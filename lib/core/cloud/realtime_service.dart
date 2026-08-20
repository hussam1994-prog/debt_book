import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../features/dashboard/providers/analytics_providers.dart';
import '../../features/people/providers/people_providers.dart';

class RealtimeService {
  final SupabaseClient _client = Supabase.instance.client;
  final Ref _ref;

  RealtimeService(this._ref);

  void start() {
    if (_client.auth.currentUser == null) return;

    // persons
    _client
        .channel('public:persons')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'persons',
          callback: (payload) => _ref.invalidate(peopleProvider),
        )
        .subscribe();

    // debts
    _client
        .channel('public:debts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'debts',
          callback: (payload) => _ref.invalidate(allDebtsProvider),
        )
        .subscribe();

    // payments
    _client
        .channel('public:payments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (payload) => _ref.invalidate(allPaymentsProvider),
        )
        .subscribe();

    // ledger_entries
    _client
        .channel('public:ledger_entries')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ledger_entries',
          callback: (payload) => _ref.invalidate(balancesByDebtProvider),
        )
        .subscribe();
  }

  void stop() {
    _client.removeAllChannels();
  }
}