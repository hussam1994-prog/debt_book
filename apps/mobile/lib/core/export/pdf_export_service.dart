import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:domain/domain.dart';

class PdfExportService {
  /// تحميل الخط العربي (يُستدعى في الـ main isolate فقط)
  Future<Uint8List> _loadArabicFontBytes() async {
    final data = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    return data.buffer.asUint8List();
  }

  /// تصدير الديون إلى ملف PDF مع دعم عربي RTL
  Future<File> exportDebtsToPdf({
    required List<Map<String, String>> rows,
    required Map<String, String> labels,
  }) async {
    final fontBytes = await _loadArabicFontBytes();

    final bytes = await Isolate.run(
      () => _generateDebtsPdf(
        fontBytes: fontBytes,
        rows: rows,
        labels: labels,
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/debts_$timestamp.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// تصدير كشف حساب شخصي (اسم الشخص + الديون + الإجمالي)
  Future<File> exportPersonStatementToPdf({
    required String personName,
    required List<Map<String, String>> debtRows,
    required String totalAmount,
    required Map<String, String> labels,
  }) async {
    final fontBytes = await _loadArabicFontBytes();

    final bytes = await Isolate.run(
      () => _generatePersonStatementPdf(
        fontBytes: fontBytes,
        personName: personName,
        debtRows: debtRows,
        totalAmount: totalAmount,
        labels: labels,
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/statement_${personName}_$timestamp.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// تصدير الديون المجمّعة حسب الشخص إلى PDF.
  Future<File> exportGroupedDebtsToPdf({
    required List<PersonDebtSummary> summaries,
    required Map<String, String> labels,
  }) async {
    final fontBytes = await _loadArabicFontBytes();

    final bytes = await Isolate.run(
      () => _generateGroupedDebtsPdf(
        fontBytes: fontBytes,
        summaries: summaries,
        labels: labels,
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/grouped_debts_$timestamp.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ─── دوال التوليد داخل الـ isolate (لا تعتمد على Flutter) ───

  static Future<Uint8List> _generateDebtsPdf({
    required Uint8List fontBytes,
    required List<Map<String, String>> rows,
    required Map<String, String> labels,
  }) async {
    final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) => [
          pw.Text(
            labels['pdfReportTitle'] ?? 'Debt Book Report',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: font,
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
                  _cellInIsolate(labels['pdfPerson'] ?? 'Person', font, bold: true),
                  _cellInIsolate(labels['pdfDescription'] ?? 'Description', font, bold: true),
                  _cellInIsolate(labels['pdfOriginalAmount'] ?? 'Original Amount', font, bold: true),
                  _cellInIsolate(labels['pdfBalance'] ?? 'Balance', font, bold: true),
                  _cellInIsolate(labels['pdfStatus'] ?? 'Status', font, bold: true),
                  _cellInIsolate(labels['pdfDueDate'] ?? 'Due Date', font, bold: true),
                ],
              ),
              ...rows.map(
                (row) => pw.TableRow(
                  children: [
                    _cellInIsolate(row['person'] ?? '', font),
                    _cellInIsolate(row['description'] ?? '', font),
                    _cellInIsolate(row['originalAmount'] ?? '', font),
                    _cellInIsolate(row['balance'] ?? '', font),
                    _cellInIsolate(row['status'] ?? '', font),
                    _cellInIsolate(row['dueDate'] ?? '', font),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _generatePersonStatementPdf({
    required Uint8List fontBytes,
    required String personName,
    required List<Map<String, String>> debtRows,
    required String totalAmount,
    required Map<String, String> labels,
  }) async {
    final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) => [
          pw.Text(
            '${labels['statementFor'] ?? 'Statement for'} $personName',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: font,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${labels['totalOutstanding'] ?? 'Total Outstanding'}: $totalAmount دينار',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: font, fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  _cellInIsolate(labels['description'] ?? 'Description', font, bold: true),
                  _cellInIsolate(labels['originalAmount'] ?? 'Original Amount', font, bold: true),
                  _cellInIsolate(labels['balance'] ?? 'Balance', font, bold: true),
                  _cellInIsolate(labels['status'] ?? 'Status', font, bold: true),
                ],
              ),
              ...debtRows.map(
                (row) => pw.TableRow(
                  children: [
                    _cellInIsolate(row['description'] ?? '', font),
                    _cellInIsolate(row['originalAmount'] ?? '', font),
                    _cellInIsolate(row['balance'] ?? '', font),
                    _cellInIsolate(row['status'] ?? '', font),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _generateGroupedDebtsPdf({
    required Uint8List fontBytes,
    required List<PersonDebtSummary> summaries,
    required Map<String, String> labels,
  }) async {
    final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (context) => [
          pw.Text(
            labels['groupedDebtsReportTitle'] ?? 'Grouped Debts Report',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: font,
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
                  _cellInIsolate(labels['person'] ?? 'Person', font, bold: true),
                  _cellInIsolate(labels['totalOutstanding'] ?? 'Total Outstanding', font, bold: true),
                  _cellInIsolate(labels['debts'] ?? 'Debts', font, bold: true),
                  _cellInIsolate(labels['dueDate'] ?? 'Due Date', font, bold: true),
                ],
              ),
              ...summaries.map(
                (s) => pw.TableRow(
                  children: [
                    _cellInIsolate(s.personName, font),
                    _cellInIsolate('${s.totalOutstanding.amount} IQD', font),
                    _cellInIsolate('${s.debtCount}', font),
                    _cellInIsolate(
                      s.lastDueDate != null
                          ? '${s.lastDueDate!.day}/${s.lastDueDate!.month}/${s.lastDueDate!.year}'
                          : '',
                      font,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cellInIsolate(String text, pw.Font font, {bool bold = false}) {
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