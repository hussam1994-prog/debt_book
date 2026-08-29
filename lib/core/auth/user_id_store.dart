import 'package:shared_preferences/shared_preferences.dart';

class UserIdStore {
  static const _key = 'last_user_id';

  Future<String?> getLastUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, userId);
  }
}