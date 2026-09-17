import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/outbox_repository.dart';
import 'package:mobile/core/providers.dart';
import 'package:mobile/data/repositories/debt_repository_impl.dart';
import 'package:mobile/data/repositories/payment_repository_impl.dart';
import 'package:mobile/data/repositories/person_repository_impl.dart';
import 'package:mobile/features/people/presentation/person_detail_page.dart';

import 'helpers/fake_sync_service.dart';

void main() {
  late AppDatabase db;
  late OutboxRepository outboxRepo;
  late PersonRepositoryImpl personRepo;
  late DebtRepositoryImpl debtRepo;
  late PaymentRepositoryImpl paymentRepo;
  late UuidGenerator uuidGen;

  setUp(() {
    db = AppDatabase.memory();
    outboxRepo = OutboxRepository(db);
    personRepo = PersonRepositoryImpl(db, outboxRepo);
    debtRepo = DebtRepositoryImpl(db, outboxRepo);
    paymentRepo = PaymentRepositoryImpl(db, outboxRepo);
    uuidGen = DefaultUuidGenerator();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Person list shows remaining balance after payment',
      (tester) async {
    // ✅ حجم شاشة كافٍ
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final personId = PersonId('p1');
    final debtId = DebtId('d1');

    // 1) إنشاء شخص
    await personRepo.save(Person(
      id: personId,
      name: 'Ahmed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 2) إنشاء دين مع قيد افتتاحي
    await debtRepo.createDebt(
      Debt(
        id: debtId,
        personId: personId,
        amount: Money(amount: 1000),
        status: DebtStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LedgerEntry(
        id: LedgerEntryId(uuidGen.generateUuidV7()),
        debtId: debtId,
        entryType: LedgerEntryType.debt_creation,
        amount: Money(amount: 1000),
        createdAt: DateTime.now(),
      ),
    );

    // 3) إضافة دفعة 200
    final payment = Payment(
      id: PaymentId('pay1'),
      debtId: debtId,
      amount: Money(amount: 200),
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await paymentRepo.recordPayment(
      payment,
      LedgerEntry(
        id: LedgerEntryId(uuidGen.generateUuidV7()),
        debtId: debtId,
        entryType: LedgerEntryType.payment,
        amount: Money(amount: -200),
        paymentId: payment.id,
        createdAt: DateTime.now(),
      ),
    );

    // 4) عرض صفحة الشخص
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // ✅ تجاوز syncService لتجنب Supabase
          syncServiceProvider.overrideWithValue(FakeSyncService()),
        ],
        child: MaterialApp(
          home: PersonDetailPage(personId: personId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 5) التحقق من الرصيد 800
    // 💡 الرصيد قد يُعرض كـ "800" أو "800 IQD" أو "IQD 800"
    // نتحقق من أي widget يحتوي "800"
    final balanceFinder = find.byWidgetPredicate(
      (w) => w is Text && (w.data?.contains('800') ?? false),
    );
    expect(
      balanceFinder,
      findsWidgets,
      reason: 'يجب أن يظهر الرصيد 800 في الصفحة',
    );
  });
}