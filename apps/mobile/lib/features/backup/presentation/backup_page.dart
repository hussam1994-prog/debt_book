import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/backup/cloud_backup_service.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  List<FileSystemEntity> _localBackups = [];
  List<CloudBackupInfo> _cloudBackups = [];
  bool _isLoading = false;
  bool _showCloud = false;

  @override
  void initState() {
    super.initState();
    _loadLocalBackups();
  }

  // ─── تحميل النسخ المحلية ───
  Future<void> _loadLocalBackups() async {
    setState(() => _isLoading = true);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(docsDir.path, 'backups'));
      if (await backupDir.exists()) {
        final files = await backupDir.list().toList();
        files.sort((a, b) =>
            b.statSync().modified.compareTo(a.statSync().modified));
        setState(() => _localBackups = files);
      } else {
        setState(() => _localBackups = []);
      }
    } catch (e) {
      debugPrint('Error loading backups: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── تحميل النسخ السحابية ───
  Future<void> _loadCloudBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await ref.read(cloudBackupServiceProvider).listBackups();
      if (mounted) {
        setState(() => _cloudBackups = backups);
      }
    } catch (e) {
      debugPrint('Error loading cloud backups: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── إنشاء نسخة احتياطية محلية ───
  Future<void> _createLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));
      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ملف قاعدة البيانات غير موجود')),
          );
        }
        return;
      }

      final backupDir = Directory(p.join(docsDir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath =
          p.join(backupDir.path, 'backup_$timestamp.db');

      await dbFile.copy(backupPath);

      await _loadLocalBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.backupCreated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.backupFailedWithError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── رفع نسخة احتياطية سحابية ───
  Future<void> _uploadCloudBackup() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(cloudBackupServiceProvider).uploadBackup();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ تم الرفع بنجاح (${(result.size! / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // ✅ نظّف النسخ القديمة (احتفظ بـ 5)
        await ref.read(cloudBackupServiceProvider).cleanupOldBackups();
        // ✅ حدّث القائمة السحابية
        await _loadCloudBackups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric(result.errorMessage ?? ''))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.uploadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── استعادة نسخة محلية ───
  Future<void> _restoreLocalBackup(File backupFile) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restore),
        content: Text(l10n.confirmRestore),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // 1. نسخة احتياطية سريعة للبيانات الحالية
      final docsDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(docsDir.path, 'debt_book.sqlite'));
      if (await dbFile.exists()) {
        final safetyDir = Directory(p.join(docsDir.path, 'backups'));
        if (!await safetyDir.exists()) {
          await safetyDir.create(recursive: true);
        }
        await dbFile.copy(
          p.join(
            safetyDir.path,
            'pre_restore_${DateTime.now().millisecondsSinceEpoch}.db',
          ),
        );
      }

      // 2. استبدال DB
      await backupFile.copy(dbFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupRestored),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreFailedWithError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── تنزيل نسخة سحابية ───
  Future<void> _restoreCloudBackup(CloudBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة من السحابة'),
        content: const Text(
          'سيتم تنزيل النسخة من السحابة. يمكنك استعادتها لاحقاً من النسخ المحلية. متابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تنزيل'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(cloudBackupServiceProvider)
          .downloadBackup(backup.filePath);

      if (!mounted) return;

      if (result.success) {
        // ✅ بعد التنزيل، انسخ الملف إلى مجلد backups المحلي
        final docsDir = await getApplicationDocumentsDirectory();
        final backupDir = Directory(p.join(docsDir.path, 'backups'));
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }

        final downloadedFile = File(result.path!);
        final localPath = p.join(
          backupDir.path,
          'cloud_${DateTime.now().millisecondsSinceEpoch}.db',
        );
        await downloadedFile.copy(localPath);

        // ✅ حدّث القائمة المحلية
        await _loadLocalBackups();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ تم التنزيل (${(result.size! / 1024).toStringAsFixed(1)} KB). '
                'يمكنك استعادتها من القائمة المحلية.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGeneric(result.errorMessage ?? ''))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.downloadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── حذف نسخة محلية ───
  Future<void> _deleteLocalBackup(File file) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBackup),
        content: Text(l10n.confirmDeleteBackup),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await file.delete();
      await _loadLocalBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.deleteFailed(e.toString()))),
        );
      }
    }
  }

  // ─── حذف نسخة سحابية ───
  Future<void> _deleteCloudBackup(CloudBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف نسخة سحابية'),
        content: const Text('هل أنت متأكد من حذف هذه النسخة من السحابة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final ok = await ref
          .read(cloudBackupServiceProvider)
          .deleteBackup(backup.id, backup.filePath);

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم الحذف')),
        );
        await _loadCloudBackups();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── مشاركة ملف ───
  Future<void> _shareBackup(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  // ─── تبديل العرض (محلي/سحابي) ───
  void _toggleView(bool cloud) {
    setState(() => _showCloud = cloud);
    if (cloud && _cloudBackups.isEmpty) {
      _loadCloudBackups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupRestore),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showCloud ? _loadCloudBackups : _loadLocalBackups,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Tabs: محلي / سحابي ───
          Container(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'محلي',
                    icon: Icons.phone_android,
                    isActive: !_showCloud,
                    onTap: () => _toggleView(false),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'سحابي',
                    icon: Icons.cloud,
                    isActive: _showCloud,
                    onTap: () => _toggleView(true),
                  ),
                ),
              ],
            ),
          ),

          // ─── محتوى ───
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showCloud
                    ? _buildCloudView(l10n)
                    : _buildLocalView(l10n),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading
            ? null
            : (_showCloud ? _uploadCloudBackup : _createLocalBackup),
        backgroundColor: AppColors.primary,
        icon: Icon(_showCloud ? Icons.cloud_upload : Icons.backup),
        label: Text(_showCloud ? 'رفع نسخة' : l10n.createBackup),
      ),
    );
  }

  // ─── العرض المحلي ───
  Widget _buildLocalView(dynamic l10n) {
    if (_localBackups.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open,
        title: l10n.noBackups,
        subtitle: l10n.noBackups,
        actionLabel: l10n.createBackup,
        onAction: _createLocalBackup,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLocalBackups,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _localBackups.length,
        itemBuilder: (context, index) {
          final file = _localBackups[index] as File;
          final stat = file.statSync();
          final name = p.basename(file.path);
          final size = stat.size;
          final date = stat.modified;

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.save, color: AppColors.primary),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${(size / 1024).toStringAsFixed(1)} KB • '
                '${date.day}/${date.month}/${date.year} '
                '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'restore':
                      _restoreLocalBackup(file);
                      break;
                    case 'share':
                      _shareBackup(file);
                      break;
                    case 'delete':
                      _deleteLocalBackup(file);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        const Icon(Icons.restore, size: 18),
                        const SizedBox(width: 8),
                        Text(context.l10n.restore),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, size: 18),
                        const SizedBox(width: 8),
                        const Text('مشاركة'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── العرض السحابي ───
  Widget _buildCloudView(dynamic l10n) {
    if (_cloudBackups.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'لا توجد نسخ سحابية',
        subtitle: 'اضغط "رفع نسخة" لإنشاء أول نسخة احتياطية سحابية',
        actionLabel: 'رفع نسخة',
        onAction: _uploadCloudBackup,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCloudBackups,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _cloudBackups.length,
        itemBuilder: (context, index) {
          final backup = _cloudBackups[index];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: const Icon(Icons.cloud, color: Colors.blue),
              ),
              title: Text(
                '${backup.createdAt.day}/${backup.createdAt.month}/${backup.createdAt.year} '
                '${backup.createdAt.hour}:${backup.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${(backup.fileSize / 1024).toStringAsFixed(1)} KB'
                '${backup.encrypted ? " • مشفر 🔒" : ""}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'download':
                      _restoreCloudBackup(backup);
                      break;
                    case 'delete':
                      _deleteCloudBackup(backup);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('تنزيل'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'حذف من السحابة',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── زر Tab ───
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}