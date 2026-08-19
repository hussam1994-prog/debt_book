import 'package:domain/domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSyncService {
  final SupabaseClient _client = Supabase.instance.client;

  /// رفع نسخة احتياطية (مثلاً ملف CSV أو JSON)
  Future<void> uploadBackup({
    required String userId,
    required String filePath,
  }) async {
    // يمكن استخدام Storage لاحقًا
  }

  /// حفظ/تحديث بيانات المستخدم على السحابة
  Future<void> savePerson(Person person) async {
    await _client.from('persons').upsert({
      'id': person.id.value,
      'name': person.name,
      'phone': person.phone,
      'email': person.email,
      'created_at': person.createdAt.toIso8601String(),
      'updated_at': person.updatedAt.toIso8601String(),
    });
  }

  /// جلب جميع الأشخاص من السحابة
  Future<List<Map<String, dynamic>>> fetchPersons() async {
    final data = await _client.from('persons').select();
    return data;
  }
}