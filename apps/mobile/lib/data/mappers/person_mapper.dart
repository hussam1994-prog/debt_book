import 'package:domain/domain.dart';
import '../../core/database/app_database.dart';

class PersonMapper {
  static Person fromRow(PersonRow row) {
    return Person(
      id: PersonId(row.id),
      name: row.name,
      phone: row.phone,
      email: row.email,
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      version: row.version,
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
          : null,
    );
  }
}