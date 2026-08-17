import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  List<File>? _backups;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final backupService = ref.read(backupServiceProvider);
    final backups = await backupService.listBackups();
    setState(() => _backups = backups);
  }

  Future<void> _createBackup() async {
    final logger = ref.read(loggingServiceProvider);
    logger.info('Creating backup');

    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final file = await backupService.createBackup();
      logger.info('Backup created');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created: ${file.path.split('/').last}')),
        );
      }
      await _loadBackups();
    } catch (e) {
      logger.error('Backup failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(File file) async {
    final logger = ref.read(loggingServiceProvider);
    logger.info('Restoring backup');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text('This will replace all current data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.restoreBackup(file);
      logger.info('Backup restored');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored. Restart the app to apply changes.')),
        );
      }
    } catch (e) {
      logger.error('Restore failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Create Backup'),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _backups == null || _backups!.isEmpty
                      ? const EmptyState(
                          icon: Icons.backup_outlined,
                          title: 'No backups',
                          subtitle: 'Create your first backup to keep your data safe.',
                        )
                      : ListView.builder(
                          itemCount: _backups!.length,
                          itemBuilder: (context, index) {
                            final file = _backups![index];
                            final date = file.lastModifiedSync();
                            return ListTile(
                              leading: const Icon(Icons.backup, color: AppColors.primary),
                              title: Text(file.path.split('/').last),
                              subtitle: Text(
                                  '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore),
                                    onPressed: () => _restoreBackup(file),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      final backupService = ref.read(backupServiceProvider);
                                      await backupService.deleteBackup(file);
                                      await _loadBackups();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}