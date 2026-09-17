import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/voice/voice_search_service.dart';
import '../../../core/whatsapp/whatsapp_service.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../providers/people_providers.dart';
import '../providers/person_tag_provider.dart';

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _voiceService = VoiceSearchService();
  String _query = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(peoplePaginatedProvider.notifier).loadMore();
      _voiceService.initialize();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(peoplePaginatedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _refreshLocal() async {
    await ref.read(peoplePaginatedProvider.notifier).refresh();
  }

  // ─── ✅ البحث الصوتي المحسّن (عربي + إنجليزي) ───
  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _voiceService.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'البحث الصوتي غير متاح. تأكد من منح الإذن وتثبيت حزمة اللغة.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    // ✅ تحديد اللغة من إعدادات التطبيق
    final currentLocale = ref.read(localeProvider);
    final langCode = currentLocale.languageCode; // 'ar' أو 'en'

    debugPrint('🎤 Starting voice search: $langCode');

    await _voiceService.startListening(
      preferredLanguageCode: langCode,
      // ✅ نتيجة جزئية (تعرض أثناء الكلام)
      onPartialResult: (text) {
        if (mounted && text.isNotEmpty) {
          _searchController.text = text;
          setState(() {
            _query = text.trim().toLowerCase();
          });
        }
      },
      // ✅ نتيجة نهائية
      onResult: (text) {
        if (mounted) {
          _searchController.text = text;
          setState(() {
            _query = text.trim().toLowerCase();
            _isListening = false;
          });
        }
      },
      // ✅ معالجة الأخطاء
      onError: (error) {
        debugPrint('❌ Voice error: $error');
        if (mounted) {
          setState(() => _isListening = false);
          if (error.contains('no_match')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لم يتم التعرف على الكلام. حاول مرة أخرى.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );

    // إيقاف تلقائي بعد 15 ثانية
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isListening) {
        _voiceService.stopListening();
        setState(() => _isListening = false);
      }
    });
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

    await ref.read(personRepositoryProvider).softDelete(person.id);

    await ref.read(peoplePaginatedProvider.notifier).refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.personDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peoplePaginatedProvider);
    final notifier = ref.watch(peoplePaginatedProvider.notifier);
    final tags = ref.watch(personTagProvider);
    final l10n = context.l10n;

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
                hintText: _isListening
                    ? '🎤 جارٍ الاستماع...'
                    : l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                // ✅ زر الميكروفون
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : null,
                  ),
                  tooltip: 'بحث صوتي',
                  onPressed: _toggleVoiceSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: _isListening,
                fillColor: _isListening
                    ? Colors.red.withValues(alpha: 0.05)
                    : null,
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
              onRefresh: _refreshLocal,
              child: people.isEmpty
                  ? (notifier.isLoading
                      ? const PeopleListSkeleton()
                      : EmptyState(
                          icon: Icons.people_outline,
                          title: l10n.noPeople,
                          subtitle: l10n.noPeople,
                          actionLabel: 'إضافة شخص',
                          onAction: () => _showAddPersonDialog(context),
                        ))
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: people.length + (notifier.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == people.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final person = people[index];
                        final matchesQuery = _query.isEmpty ||
                            person.name.toLowerCase().contains(_query) ||
                            (person.phone != null &&
                                person.phone!.toLowerCase().contains(_query));

                        if (!matchesQuery) {
                          return const SizedBox.shrink();
                        }

                        return AnimatedListItem(
                          index: index,
                          child: _PersonListCard(
                            person: person,
                            tags: tags,
                            onTap: () =>
                                context.go('/person/${person.id.value}'),
                            onDelete: () => _confirmDeletePerson(person),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'إضافة سريعة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _quickActionItem(
                    context,
                    Icons.person_add,
                    'شخص جديد',
                    () {
                      Navigator.pop(ctx);
                      _showAddPersonDialog(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  _quickActionItem(
                    context,
                    Icons.receipt_long,
                    'دين جديد',
                    () {
                      Navigator.pop(ctx);
                      context.go('/all-debts');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

                final personRepo = ref.read(personRepositoryProvider);
                final existing = await personRepo.findByName(name);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (existing != null) {
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

                final phone = phoneController.text.trim();
                final createPerson = ref.read(createPersonProvider);
                await createPerson(
                  name: name,
                  phone: phone.isEmpty ? null : phone,
                );
                await ref.read(peoplePaginatedProvider.notifier).refresh();
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}

// ─── بطاقة الشخص ───
class _PersonListCard extends StatelessWidget {
  final Person person;
  final Map<String, int> tags;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PersonListCard({
    required this.person,
    required this.tags,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = colorForPerson(person.id.value, person.name, tags);
    final hasPhone = person.phone != null && person.phone!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Hero(
                  tag: 'person_avatar_${person.id.value}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: avatarColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: avatarColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      person.name.trim().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: avatarColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        person.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (hasPhone) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 13,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                person.phone!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                if (hasPhone)
                  IconButton(
                    icon: const Icon(Icons.chat, color: Colors.green),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: context.l10n.whatsappTooltip,
                    onPressed: () async {
                      await WhatsAppService.sendReminder(
                        phone: person.phone!,
                        message: context.l10n.whatsappGeneralMessage,
                      );
                    },
                  ),

                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.delete,
                  onPressed: onDelete,
                ),

                const Icon(
                  Icons.chevron_left,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}