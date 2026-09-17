import '../repositories/person_repository.dart';
import '../value_objects/person_id.dart';

class DeletePerson {
  final PersonRepository _repository;

  const DeletePerson(this._repository);

  Future<void> call(PersonId id) async {
    await _repository.softDelete(id);
  }
}