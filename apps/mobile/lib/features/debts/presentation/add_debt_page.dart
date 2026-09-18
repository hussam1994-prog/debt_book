import 'dart:io';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../people/providers/people_providers.dart';

class AddDebtPage extends ConsumerStatefulWidget {
  final PersonId personId;
  const AddDebtPage({super.key, required this.personId});

  @override
  ConsumerState<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends ConsumerState<AddDebtPage> {
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? _dueDate;
  int? _reminderDays;
  String? _attachmentPath;
  bool _isInstallment = false;
  int _numberOfInstallments = 1;
  DateTime? _firstInstallmentDate;

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickFirstInstallmentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstInstallmentDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _firstInstallmentDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _attachmentPath = image.path);
    }
  }

  void _saveDebt() async {
    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.invalidAmount)),
      );
      return;
    }

    final description = descriptionController.text.trim();
    final confirmed = await _showSummaryDialog(
      amount: amount,
      description: description,
      dueDate: _dueDate,
      reminderDays: _reminderDays,
    );

    if (confirmed != true) return;

    final createDebt = ref.read(createDebtProvider);
    try {
      final debt = await createDebt(
        personId: widget.personId,
        amount: Money(amount: amount),
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        attachmentPath: _attachmentPath,
      );

      // ✅ إذا كان التقسيط مفعّلًا
      if (_isInstallment) {
        final createInstallments = ref.read(createInstallmentsProvider);
        final firstDate = _firstInstallmentDate ?? DateTime.now();
        await createInstallments.call(
          debtId: debt.id,
          amount: debt.amount,
          numberOfInstallments: _numberOfInstallments,
          firstDueDate: firstDate,
        );
      }

      // الإشعارات
      final notificationService = ref.read(notificationServiceProvider);
      final uniqueId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await notificationService.showNewDebtNotification(
        id: uniqueId,
        title: context.l10n.newDebtNotificationTitle,
        body: context.l10n.newDebtNotificationBody(amount),
      );

      if (_dueDate != null && _reminderDays != null) {
        await notificationService.scheduleReminderBeforeDays(
          id: uniqueId + 1,
          title: context.l10n.dueSoonNotificationTitle,
          body: context.l10n.dueSoonNotificationBody,
          dueDate: _dueDate!,
          daysBefore: _reminderDays!,
        );
      }

      ref.invalidate(debtsForPersonProvider(widget.personId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<bool?> _showSummaryDialog({
    required int amount,
    required String description,
    DateTime? dueDate,
    int? reminderDays,
  }) async {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final rows = [
          ('${l10n.amount}', '$amount دينار'),
          ('${l10n.description}', description.isEmpty ? '-' : description),
          ('${l10n.dueDate}', dueDate == null ? '-' : _formatDate(dueDate!)),
          (
            '${l10n.reminder}',
            reminderDays == null
                ? l10n.noReminder
                : '${l10n.beforeDays(reminderDays)}'
          ),
          (
            l10n.installment,
            _isInstallment ? '$_numberOfInstallments ${l10n.installments}' : l10n.no
          ),
        ];

        return AlertDialog(
          title: Text(l10n.confirmSave),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            row.$1,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(child: Text(row.$2)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addDebt),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/person/${widget.personId.value}'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(l10n.dueDate),
              subtitle: Text(
                _dueDate == null ? l10n.optional : _formatDate(_dueDate!),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: _pickDueDate,
              ),
            ),
            DropdownButtonFormField<int?>(
              value: _reminderDays,
              decoration: InputDecoration(
                labelText: l10n.reminder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.noReminder),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(l10n.beforeDays(1)),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(l10n.beforeDays(2)),
                ),
              ],
              onChanged: (value) {
                setState(() => _reminderDays = value);
              },
            ),
            const SizedBox(height: 16),
            // ✅ خيار التقسيط
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.installmentPlan),
              value: _isInstallment,
              onChanged: (value) {
                setState(() => _isInstallment = value);
              },
            ),
            if (_isInstallment) ...[
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.numberOfInstallments,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _numberOfInstallments = int.tryParse(value) ?? 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available),
                title: Text(l10n.firstInstallmentDate),
                subtitle: Text(
                  _firstInstallmentDate == null
                      ? l10n.optional
                      : _formatDate(_firstInstallmentDate!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _pickFirstInstallmentDate,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // ✅ زر إرفاق صورة
            _attachmentPath == null
                ? OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.attach_file),
                    label: Text(l10n.attachImage),
                  )
                : Column(
                    children: [
                      Image.file(
                        File(_attachmentPath!),
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.changeImage),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveDebt,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveDebt),
            ),
          ],
        ),
      ),
    );
  }
}