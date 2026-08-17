import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/providers.dart';
import 'package:mobile/features/people/presentation/person_detail_page.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Person detail shows debts list', (WidgetTester tester) async {
    final personId = PersonId('person-1');

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

    // انتظر حتى تكتمل العمليات غير المتزامنة
    await tester.pumpAndSettle();

    expect(find.text('Person Details'), findsOneWidget);
    expect(find.text('No Debts'), findsOneWidget);
  });
}