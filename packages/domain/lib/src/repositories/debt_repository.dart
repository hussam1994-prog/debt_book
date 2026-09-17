import '../entities/debt.dart';
import '../entities/ledger_entry.dart';
import '../entities/person_debt_summary.dart';
import '../value_objects/debt_id.dart';
import '../value_objects/person_id.dart';

/// عقد مستودع الديون.
abstract class DebtRepository {
  /// إنشاء دين مع قيده الأولي (عملية ذرية).
  Future<void> createDebt(Debt debt, LedgerEntry initialEntry);

  /// البحث عن دين بواسطة المعرّف.
  Future<Debt?> findById(DebtId id);

  /// جلب ديون شخص معين.
  Future<List<Debt>> findByPersonId(PersonId personId);

  /// جميع الديون غير المحذوفة.
  Future<List<Debt>> findAll();

  /// صفحة من الديون مع اسم الشخص (للتحميل التدريجي).
  Future<List<(Debt, String)>> findAllPaginatedWithPersonName({
    int limit = 50,
    int offset = 0,
  });

  Future<List<PersonDebtSummary>> getDebtsGroupedByPerson();

  Future<void> updateDebt(Debt debt);

  Future<void> softDelete(DebtId id);
}