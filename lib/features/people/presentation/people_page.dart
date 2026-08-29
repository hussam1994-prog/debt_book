import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp/whatsapp_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../providers/people_providers.dart';

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshLocal() {
    ref.invalidate(peopleProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث القائمة محليًا')),
      );
    }
  }

  Future<void> _confirmDeletePerson(Person person) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDeletePerson),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deletePerson = ref.read(deletePersonProvider);
    await deletePerson(person.id);

    // ✅ حذف من السحابة أيضًا
    final cloudSync = ref.read(cloudSyncServiceProvider);
    await cloudSync.softDeletePersonOnCloud(person.id);

    if (!mounted) return;
    ref.invalidate(peopleProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.personDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.people),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _refreshLocal,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: l10n.allDebts,
            onPressed: () => context.go('/all-debts'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: l10n.dashboard,
            onPressed: () => context.go('/dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: l10n.reports,
            onPressed: () => context.go('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshLocal(),
              child: peopleAsync.when(
                data: (people) {
                  final filtered = _query.isEmpty
                      ? people
                      : people.where((p) {
                          final nameMatch =
                              p.name.toLowerCase().contains(_query);
                          final phoneMatch = p.phone != null &&
                              p.phone!.toLowerCase().contains(_query);
                          return nameMatch || phoneMatch;
                        }).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.search,
                      title: l10n.noPeople,
                      subtitle: l10n.noPeople,
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final person = filtered[index];
                      return AppCard(
                        onTap: () => context.go('/person/${person.id.value}'),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                person.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (person.phone != null)
                                    Text(
                                      person.phone!,
                                      style: textTheme.bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                            if (person.phone != null &&
                                person.phone!.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.chat,
                                    color: Colors.green),
                                tooltip: l10n.whatsappTooltip,
                                onPressed: () async {
                                  final message = l10n.whatsappGeneralMessage;
                                  await WhatsAppService.sendReminder(
                                    phone: person.phone!,
                                    message: message,
                                  );
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: l10n.delete,
                              onPressed: () => _confirmDeletePerson(person),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPersonDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ الدالة الجديدة: فحص الاسم ثم إضافة أو تحويل لإضافة دين
  void _showAddPersonDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.addPerson),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                maxLength: 50,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                maxLength: 15,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneOptional),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                // ✅ البحث عن شخص بنفس الاسم
                final personRepo = ref.read(personRepositoryProvider);
                final existing = await personRepo.findByName(name);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (existing != null) {
                  // ✅ الاسم موجود: عرض خيار إضافة دين
                  final shouldAddDebt = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.nameExists),
                      content: Text(
                          '${l10n.nameExistsMessage}\n${existing.name}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.createNew),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.addDebtToExisting),
                        ),
                      ],
                    ),
                  );

                  if (shouldAddDebt == true && context.mounted) {
                    context.go('/person/${existing.id.value}/add-debt');
                  }
                  return;
                }

                // ✅ لا يوجد مكرر: إنشاء شخص جديد
                final phone = phoneController.text.trim();
                final createPerson = ref.read(createPersonProvider);
                await createPerson(
                  name: name,
                  phone: phone.isEmpty ? null : phone,
                );
                ref.invalidate(peopleProvider);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}