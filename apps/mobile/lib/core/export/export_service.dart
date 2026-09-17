import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:domain/domain.dart';

class ExportService {
  /// تصدير بيانات الديون إلى ملف CSV.
  Future<File> exportDebtsToCsv({
    required List<Map<String, String>> rows,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(exportDir.path, 'debts_$timestamp.csv');

    await Isolate.run(() => _generateAndWriteCsv(rows, filePath));

    return File(filePath);
  }

  /// تصدير الديون المجمّعة حسب الشخص إلى CSV.
  Future<File> exportGroupedDebtsToCsv({
    required List<PersonDebtSummary> summaries,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(exportDir.path, 'grouped_debts_$timestamp.csv');

    await Isolate.run(() => _generateGroupedCsv(summaries, filePath));

    return File(filePath);
  }
}

/// دالة مستقلة تعمل داخل isolate لبناء CSV وكتابته.
Future<void> _generateAndWriteCsv(
    List<Map<String, String>> rows, String filePath) async {
  final buffer = StringBuffer();
  buffer.writeln(
      'Person,Description,Original Amount,Remaining Balance,Status,Due Date');

  for (final row in rows) {
    buffer.writeln(
      '${row['person']},${row['description']},${row['originalAmount']},${row['balance']},${row['status']},${row['dueDate']}',
    );
  }

  await File(filePath).writeAsString(buffer.toString(), flush: true);
}

/// دالة مستقلة تعمل داخل isolate لبناء CSV مجمّع وكتابته.
Future<void> _generateGroupedCsv(
    List<PersonDebtSummary> summaries, String filePath) async {
  final buffer = StringBuffer();
  buffer.writeln('Person,Total Outstanding,Debt Count,Last Due Date');

  for (final s in summaries) {
    final dueDate = s.lastDueDate != null
        ? '${s.lastDueDate!.day}/${s.lastDueDate!.month}/${s.lastDueDate!.year}'
        : '';
    buffer.writeln(
        '${s.personName},${s.totalOutstanding.amount},${s.debtCount},$dueDate');
  }

  await File(filePath).writeAsString(buffer.toString(), flush: true);
}