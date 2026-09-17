import '../entities/person.dart';
import '../repositories/person_repository.dart';

class UpdatePerson {
  final PersonRepository _repository;

  const UpdatePerson(this._repository);

  Future<void> call(Person person) async {
    await _repository.update(person);
  }
}