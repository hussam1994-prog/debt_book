import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  /// تحميل الخط العربي
  Future<pw.Font> _loadArabicFont() async {
    final data = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    return pw.Font.ttf(data);
  }

  /// تصدير الديون إلى ملف PDF مع دعم عربي RTL
  Future<File> exportDebtsToPdf({
    required List<Map<String, String>> rows,
    required Map<String, String> labels,
  }) async {
    final arabicFont = await _loadArabicFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFont,
        ),
        build: (context) => [
          pw.Text(
            labels['pdfReportTitle'] ?? 'Debt Book Report',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  _cell(labels['pdfPerson'] ?? 'Person', arabicFont, bold: true),
                  _cell(labels['pdfDescription'] ?? 'Description', arabicFont, bold: true),
                  _cell(labels['pdfOriginalAmount'] ?? 'Original Amount', arabicFont, bold: true),
                  _cell(labels['pdfBalance'] ?? 'Balance', arabicFont, bold: true),
                  _cell(labels['pdfStatus'] ?? 'Status', arabicFont, bold: true),
                  _cell(labels['pdfDueDate'] ?? 'Due Date', arabicFont, bold: true),
                ],
              ),
              ...rows.map(
                (row) => pw.TableRow(
                  children: [
                    _cell(row['person'] ?? '', arabicFont),
                    _cell(row['description'] ?? '', arabicFont),
                    _cell(row['originalAmount'] ?? '', arabicFont),
                    _cell(row['balance'] ?? '', arabicFont),
                    _cell(row['status'] ?? '', arabicFont),
                    _cell(row['dueDate'] ?? '', arabicFont),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/debts_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// ✅ تصدير كشف حساب شخصي (اسم الشخص + الديون + الإجمالي)
  Future<File> exportPersonStatementToPdf({
    required String personName,
    required List<Map<String, String>> debtRows,
    required String totalAmount,
    required Map<String, String> labels,
  }) async {
    final arabicFont = await _loadArabicFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFont,
        ),
        build: (context) => [
          pw.Text(
            '${labels['statementFor'] ?? 'Statement for'} $personName',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${labels['totalOutstanding'] ?? 'Total Outstanding'}: $totalAmount دينار',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicFont, fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  _cell(labels['description'] ?? 'Description', arabicFont, bold: true),
                  _cell(labels['originalAmount'] ?? 'Original Amount', arabicFont, bold: true),
                  _cell(labels['balance'] ?? 'Balance', arabicFont, bold: true),
                  _cell(labels['status'] ?? 'Status', arabicFont, bold: true),
                ],
              ),
              ...debtRows.map(
                (row) => pw.TableRow(
                  children: [
                    _cell(row['description'] ?? '', arabicFont),
                    _cell(row['originalAmount'] ?? '', arabicFont),
                    _cell(row['balance'] ?? '', arabicFont),
                    _cell(row['status'] ?? '', arabicFont),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // ✅ الإصلاح هنا: استخدام ${personName}
    final file = File('${dir.path}/statement_${personName}_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _cell(String text, pw.Font font, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          fontSize: 11,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}