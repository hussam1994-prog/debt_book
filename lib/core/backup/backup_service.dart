import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
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

  Future<List<File>> listBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, 'backups'));
    if (!backupDir.existsSync()) return [];

    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> restoreBackup(File backupFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));

    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    await backupFile.copy(dbFile.path);
  }

  Future<void> deleteBackup(File backupFile) async {
    if (backupFile.existsSync()) {
      backupFile.deleteSync();
    }
  }

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
      if (backups.length >= 5) {
        await deleteBackup(backups.last);
      }
      await createBackup();
    }
  }

  Future<void> shareBackup(File backupFile) async {
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      subject: 'Debt Book Backup',
      text: 'نسخة احتياطية من تطبيق دفتر الديون',
    );
  }

  Future<File?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.isNotEmpty) {
      final firstFile = result.first;
      if (firstFile.path != null) {
        return File(firstFile.path!);
      }
    }
    return null;
  }

  Future<void> importBackup(File sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));

    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    await sourceFile.copy(dbFile.path);
  }
}