import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Servicio de almacenamiento seguro y persistente en el dispositivo.
// Guarda el ID y JSON del usuario para mantener la sesión entre arranques
// sin que el usuario tenga que iniciar sesión cada vez.
class StorageService {
  final FlutterSecureStorage _storage;

  static const _keyUserId   = 'user_id';
  static const _keyUserJson = 'user_json';

  StorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _keyUserId, value: userId.toString());
  }
  Future<int?> getUserId() async {
    final value = await _storage.read(key: _keyUserId);
    if (value == null) return null;
    return int.tryParse(value);
  }
  Future<void> deleteUserId() async {
    await _storage.delete(key: _keyUserId);
  }
  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: _keyUserJson, value: userJson);
  }
  Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUserJson);
  }
  Future<void> deleteUserJson() async {
    await _storage.delete(key: _keyUserJson);
  }
  // La sesión dura indefinidamente hasta que el usuario cierra sesión
  // manualmente desde el drawer o se desinstala la app
  Future<bool> hasSession() async {
    final userId = await _storage.read(key: _keyUserId);
    return userId != null && userId.isNotEmpty;
  }
  // Borra todos los datos guardados. Se llama únicamente al hacer logout
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}