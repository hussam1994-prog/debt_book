import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

final debtsPaginatedProvider =
    NotifierProvider<DebtsPaginatedNotifier, List<(Debt, String)>>(() {
  return DebtsPaginatedNotifier();
});

class DebtsPaginatedNotifier extends Notifier<List<(Debt, String)>> {
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  static const int _pageSize = 50;

  @override
  List<(Debt, String)> build() => [];

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    try {
      final repo = ref.read(debtRepositoryProvider);
      final newItems = await repo.findAllPaginatedWithPersonName(
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