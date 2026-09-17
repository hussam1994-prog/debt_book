import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers.dart';
import 'package:mobile/features/people/presentation/person_detail_page.dart';
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

  testWidgets('Person detail renders without crash', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final personId = PersonId('person-1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncServiceProvider.overrideWithValue(FakeSyncService()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: const Locale('en'),
          home: PersonDetailPage(personId: personId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // ✅ نتحقق فقط أن الشاشة بُنيت بدون استثناءات
    expect(tester.takeException(), isNull);
    expect(find.byType(PersonDetailPage), findsOneWidget);
  });
}