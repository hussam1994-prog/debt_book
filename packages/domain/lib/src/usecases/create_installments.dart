import '../entities/installment.dart';
import '../entities/debt.dart';
import '../repositories/installment_repository.dart';
import '../services/uuid_generator.dart';
import '../value_objects/installment_id.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/money.dart';

class CreateInstallments {
  final InstallmentRepository _repository;
  final UuidGenerator _uuidGenerator;

  const CreateInstallments({
    required InstallmentRepository repository,
    required UuidGenerator uuidGenerator,
  })  : _repository = repository,
        _uuidGenerator = uuidGenerator;

  /// ينشئ أقساطًا متساوية لدين معين.
  /// [debtId]، [amount]، [numberOfInstallments]، [firstDueDate]، [intervalDays].
  Future<void> call({
    required DebtId debtId,
    required Money amount,
    required int numberOfInstallments,
    required DateTime firstDueDate,
    int intervalDays = 30,
  }) async {
    if (numberOfInstallments <= 0) {
      throw ArgumentError('Number of installments must be positive');
    }

    final installmentAmount = amount.amount ~/ numberOfInstallments;
    final remainder = amount.amount % numberOfInstallments;

    for (var i = 0; i < numberOfInstallments; i++) {
      final dueDate = firstDueDate.add(Duration(days: i * intervalDays));
      final currentAmount = installmentAmount + (i == 0 ? remainder : 0);

      final installment = Installment(
        id: InstallmentId(_uuidGenerator.generateUuidV7()),
        debtId: debtId,
        number: i + 1,
        amount: Money(amount: currentAmount, currency: amount.currency),
        dueDate: dueDate,
        status: InstallmentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.save(installment);
    }
  }
}