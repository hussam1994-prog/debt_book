import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// لون كل شخص (يُخزَّن في SharedPreferences)
final personTagProvider =
    StateNotifierProvider<PersonTagNotifier, Map<String, int>>(
  (ref) => PersonTagNotifier(),
);

class PersonTagNotifier extends StateNotifier<Map<String, int>> {
  PersonTagNotifier() : super({});

  static const _key = 'person_tag_colors';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return;

    try {
      final map = <String, int>{};
      for (final part in json.split(',')) {
        final kv = part.split(':');
        if (kv.length == 2) {
          map[kv[0]] = int.parse(kv[1]);
        }
      }
      state = map;
    } catch (_) {}
  }

  Future<void> setColor(String personId, int colorIndex) async {
    state = {...state, personId: colorIndex};
    await _save();
  }

  Future<void> clearColor(String personId) async {
    final newState = {...state};
    newState.remove(personId);
    state = newState;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = state.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    await prefs.setString(_key, json);
  }
}

/// ✅ الحصول على لون الشخص (مع fallback للاسم)
Color colorForPerson(String personId, String name, Map<String, int> tags) {
  final tagIndex = tags[personId];
  if (tagIndex != null) {
    return _tagColors[tagIndex % _tagColors.length];
  }
  return _colorForName(name);
}

const _tagColors = [
  Color(0xFFEF5350),
  Color(0xFFFFA726),
  Color(0xFFFFCA28),
  Color(0xFF66BB6A),
  Color(0xFF26C6DA),
  Color(0xFF42A5F5),
  Color(0xFF7E57C2),
  Color(0xFFEC407A),
];

Color _colorForName(String name) {
  final colors = [
    Color(0xFF1E3A5F), Color(0xFF2E7D32), Color(0xFFC62828),
    Color(0xFF6A1B9A), Color(0xFFEF6C00), Color(0xFF00838F),
  ];
  return colors[name.hashCode.abs() % colors.length];
}