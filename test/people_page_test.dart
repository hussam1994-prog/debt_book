import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers.dart';
import 'package:mobile/features/people/presentation/people_page.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Add person shows in list', (WidgetTester tester) async {
    // Pump the widget with overridden appDatabaseProvider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: PeoplePage(),
        ),
      ),
    );

    // Tap the add button
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Enter name and phone
    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Ahmed');
    await tester.enterText(
        find.widgetWithText(TextField, 'Phone (optional)'), '123456789');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    // Expect the person name is displayed
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('123456789'), findsOneWidget);
  });
}