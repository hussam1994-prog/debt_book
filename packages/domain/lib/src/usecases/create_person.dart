import '../entities/person.dart';
import '../repositories/person_repository.dart';
import '../services/uuid_generator.dart';
import '../value_objects/person_id.dart';

/// حالة استخدام: إنشاء شخص جديد.
class CreatePerson {
  final PersonRepository _personRepository;
  final UuidGenerator _uuidGenerator;

  CreatePerson({
    required PersonRepository personRepository,
    required UuidGenerator uuidGenerator,
  })  : _personRepository = personRepository,
        _uuidGenerator = uuidGenerator;

  /// ينفذ العملية ويرجع الشخص المُنشأ.
  Future<Person> call({
    required String name,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final now = DateTime.now();
    final person = Person(
      id: PersonId(_uuidGenerator.generateUuidV7()),
      name: name,
      phone: phone,
      email: email,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await _personRepository.save(person);
    return person;
  }
}