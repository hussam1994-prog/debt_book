import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ExportService {
  /// تصدير بيانات الديون إلى ملف CSV.
  /// يرجع مسار الملف الناتج.
  Future<File> exportDebtsToCsv({
    required List<Map<String, String>> rows,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'exports'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(exportDir.path, 'debts_$timestamp.csv'));

    // إنشاء محتوى CSV بسيط
    final buffer = StringBuffer();
    // عناوين الأعمدة
    buffer.writeln('Person,Description,Original Amount,Remaining Balance,Status,Due Date');

    for (final row in rows) {
      buffer.writeln(
        '${row['person']},${row['description']},${row['originalAmount']},${row['balance']},${row['status']},${row['dueDate']}',
      );
    }

    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }
}