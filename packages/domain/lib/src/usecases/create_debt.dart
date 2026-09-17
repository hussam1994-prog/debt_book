import '../entities/debt.dart';
import '../entities/ledger_entry.dart';
import '../enums/debt_status.dart';
import '../enums/ledger_entry_type.dart';
import '../repositories/debt_repository.dart';
import '../repositories/person_repository.dart';
import '../services/uuid_generator.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/ledger_entry_id.dart';
import '../value_objects/money.dart';
import '../value_objects/person_id.dart';

/// حالة استخدام: إنشاء دين جديد مع قيده الافتتاحي.
class CreateDebt {
  final DebtRepository _debtRepository;
  final PersonRepository _personRepository;
  final UuidGenerator _uuidGenerator;

  CreateDebt({
    required DebtRepository debtRepository,
    required PersonRepository personRepository,
    required UuidGenerator uuidGenerator,
  })  : _debtRepository = debtRepository,
        _personRepository = personRepository,
        _uuidGenerator = uuidGenerator;

  /// ينفذ العملية ويرجع الدين المُنشأ.
  Future<Debt> call({
    required PersonId personId,
    required Money amount,
    String? description,
    DateTime? dueDate,
    String? attachmentPath,
  }) async {
    // التحقق من وجود الشخص
    final person = await _personRepository.findById(personId);
    if (person == null) {
      throw ArgumentError('Person not found: $personId');
    }

    final now = DateTime.now();
    final debt = Debt(
      id: DebtId(_uuidGenerator.generateUuidV7()),
      personId: personId,
      description: description,
      amount: amount,
      dueDate: dueDate,
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
      attachmentPath: attachmentPath,
    );

    // القيد الافتتاحي: زيادة الالتزام (موجب)
    final initialEntry = LedgerEntry(
      id: LedgerEntryId(_uuidGenerator.generateUuidV7()),
      debtId: debt.id,
      entryType: LedgerEntryType.debt_creation,
      amount: amount,
      createdAt: now,
    );

    await _debtRepository.createDebt(debt, initialEntry);
    return debt;
  }
}