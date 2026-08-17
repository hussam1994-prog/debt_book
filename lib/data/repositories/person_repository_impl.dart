import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';
import '../mappers/person_mapper.dart';
import 'package:drift/drift.dart';

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
            // ⬇️ version و isDeleted عندهم withDefault بالجدول → لازم Value()
            version: Value(person.version),
            isDeleted: Value(person.isDeleted),
            deletedAt: Value(person.deletedAt?.millisecondsSinceEpoch),
          ),
          // ⚠️ ملاحظة: لو "save" تُستخدم أيضاً للتحديث بوجود نفس id،
          // insert() الافتراضي بيفشل. لو تحتاج upsert أضف:
          // mode: InsertMode.insertOrReplace
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
    final rows = await _db.select(_db.persons).get();
    return rows.map(PersonMapper.fromRow).toList();
  }
}