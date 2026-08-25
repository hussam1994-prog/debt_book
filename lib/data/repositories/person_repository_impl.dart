import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../mappers/person_mapper.dart';

class PersonRepositoryImpl implements PersonRepository {
  final AppDatabase _db;

  PersonRepositoryImpl(this._db);

  @override
  Future<void> save(Person person) async {
    await _db.into(_db.persons).insert(
          PersonsCompanion.insert(
            id: person.id.value,
            name: person.name,
            phone: Value(person.phone),
            email: Value(person.email),
            notes: Value(person.notes),
            createdAt: person.createdAt.millisecondsSinceEpoch,
            updatedAt: person.updatedAt.millisecondsSinceEpoch,
            version: Value(person.version),
            isDeleted: Value(person.isDeleted),
            deletedAt: Value(person.deletedAt?.millisecondsSinceEpoch),
          ),
        );
  }

  @override
  Future<Person?> findById(PersonId id) async {
    final row = await (_db.select(_db.persons)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) return null;
    return PersonMapper.fromRow(row);
  }

  @override
  Future<List<Person>> findAll() async {
    // ✅ إصلاح: إرجاع الأشخاص غير المحذوفين فقط
    final rows = await (_db.select(_db.persons)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return rows.map(PersonMapper.fromRow).toList();
  }

  @override
  Future<void> update(Person person) async {
    await (_db.update(_db.persons)
          ..where((t) => t.id.equals(person.id.value)))
        .write(PersonsCompanion(
          name: Value(person.name),
          phone: Value(person.phone),
          email: Value(person.email),
          notes: Value(person.notes),
          updatedAt: Value(person.updatedAt.millisecondsSinceEpoch),
          version: Value(person.version),
          isDeleted: Value(person.isDeleted),
          deletedAt: Value(person.deletedAt?.millisecondsSinceEpoch),
        ));
  }
 
  @override
  Future<Person?> findByName(String name) async {
    final all = await findAll();
    for (final person in all) {
      if (person.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        return person;
      }
    }
    return null;
  }
  @override
  Future<void> softDelete(PersonId id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.persons)
          ..where((t) => t.id.equals(id.value)))
        .write(PersonsCompanion(
          isDeleted: Value(true),
          deletedAt: Value(now),
          updatedAt: Value(now),
          version: Value(1),
        ));
  }
}