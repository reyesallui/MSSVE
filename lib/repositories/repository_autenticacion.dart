import 'dart:convert';

import '../models/usuario.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/crypto_helper.dart';

// Capa de datos de autenticacion: login, registro, sesion cacheada y logout
class RepositoryAutenticacion {
  final DatabaseService _db;
  final StorageService _storageService;

  RepositoryAutenticacion({
    required DatabaseService db,
    required StorageService storageService,
  })  : _db = db,
        _storageService = storageService;

  Future<Usuario> login({
    required String email,
    required String password,
  }) async {
    try {
      final passwordHash = CryptoHelper.hashPassword(password);
// Compara hash SHA-256 contra almacenado en BD
      final results = await _db.query(
        'SELECT * FROM usuarios WHERE email = ?',
        [email],
      );
      if (results.isEmpty) throw Exception('login.error_invalid');
      final row = results.first;
      if (row['password_hash'] != passwordHash) {
        throw Exception('login.error_invalid');
      }
      final usuario = Usuario.fromJson(Map<String, dynamic>.from(row));
// Convierte fila SQL a objeto Usuario y guarda sesion local
      await _storageService.saveUserId(usuario.id);
      await _storageService.saveUserJson(jsonEncode(usuario.toJson()));
      return usuario;
    } catch (e) {
      if (e.toString().contains('login.') ||
          e.toString().contains('error.')) {
        rethrow;
      }
      throw Exception('error.unknown');
    }
  }

// Inserta nuevo usuario con hash y GET calculado; lanza error si email ya existe
  Future<Usuario> register({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
    required double peso,
    required int altura,
    required String genero,
    required String objetivo,
    required String nivelActividad,
    required double get,
    required int edad,
  }) async {
    try {
      final passwordHash = CryptoHelper.hashPassword(password);
// Compara hash SHA-256 contra almacenado en BD
      final existing = await _db.query(
        'SELECT id FROM usuarios WHERE email = ?',
        [email],
      );
      if (existing.isNotEmpty) throw Exception('register.error_email_exists');

      
      
      final insertId = await _db.insert(
        '''INSERT INTO usuarios
           (nombre, apellidos, email, password_hash, peso, altura,
            genero, objetivo, nivel_actividad, gasto_energetico_total, edad)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [nombre, apellidos, email, passwordHash, peso, altura,
         genero, objetivo, nivelActividad, get, edad],
      );

      final results = await _db.query(
        'SELECT * FROM usuarios WHERE id = ?', [insertId],
      );
      final usuario = Usuario.fromJson(Map<String, dynamic>.from(results.first));
      await _storageService.saveUserId(usuario.id);
      await _storageService.saveUserJson(jsonEncode(usuario.toJson()));
      return usuario;
    } catch (e) {
      if (e.toString().contains('register.') ||
          e.toString().contains('error.')) {
        rethrow;
      }
      throw Exception('error.unknown');
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

// Intenta restaurar sesion desde JSON local primero, luego desde BD si el JSON falla
  Future<Usuario?> getUsuarioCacheado() async {
    try {
      final hasSession = await _storageService.hasSession();
      if (!hasSession) return null;
      final userJson = await _storageService.getUserJson();
      if (userJson != null) {
        try {
          return Usuario.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        } catch (_) {}
      }
      final userId = await _storageService.getUserId();
      if (userId == null) return null;
      final results = await _db.query(
        'SELECT * FROM usuarios WHERE id = ?', [userId],
      );
      if (results.isEmpty) return null;
      final usuario = Usuario.fromJson(Map<String, dynamic>.from(results.first));
      await _storageService.saveUserJson(jsonEncode(usuario.toJson()));
      return usuario;
    } catch (_) {
      return null;
    }
  }
}