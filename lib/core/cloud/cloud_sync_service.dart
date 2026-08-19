import 'package:domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSyncService {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------- Persons ----------

  /// حفظ أو تحديث شخص على السحابة
  Future<void> savePerson(Person person) async {
    await _client.from('persons').upsert({
      'id': person.id.value,
      'name': person.name,
      'phone': person.phone,
      'email': person.email,
      'created_at': person.createdAt.toIso8601String(),
      'updated_at': person.updatedAt.toIso8601String(),
      'is_deleted': person.isDeleted,
    });
  }

  /// رفع جميع الأشخاص المحليين إلى السحابة
  Future<void> pushPersonsToCloud(List<Person> persons) async {
    for (final person in persons) {
      await _client.from('persons').upsert({
        'id': person.id.value,
        'name': person.name,
        'phone': person.phone,
        'email': person.email,
        'created_at': person.createdAt.toIso8601String(),
        'updated_at': person.updatedAt.toIso8601String(),
        'is_deleted': person.isDeleted,
      });
    }
  }

  /// جلب جميع الأشخاص غير المحذوفين من السحابة
  Future<List<Map<String, dynamic>>> fetchPersons() async {
    final data = await _client
        .from('persons')
        .select()
        .eq('is_deleted', false);
    return data;
  }

  /// حذف شخص (Soft delete) على السحابة
  Future<void> softDeletePerson(PersonId id) async {
    await _client.from('persons').update({
      'is_deleted': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id.value);
  }

  /// مزامنة من السحابة إلى قاعدة البيانات المحلية (استدعاء callback)
  Future<void> syncPersonsFromCloud({
    required void Function(List<Map<String, dynamic>>) onData,
  }) async {
    final cloudPersons = await fetchPersons();
    onData(cloudPersons);
  }

  // ---------- Debts ----------

  /// رفع جميع الديون المحلية إلى السحابة
  Future<void> pushDebtsToCloud(List<Debt> debts) async {
    for (final debt in debts) {
      await _client.from('debts').upsert({
        'id': debt.id.value,
        'person_id': debt.personId.value,
        'description': debt.description,
        'amount': debt.amount.amount,
        'currency': debt.amount.currency,
        'due_date': debt.dueDate?.toIso8601String(),
        'status': debt.status.name,
        'created_at': debt.createdAt.toIso8601String(),
        'updated_at': debt.updatedAt.toIso8601String(),
        'version': debt.version,
        'is_deleted': debt.isDeleted,
      });
    }
  }

  /// جلب جميع الديون غير المحذوفة من السحابة
  Future<List<Map<String, dynamic>>> fetchDebts() async {
    final data = await _client
        .from('debts')
        .select()
        .eq('is_deleted', false);
    return data;
  }

  // ---------- Payments ----------

  /// رفع جميع الدفعات المحلية إلى السحابة
  Future<void> pushPaymentsToCloud(List<Payment> payments) async {
    for (final payment in payments) {
      await _client.from('payments').upsert({
        'id': payment.id.value,
        'debt_id': payment.debtId.value,
        'amount': payment.amount.amount,
        'currency': payment.amount.currency,
        'payment_date': payment.paymentDate.toIso8601String(),
        'method': payment.method.name,
        'notes': payment.notes,
        'created_at': payment.createdAt.toIso8601String(),
        'updated_at': payment.updatedAt.toIso8601String(),
        'version': payment.version,
        'is_deleted': payment.isDeleted,
      });
    }
  }

  /// جلب جميع الدفعات غير المحذوفة من السحابة
  Future<List<Map<String, dynamic>>> fetchPayments() async {
    final data = await _client
        .from('payments')
        .select()
        .eq('is_deleted', false);
    return data;
  }

  // ---------- Ledger Entries ----------

  /// رفع جميع قيود دفتر الأستاذ المحلية إلى السحابة
  Future<void> pushLedgerEntriesToCloud(List<LedgerEntry> entries) async {
    for (final entry in entries) {
      await _client.from('ledger_entries').upsert({
        'id': entry.id.value,
        'debt_id': entry.debtId.value,
        'entry_type': entry.entryType.name,
        'amount': entry.amount.amount,
        'currency': entry.amount.currency,
        'correlation_id': entry.correlationId?.value,
        'source_entry_id': entry.sourceEntryId?.value,
        'payment_id': entry.paymentId?.value,
        'created_at': entry.createdAt.toIso8601String(),
        'server_sequence': entry.serverSequence,
      });
    }
  }

  /// جلب جميع قيود دفتر الأستاذ من السحابة
  Future<List<Map<String, dynamic>>> fetchLedgerEntries() async {
    final data = await _client.from('ledger_entries').select();
    return data;
  }
}