// apps/mobile/lib/features/debts/providers/ledger_paginated_provider.dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final ledgerPaginatedProvider =
    StateNotifierProvider.family<LedgerPaginatedNotifier, List<LedgerEntry>, DebtId>(
  (ref, debtId) {
    final repo = ref.watch(ledgerRepositoryProvider);
    return LedgerPaginatedNotifier(repo, debtId);
  },
);

class LedgerPaginatedNotifier extends StateNotifier<List<LedgerEntry>> {
  final LedgerRepository _repo;
  final DebtId _debtId;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  static const int _pageSize = 50;

  LedgerPaginatedNotifier(this._repo, this._debtId) : super([]);

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    try {
      final newItems = await _repo.findByDebtIdPaginated(
        _debtId,
        limit: _pageSize,
        offset: _offset,
      );
      state = [...state, ...newItems];
      _offset += newItems.length;
      if (newItems.length < _pageSize) _hasMore = false;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    _offset = 0;
    _hasMore = true;
    state = [];
    await loadMore();
  }
}