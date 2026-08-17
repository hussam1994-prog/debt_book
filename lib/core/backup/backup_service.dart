import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

    // نسخ الملف المستعاد فوق قاعدة البيانات الحالية
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
}