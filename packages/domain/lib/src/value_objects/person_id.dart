/// معرّف شخص غير قابل للتغيير.
class PersonId {
  final String value;

  PersonId(this.value) : assert(value.isNotEmpty, 'PersonId cannot be empty');

  @override
  bool operator ==(Object other) => other is PersonId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}