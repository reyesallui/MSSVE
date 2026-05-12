import 'dart:convert';

import '../models/usuario.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/crypto_helper.dart';
import '../utils/get_calculator.dart';

// Capa de datos del perfil: consulta, actualizacion y cambio de contrasena
class RepositoryPerfil {
  final DatabaseService _db;
  final StorageService _storageService;

  RepositoryPerfil({
    required DatabaseService db,
    required StorageService storageService,
  })  : _db = db,
        _storageService = storageService;

  
  Future<Usuario> getUsuario(int id) async {
    try {
      final results = await _db.query(
        '''SELECT id, nombre, apellidos, email, peso, altura,
           genero, objetivo, nivel_actividad,
           gasto_energetico_total, edad, fecha_registro
           FROM usuarios WHERE id = ?''',
        [id],
      );

      if (results.isEmpty) throw Exception('error.unknown');

      final usuario = Usuario.fromJson(Map<String, dynamic>.from(results.first));
      
      await _storageService.saveUserJson(jsonEncode(usuario.toJson()));
      return usuario;
    } catch (e) {
      if (e.toString().contains('error.')) rethrow;
      throw Exception('error.unknown');
    }
  }

  
  
  
  Future<Usuario> actualizarPerfil({
    required int id,
    required String nombre,
    required String apellidos,
    required String email,
    required double peso,
    required int altura,
    required String genero,
    required String objetivo,
    required String nivelActividad,
    required int edad,
  }) async {
    try {
      final nuevoGet = GETCalculator.calcularGET(
// Recalcula el gasto energetico total (GET) al actualizar peso/altura/edad/objetivo
        peso: peso,
        altura: altura,
        edad: edad,
        genero: genero,
        nivelActividad: nivelActividad,
        objetivo: objetivo,
      );

      await _db.query(
        '''UPDATE usuarios SET
           nombre = ?, apellidos = ?, email = ?, peso = ?, altura = ?,
           genero = ?, objetivo = ?, nivel_actividad = ?,
           gasto_energetico_total = ?, edad = ?
           WHERE id = ?''',
        [nombre, apellidos, email, peso, altura,
         genero, objetivo, nivelActividad, nuevoGet, edad, id],
      );

      return await getUsuario(id);
    } catch (e) {
      if (e.toString().contains('error.')) rethrow;
      throw Exception('error.unknown');
    }
  }

  
  
// Verifica contrasena actual contra hash almacenado antes de actualizar
  Future<void> cambiarPassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final results = await _db.query(
        'SELECT password_hash FROM usuarios WHERE id = ?',
        [userId],
      );

      if (results.isEmpty) throw Exception('error.unknown');

      final storedHash  = results.first['password_hash'] as String;
      final currentHash = CryptoHelper.hashPassword(currentPassword);

      if (storedHash != currentHash) {
        throw Exception('perfil.error_wrong_password');
      }

      final newHash = CryptoHelper.hashPassword(newPassword);
      await _db.query(
        'UPDATE usuarios SET password_hash = ? WHERE id = ?',
        [newHash, userId],
      );
    } catch (e) {
      if (e.toString().contains('perfil.') ||
          e.toString().contains('error.')) {
        rethrow;
      }
      throw Exception('error.unknown');
    }
  }
}