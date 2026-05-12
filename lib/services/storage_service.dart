import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class _StorageBackend {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class _SecureStorageBackend implements _StorageBackend {
  final FlutterSecureStorage _storage;

  _SecureStorageBackend()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

class _PrefsStorageBackend implements _StorageBackend {
  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class StorageService {
  final _StorageBackend _storage;

  static const _keyUserId = 'user_id';
  static const _keyUserJson = 'user_json';

  StorageService()
      : _storage = Platform.isWindows
            ? _PrefsStorageBackend()
            : _SecureStorageBackend();

  Future<void> saveUserId(int userId) async {
    await _storage.write(_keyUserId, userId.toString());
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(_keyUserId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(_keyUserId);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(_keyUserJson, userJson);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(_keyUserJson);
  }

  Future<void> deleteUserJson() async {
    await _storage.delete(_keyUserJson);
  }

  Future<bool> hasSession() async {
    final userId = await _storage.read(_keyUserId);
    return userId != null && userId.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
