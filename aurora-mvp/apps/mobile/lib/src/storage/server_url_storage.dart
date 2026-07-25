import 'package:shared_preferences/shared_preferences.dart';

abstract class ServerUrlStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesServerUrlStorage implements ServerUrlStorage {
  static const _key = 'aurora_server_url';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}

class MemoryServerUrlStorage implements ServerUrlStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}
