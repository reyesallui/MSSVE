import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Helper de encriptación de contraseñas usando SHA-256.
class CryptoHelper {
  // Constructor privado: clase de utilidad pura con métodos estáticos.
  CryptoHelper._();

  /// Este mismo hash es el que se almacena en la columna `password_hash`
  /// de la tabla `usuarios` en MySQL.
  static String hashPassword(String password) {
    // utf8.encode convierte el String a List<int> de bytes
    final bytes = utf8.encode(password);

    // sha256.convert calcula el digest
    final digest = sha256.convert(bytes);

    // toString() devuelve la representación hexadecimal del hash.
    return digest.toString();
  }
}