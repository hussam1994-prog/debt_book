import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  /// إنشاء نسخة احتياطية من قاعدة البيانات.
  /// يرجع مسار الملف الناتج.
  Future<File> createBackup() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));

    if (!dbFile.existsSync()) {
      throw Exception('Database file not found');
    }

    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File(p.join(backupDir.path, 'backup_$timestamp.db'));
    await dbFile.copy(backupFile.path);
    return backupFile;
  }

  /// سرد النسخ الاحتياطية المتاحة.
  Future<List<File>> listBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!backupDir.existsSync()) return [];

    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();

    // ترتيب من الأحدث إلى الأقدم
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// استعادة نسخة احتياطية.
  Future<void> restoreBackup(File backupFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));

    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    await backupFile.copy(dbFile.path);
  }

  /// حذف نسخة احتياطية.
  Future<void> deleteBackup(File backupFile) async {
    if (backupFile.existsSync()) {
      backupFile.deleteSync();
    }
  }

  /// نسخ احتياطي تلقائي (إذا لم توجد نسخة أو مر يوم على آخر نسخة).
  Future<void> autoBackupIfNeeded() async {
    final backups = await listBackups();
    if (backups.isEmpty) {
      await createBackup();
      return;
    }

    final lastBackup = backups.first;
    final now = DateTime.now();
    final diff = now.difference(lastBackup.lastModifiedSync());
    if (diff.inDays >= 1) {
      // نحذف أقدم النسخ إذا كانت أكثر من 5
      if (backups.length >= 5) {
        // نحذف الأقدم
        final oldest = backups.last;
        await deleteBackup(oldest);
      }
      await createBackup();
    }
  }

  /// مشاركة نسخة احتياطية عبر التطبيقات (إيميل/واتساب).
  Future<void> shareBackup(File backupFile) async {
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      subject: 'Debt Book Backup',
      text: 'نسخة احتياطية من تطبيق دفتر الديون',
    );
  }

  /// اختيار ملف نسخة احتياطية من جهاز المستخدم.
  Future<File?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// استيراد نسخة احتياطية من ملف خارجي.
  Future<void> importBackup(File sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));

    // نسخ الملف المختار فوق قاعدة البيانات الحالية
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    await sourceFile.copy(dbFile.path);
  }
}