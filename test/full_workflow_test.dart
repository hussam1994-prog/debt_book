import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers.dart';
import 'package:mobile/data/repositories/person_repository_impl.dart';
import 'package:mobile/data/repositories/debt_repository_impl.dart';
import 'package:mobile/data/repositories/payment_repository_impl.dart';
import 'package:mobile/data/repositories/ledger_repository_impl.dart';
import 'package:mobile/features/people/presentation/person_detail_page.dart';

void main() {
  late AppDatabase db;
  late PersonRepositoryImpl personRepo;
  late DebtRepositoryImpl debtRepo;
  late PaymentRepositoryImpl paymentRepo;
  late LedgerRepositoryImpl ledgerRepo;
  late UuidGenerator uuidGen;

  setUp(() {
    db = AppDatabase.memory();
    personRepo = PersonRepositoryImpl(db);
    debtRepo = DebtRepositoryImpl(db);
    paymentRepo = PaymentRepositoryImpl(db);
    ledgerRepo = LedgerRepositoryImpl(db);
    uuidGen = DefaultUuidGenerator();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Person list shows remaining balance after payment', (tester) async {
    final personId = PersonId('p1');
    final debtId = DebtId('d1');

    // إنشاء شخص
    final person = Person(
      id: personId,
      name: 'Ahmed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await personRepo.save(person);

    // إنشاء دين مع قيد افتتاحي
    final debt = Debt(
      id: debtId,
      personId: personId,
      amount: Money(amount: 1000),
      status: DebtStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final openingEntry = LedgerEntry(
      id: LedgerEntryId(uuidGen.generateUuidV7()),
      debtId: debtId,
      entryType: LedgerEntryType.debt_creation,
      amount: Money(amount: 1000),
      createdAt: DateTime.now(),
    );
    await debtRepo.createDebt(debt, openingEntry);

    // إضافة دفعة
    final payment = Payment(
      id: PaymentId('pay1'),
      debtId: debtId,
      amount: Money(amount: 200),
      paymentDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final paymentEntry = LedgerEntry(
      id: LedgerEntryId(uuidGen.generateUuidV7()),
      debtId: debtId,
      entryType: LedgerEntryType.payment,
      amount: Money(amount: -200),
      paymentId: payment.id,
      createdAt: DateTime.now(),
    );
    await paymentRepo.recordPayment(payment, paymentEntry);

    // عرض صفحة الشخص
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: PersonDetailPage(personId: personId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // يجب أن يظهر الرصيد المتبقي 800
    expect(find.text('800 IQD'), findsOneWidget);
  });
}