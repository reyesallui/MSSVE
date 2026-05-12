import 'dart:convert';
import 'package:crypto/crypto.dart';


// Utilidad de hashing SHA-256 para contrasenas (sin sal por simplicidad, mejorable con bcrypt)
class CryptoHelper {
  
  CryptoHelper._();

  
  
  static String hashPassword(String password) {
    
    final bytes = utf8.encode(password);

    
    final digest = sha256.convert(bytes);

    
    return digest.toString();
  }
}