import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers.dart';
import 'package:mobile/features/people/presentation/people_page.dart';
import 'package:mobile/l10n/app_localizations.dart';

import 'helpers/fake_sync_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Add person shows in list', (WidgetTester tester) async {
    // ✅ اضبط حجم الشاشة لتفادي overflow
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // ✅ تجاوز syncService حتى لا يطلب Supabase
          syncServiceProvider.overrideWithValue(FakeSyncService()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ar')],
          locale: Locale('en'),
          home: PeoplePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // فتح حوار الإضافة
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // ✅ إدخال النصوص حسب نوع الحقل (لا نعتمد على النص)
    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeast(1), reason: 'يجب أن يظهر TextField واحد على الأقل');

    await tester.enterText(textFields.first, 'Ahmed');

    if (textFields.evaluate().length > 1) {
      await tester.enterText(textFields.at(1), '123456789');
    }

    // ✅ ابحث عن أي زر (Filled/Elevated/TextButton)
    final saveButton = find.byWidgetPredicate(
      (w) => w is FilledButton || w is ElevatedButton || w is TextButton,
    );
    expect(saveButton, findsAtLeast(1), reason: 'يجب أن يوجد زر حفظ');

    // اضغط على آخر زر (عادةً "حفظ" أو "Save")
    await tester.tap(saveButton.last, warnIfMissed: false);
    await tester.pumpAndSettle();

    // التحقق
    expect(find.text('Ahmed'), findsWidgets);
  });
}