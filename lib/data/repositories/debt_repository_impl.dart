import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/database/outbox_repository.dart';
import '../../core/database/tables/outbox_table.dart';
import '../mappers/debt_mapper.dart';
import '../mappers/person_mapper.dart';

class DebtRepositoryImpl implements DebtRepository {
  final AppDatabase _db;
  final OutboxRepository _outboxRepo;

  // ✅ استقبل OutboxRepository من الخارج
  DebtRepositoryImpl(this._db, this._outboxRepo);

  Map<String, dynamic> _debtToSupabaseMap(Debt debt) {
    return {
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
      'deleted_at': debt.deletedAt?.toIso8601String(),
      'attachment_path': debt.attachmentPath,
    };
  }

  Map<String, dynamic> _ledgerEntryToSupabaseMap(LedgerEntry entry) {
    return {
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
    };
  }

  @override
  Future<void> createDebt(Debt debt, LedgerEntry initialEntry) async {
    await _db.transaction(() async {
      await _db.into(_db.debts).insert(
            DebtsCompanion.insert(
              id: debt.id.value,
              personId: debt.personId.value,
              description: Value(debt.description),
              amount: debt.amount.amount,
              currency: Value(debt.amount.currency),
              dueDate: Value(debt.dueDate?.millisecondsSinceEpoch),
              status: Value(debt.status.name),
              createdAt: debt.createdAt.millisecondsSinceEpoch,
              updatedAt: debt.updatedAt.millisecondsSinceEpoch,
              version: Value(debt.version),
              isDeleted: Value(debt.isDeleted),
              deletedAt: Value(debt.deletedAt?.millisecondsSinceEpoch),
              attachmentPath: Value(debt.attachmentPath),
            ),
          );

      await _db.into(_db.ledgerEntries).insert(
            LedgerEntriesCompanion.insert(
              id: initialEntry.id.value,
              debtId: initialEntry.debtId.value,
              entryType: initialEntry.entryType.name,
              amount: initialEntry.amount.amount,
              currency: Value(initialEntry.amount.currency),
              correlationId: Value(initialEntry.correlationId?.value),
              sourceEntryId: Value(initialEntry.sourceEntryId?.value),
              paymentId: Value(initialEntry.paymentId?.value),
              createdAt: initialEntry.createdAt.millisecondsSinceEpoch,
              serverSequence: Value(initialEntry.serverSequence),
            ),
          );

      await _outboxRepo.enqueue(
        entityType: 'debt',
        entityId: debt.id.value,
        operation: OutboxOperation.insert,
        payload: _debtToSupabaseMap(debt),
      );

      await _outboxRepo.enqueue(
        entityType: 'ledger_entry',
        entityId: initialEntry.id.value,
        operation: OutboxOperation.insert,
        payload: _ledgerEntryToSupabaseMap(initialEntry),
      );
    });
  }

  @override
  Future<Debt?> findById(DebtId id) async {
    final row = await (_db.select(_db.debts)
          ..where((t) => t.id.equals(id.value)))
        .getSingleOrNull();
    if (row == null) return null;
    return DebtMapper.fromRow(row);
  }

  @override
  Future<List<Debt>> findByPersonId(PersonId personId) async {
    final rows = await (_db.select(_db.debts)
          ..where((t) => t.personId.equals(personId.value)))
        .get();
    return rows.map(DebtMapper.fromRow).toList();
  }

  @override
  Future<List<Debt>> findAll() async {
    final rows = await _db.select(_db.debts).get();
    return rows.map(DebtMapper.fromRow).toList();
  }

  @override
  Future<List<(Debt, String)>> findAllPaginatedWithPersonName({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = _db.select(_db.debts).join([
      innerJoin(_db.persons, _db.persons.id.equalsExp(_db.debts.personId)),
    ])
      ..where(_db.debts.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(_db.debts.createdAt)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) {
      final debt = DebtMapper.fromRow(row.readTable(_db.debts));
      final person = PersonMapper.fromRow(row.readTable(_db.persons));
      return (debt, person.name);
    }).toList();
  }

  @override
  Future<void> updateDebt(Debt debt) async {
    await _db.transaction(() async {
      await (_db.update(_db.debts)
            ..where((t) => t.id.equals(debt.id.value)))
          .write(DebtsCompanion(
            personId: Value(debt.personId.value),
            description: Value(debt.description),
            amount: Value(debt.amount.amount),
            currency: Value(debt.amount.currency),
            dueDate: Value(debt.dueDate?.millisecondsSinceEpoch),
            status: Value(debt.status.name),
            updatedAt: Value(debt.updatedAt.millisecondsSinceEpoch),
            version: Value(debt.version),
            isDeleted: Value(debt.isDeleted),
            deletedAt: Value(debt.deletedAt?.millisecondsSinceEpoch),
            attachmentPath: Value(debt.attachmentPath),
          ));

      await _outboxRepo.enqueue(
        entityType: 'debt',
        entityId: debt.id.value,
        operation: OutboxOperation.update,
        payload: _debtToSupabaseMap(debt),
      );
    });
  }

  @override
  Future<List<PersonDebtSummary>> getDebtsGroupedByPerson() async {
    final query = '''
      SELECT
        p.id AS person_id,
        p.name AS person_name,
        COALESCE(SUM(le.amount), 0) AS total_outstanding,
        COUNT(DISTINCT d.id) AS debt_count,
        MAX(d.due_date) AS last_due_date
      FROM persons p
      INNER JOIN debts d ON d.person_id = p.id
      LEFT JOIN ledger_entries le ON le.debt_id = d.id
      WHERE d.is_deleted = 0 AND d.status != 'cancelled'
      GROUP BY p.id, p.name
      ORDER BY total_outstanding DESC
    ''';

    final rows = await _db.customSelect(query,
        readsFrom: {_db.persons, _db.debts, _db.ledgerEntries}).get();

    return rows.map((row) {
      final personId = PersonId(row.read<String>('person_id'));
      final personName = row.read<String>('person_name');
      final total = row.read<int>('total_outstanding');
      final count = row.read<int>('debt_count');
      final dueDate = row.read<DateTime?>('last_due_date');

      return PersonDebtSummary(
        personId: personId,
        personName: personName,
        totalOutstanding: Money(amount: total),
        debtCount: count,
        lastDueDate: dueDate,
      );
    }).toList();
  }

  @override
  Future<void> softDelete(DebtId id) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      await (_db.update(_db.debts)
            ..where((t) => t.id.equals(id.value)))
          .write(DebtsCompanion(
            isDeleted: const Value(true),
            deletedAt: Value(now.millisecondsSinceEpoch),
            updatedAt: Value(now.millisecondsSinceEpoch),
            status: const Value('cancelled'),
            version: const Value(1),
          ));

      final updatedRow = await (_db.select(_db.debts)
            ..where((t) => t.id.equals(id.value)))
          .getSingle();
      final updatedDebt = DebtMapper.fromRow(updatedRow);

      await _outboxRepo.enqueue(
        entityType: 'debt',
        entityId: id.value,
        operation: OutboxOperation.update,
        payload: _debtToSupabaseMap(updatedDebt),
      );
    });
  }
}