import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/database/outbox_repository.dart';
import '../../core/database/tables/outbox_table.dart';
import '../mappers/person_mapper.dart';

class PersonRepositoryImpl implements PersonRepository {
  final AppDatabase _db;
  final OutboxRepository _outboxRepo;

  // ✅ استقبل OutboxRepository من الخارج (لتفعيل Debounce)
  PersonRepositoryImpl(this._db, this._outboxRepo);

  Map<String, dynamic> _personToSupabaseMap(Person person) {
    return {
      'id': person.id.value,
      'name': person.name,
      'phone': person.phone,
      'email': person.email,
      'notes': person.notes,
      'created_at': person.createdAt.toIso8601String(),
      'updated_at': person.updatedAt.toIso8601String(),
      'version': person.version,
      'is_deleted': person.isDeleted,
      'deleted_at': person.deletedAt?.toIso8601String(),
    };
  }

  @override
  Future<void> save(Person person) async {
    await _db.transaction(() async {
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

      await _outboxRepo.enqueue(
        entityType: 'person',
        entityId: person.id.value,
        operation: OutboxOperation.insert,
        payload: _personToSupabaseMap(person),
      );
    });
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
    final rows = await (_db.select(_db.persons)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return rows.map(PersonMapper.fromRow).toList();
  }

  @override
  Future<List<Person>> findAllPaginated({int limit = 50, int offset = 0}) async {
    final rows = await (_db.select(_db.persons)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();
    return rows.map(PersonMapper.fromRow).toList();
  }

  @override
  Future<void> update(Person person) async {
    await _db.transaction(() async {
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

      await _outboxRepo.enqueue(
        entityType: 'person',
        entityId: person.id.value,
        operation: OutboxOperation.update,
        payload: _personToSupabaseMap(person),
      );
    });
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
    await _db.transaction(() async {
      final now = DateTime.now();
      await (_db.update(_db.persons)
            ..where((t) => t.id.equals(id.value)))
          .write(PersonsCompanion(
            isDeleted: Value(true),
            deletedAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            version: Value(1),
          ));

      final updatedRow = await (_db.select(_db.persons)
            ..where((t) => t.id.equals(id.value)))
          .getSingle();
      final updatedPerson = PersonMapper.fromRow(updatedRow);

      await _outboxRepo.enqueue(
        entityType: 'person',
        entityId: id.value,
        operation: OutboxOperation.update,
        payload: _personToSupabaseMap(updatedPerson),
      );
    });
  }
}