import 'dart:io';
import 'dart:isolate';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// خدمة تصدير Excel (xlsx) مع دعم كامل للعربية.
class ExcelExportService {
  /// تصدير قائمة الديون إلى Excel.
  Future<File> exportDebtsToExcel({
    required List<Map<String, String>> rows,
    required Map<String, String> labels,
  }) async {
    final bytes = await Isolate.run(() => _generateDebtsExcel(rows, labels));

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'debts_$timestamp.xlsx'));
    await file.writeAsBytes(bytes);
    return file;
  }

  /// تصدير تقرير مجمّع حسب الشخص.
  Future<File> exportGroupedToExcel({
    required List<Map<String, String>> rows,
    required Map<String, String> labels,
  }) async {
    final bytes = await Isolate.run(() => _generateGroupedExcel(rows, labels));

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'grouped_debts_$timestamp.xlsx'));
    await file.writeAsBytes(bytes);
    return file;
  }

  // ─────────────────────────────────────────────
  // دوال توليد Excel داخل isolate
  // ─────────────────────────────────────────────

  static List<int> _generateDebtsExcel(
    List<Map<String, String>> rows,
    Map<String, String> labels,
  ) {
    final excel = Excel.createExcel();
    final sheetName = 'Debts';
    final sheet = excel[sheetName];

    // حذف الورقة الافتراضية
    excel.setDefaultSheet(sheetName);

    // ✅ الرؤوس
    final headers = [
      labels['person'] ?? 'Person',
      labels['description'] ?? 'Description',
      labels['originalAmount'] ?? 'Original Amount',
      labels['balance'] ?? 'Balance',
      labels['status'] ?? 'Status',
      labels['dueDate'] ?? 'Due Date',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // ✅ البيانات
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final values = [
        row['person'] ?? '',
        row['description'] ?? '',
        row['originalAmount'] ?? '',
        row['balance'] ?? '',
        row['status'] ?? '',
        row['dueDate'] ?? '',
      ];

      for (var c = 0; c < values.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        cell.value = TextCellValue(values[c]);
        cell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }

    // ✅ عرض الأعمدة
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    final data = excel.encode();
    if (data == null) throw Exception('Failed to encode Excel');
    return data;
  }

  static List<int> _generateGroupedExcel(
    List<Map<String, String>> rows,
    Map<String, String> labels,
  ) {
    final excel = Excel.createExcel();
    final sheetName = 'GroupedDebts';
    final sheet = excel[sheetName];

    excel.setDefaultSheet(sheetName);

    // الرؤوس
    final headers = [
      labels['person'] ?? 'Person',
      labels['totalOutstanding'] ?? 'Total Outstanding',
      labels['debts'] ?? 'Debts',
      labels['dueDate'] ?? 'Due Date',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // البيانات
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final values = [
        row['person'] ?? '',
        row['totalOutstanding'] ?? '',
        row['debts'] ?? '',
        row['dueDate'] ?? '',
      ];

      for (var c = 0; c < values.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        cell.value = TextCellValue(values[c]);
        cell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 22);
    }

    final data = excel.encode();
    if (data == null) throw Exception('Failed to encode Excel');
    return data;
  }
}