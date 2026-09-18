import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../people/providers/people_providers.dart';

class MultiPersonReportPage extends ConsumerStatefulWidget {
  const MultiPersonReportPage({super.key});

  @override
  ConsumerState<MultiPersonReportPage> createState() =>
      _MultiPersonReportPageState();
}

class _MultiPersonReportPageState
    extends ConsumerState<MultiPersonReportPage> {
  final Set<String> _selectedIds = {};
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final peopleAsync = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير متعدد الأشخاص'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reports'),
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'إلغاء التحديد',
              onPressed: () => setState(() => _selectedIds.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── رأس ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Text(
              '${_selectedIds.length} شخص محدد',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ─── قائمة الأشخاص ───
          Expanded(
            child: peopleAsync.when(
              data: (people) {
                if (people.isEmpty) {
                  return const Center(
                    child: Text('لا يوجد أشخاص'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    final selected = _selectedIds.contains(person.id.value);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(person.id.value);
                          } else {
                            _selectedIds.remove(person.id.value);
                          }
                        });
                      },
                      title: Text(person.name),
                      subtitle: person.phone != null
                          ? Text(person.phone!)
                          : null,
                      secondary: CircleAvatar(
                        backgroundColor:
                            AppColors.forName(person.name).withValues(alpha: 0.15),
                        child: Text(
                          person.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.forName(person.name),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(context.l10n.errorGeneric(e.toString()))),
            ),
          ),

          // ─── زر توليد التقرير ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _selectedIds.isEmpty || _isGenerating
                      ? null
                      : _generateReport,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                    _isGenerating ? 'جارٍ التوليد...' : 'توليد PDF',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      final l10n = context.l10n;
      final personRepo = ref.read(personRepositoryProvider);
      final debtRepo = ref.read(debtRepositoryProvider);
      final ledgerRepo = ref.read(ledgerRepositoryProvider);
      final calculator = const BalanceCalculator();

      final allEntries = await ledgerRepo.findAll();
      final reportData = <Map<String, dynamic>>[];

      for (final id in _selectedIds) {
        final person = await personRepo.findById(PersonId(id));
        if (person == null) continue;

        final debts = await debtRepo.findByPersonId(person.id);
        final activeDebts = debts.where((d) => !d.isDeleted).toList();

        int totalOutstanding = 0;
        final debtRows = <Map<String, String>>[];

        for (final debt in activeDebts) {
          final entries = allEntries
              .where((e) => e.debtId == debt.id)
              .toList();
          final balance = calculator.calculateBalance(entries);
          if (balance.amount > 0) {
            totalOutstanding += balance.amount;
          }
          debtRows.add({
            'description': debt.description ?? '',
            'originalAmount': '${debt.amount.amount}',
            'balance': '${balance.amount}',
            'status': debt.status.name,
          });
        }

        reportData.add({
          'person': person,
          'total': totalOutstanding,
          'debts': debtRows,
        });
      }

      // ✅ أنشئ PDF موحّد
      final pdfService = ref.read(pdfExportServiceProvider);
      // ملاحظة: نحتاج دالة جديدة في pdf_service.
      // سنستخدم exportPersonStatementToPdf لكل شخص ودمجها.
      // للتبسيط: أرسل ملفات منفصلة.
      final files = <XFile>[];

      for (final data in reportData) {
        final person = data['person'] as Person;
        final file = await pdfService.exportPersonStatementToPdf(
          personName: person.name,
          debtRows: (data['debts'] as List).cast<Map<String, String>>(),
          totalAmount: '${data['total']}',
          labels: {
            'statementFor': l10n.statementFor,
            'totalOutstanding': l10n.totalOutstanding,
            'description': l10n.description,
            'originalAmount': l10n.originalAmount,
            'balance': l10n.balance,
            'status': l10n.status,
          },
        );
        files.add(XFile(file.path));
      }

      if (mounted && files.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            text: 'تقارير ${files.length} أشخاص',
            files: files,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}