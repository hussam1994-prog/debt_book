import 'package:uuid/uuid.dart';

/// مولد المعرّفات الفريدة.
abstract class UuidGenerator {
  String generateUuidV7();
}

/// التنفيذ الافتراضي باستخدام حزمة uuid.
class DefaultUuidGenerator implements UuidGenerator {
  final Uuid _uuid;

  DefaultUuidGenerator({Uuid? uuid}) : _uuid = uuid ?? Uuid();

  @override
  String generateUuidV7() {
    return _uuid.v7();
  }
}