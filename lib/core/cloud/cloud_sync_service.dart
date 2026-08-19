import 'package:domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSyncService {
  final SupabaseClient _client = Supabase.instance.client;

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

  /// ✅ رفع جميع الأشخاص المحليين إلى السحابة (Upsert)
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

  /// مزامنة من السحابة إلى قاعدة البيانات المحلية
  Future<void> syncPersonsFromCloud({
    required void Function(List<Map<String, dynamic>>) onData,
  }) async {
    final cloudPersons = await fetchPersons();
    onData(cloudPersons);
  }
}