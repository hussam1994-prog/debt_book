import '../entities/person.dart';
import '../value_objects/person_id.dart';

/// عقد مستودع الأشخاص.
abstract class PersonRepository {
  /// حفظ شخص جديد.
  Future<void> save(Person person);

  /// البحث عن شخص بواسطة المعرّف.
  Future<Person?> findById(PersonId id);

  /// جميع الأشخاص غير المحذوفين.
  Future<List<Person>> findAll();

  /// صفحة من الأشخاص لدعم التحميل التدريجي (pagination).
  Future<List<Person>> findAllPaginated({int limit = 50, int offset = 0});

  Future<void> update(Person person);

  Future<void> softDelete(PersonId id);

  Future<Person?> findByName(String name);
}