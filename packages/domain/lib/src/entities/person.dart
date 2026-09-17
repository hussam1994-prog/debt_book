import '../value_objects/person_id.dart';

/// كيان الشخص (صاحب الدين أو المُقرِض).
class Person {
  final PersonId id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isDeleted;
  final DateTime? deletedAt;

  Person({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deletedAt,
  }) : assert(name.trim().isNotEmpty, 'Name cannot be empty');
}