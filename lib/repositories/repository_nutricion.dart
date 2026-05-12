import 'package:mssve/models/alimento.dart';
import 'package:mssve/models/comida.dart';
import 'package:mssve/models/comida_alimento.dart';
import 'package:mssve/models/registro_diario.dart';
import 'package:mssve/services/database_service.dart';

// Capa de datos de nutricion: registro diario, comidas, alimentos y sus relaciones
class RepositoryNutricion {
  final DatabaseService _db;
  RepositoryNutricion({required DatabaseService db}) : _db = db;

  
  
// Obtiene o crea el registro diario para una fecha; carga comidas, alimentos y recalcula kcal totales
  Future<RegistroDiario> getOCCreateRegistroDiario({
    required int idUsuario,
    required String fecha,
  }) async {
    try {
      final results = await _db.query(
        'SELECT * FROM registros_diarios WHERE id_usuario = ? AND fecha = ?',
        [idUsuario, fecha],
      );

      int registroId;
      if (results.isEmpty) {
        registroId = await _db.insert(
          'INSERT INTO registros_diarios (id_usuario, fecha) VALUES (?, ?)',
          [idUsuario, fecha],
        );
      } else {
        registroId = results.first['id'] as int;
      }

      return await _cargarRegistroCompleto(registroId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  
// Carga registro + comidas + alimentos anidados con JOIN y actualiza kcal_totales_dia
  Future<RegistroDiario> _cargarRegistroCompleto(int registroId) async {
    final registroRows = await _db.query(
      'SELECT * FROM registros_diarios WHERE id = ?',
      [registroId],
    );
    final registroData = Map<String, dynamic>.from(registroRows.first);

    
    final comidasRows = await _db.query(
      'SELECT * FROM comidas WHERE id_registro_diario = ?',
      [registroId],
    );

    final List<Map<String, dynamic>> comidasConAlimentos = [];

    for (final comida in comidasRows) {
      final alimentosRows = await _db.query(
        '''SELECT
            ca.id, ca.id_comida, ca.id_alimento,
            ca.cantidad_gramos, ca.kcal_calculadas,
            a.id         AS a_id,
            a.id_usuario AS a_id_usuario,
            a.nombre     AS a_nombre,
            a.kcal_por_100g,
            a.proteinas_por_100g,
            a.carbohidratos_por_100g,
            a.grasas_por_100g,
            a.es_personalizado
           FROM comida_alimento ca
           JOIN alimentos a ON ca.id_alimento = a.id
           WHERE ca.id_comida = ?''',
        [comida['id']],
      );

      final alimentos = alimentosRows.map((row) => {
        'id': row['id'],
        'id_comida': row['id_comida'],
        'id_alimento': row['id_alimento'],
        'cantidad_gramos': row['cantidad_gramos'],
        'kcal_calculadas': row['kcal_calculadas'],
        'alimento': {
          'id': row['a_id'],
          'id_usuario': row['a_id_usuario'],
          'nombre': row['a_nombre'],
          'kcal_por_100g': row['kcal_por_100g'],
          'proteinas_por_100g': row['proteinas_por_100g'],
          'carbohidratos_por_100g': row['carbohidratos_por_100g'],
          'grasas_por_100g': row['grasas_por_100g'],
          'es_personalizado': row['es_personalizado'],
        },
      }).toList();

      comidasConAlimentos.add({
        ...Map<String, dynamic>.from(comida),
        'alimentos': alimentos,
      });
    }

    double kcalTotales = 0;
    for (final comida in comidasConAlimentos) {
      for (final a in comida['alimentos'] as List) {
        kcalTotales += double.parse((a['kcal_calculadas'] ?? 0).toString());
      }
    }

    await _db.query(
      'UPDATE registros_diarios SET kcal_totales_dia = ? WHERE id = ?',
      [kcalTotales.toStringAsFixed(2), registroId],
    );

    return RegistroDiario.fromJson({
      ...registroData,
      'kcal_totales_dia': kcalTotales,
      'comidas': comidasConAlimentos,
    });
  }

  
  
  Future<List<Alimento>> buscarAlimentos({
    required String search,
    required int idUsuario,
  }) async {
    try {
      
      
      final results = await _db.query(
        '''SELECT * FROM alimentos
           WHERE nombre LIKE ?
           AND (id_usuario IS NULL OR id_usuario = ?)
           ORDER BY es_personalizado ASC, nombre ASC''',
        ['%$search%', idUsuario],
      );
      return results
          .map((row) => Alimento.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  Future<bool> existeAlimentoConNombre(String nombre, int idUsuario) async {
    try {
      final results = await _db.query(
        '''SELECT COUNT(*) as cnt FROM alimentos
           WHERE LOWER(nombre) = LOWER(?)
           AND id_usuario = ?''',
        [nombre, idUsuario],
      );
      return (int.tryParse(results.first['cnt'].toString()) ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  Future<Alimento> crearAlimento({
    required int idUsuario,
    required String nombre,
    required double kcalPor100g,
    required double proteinasPor100g,
    required double carbohidratosPor100g,
    required double grasasPor100g,
  }) async {
    try {
      final insertId = await _db.insert(
        '''INSERT INTO alimentos
           (id_usuario, nombre, kcal_por_100g, proteinas_por_100g,
            carbohidratos_por_100g, grasas_por_100g, es_personalizado)
           VALUES (?, ?, ?, ?, ?, ?, true)''',
        [idUsuario, nombre, kcalPor100g,
         proteinasPor100g, carbohidratosPor100g, grasasPor100g],
      );
      final results = await _db.query(
        'SELECT * FROM alimentos WHERE id = ?', [insertId],
      );
      return Alimento.fromJson(Map<String, dynamic>.from(results.first));
// Retorna el alimento creado con sus datos completos
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

// Actualiza campos de un alimento existente
  Future<Alimento> editarAlimento({
    required int id,
    required String nombre,
    required double kcalPor100g,
    required double proteinasPor100g,
    required double carbohidratosPor100g,
    required double grasasPor100g,
  }) async {
    try {
      
      await _db.query(
        '''UPDATE alimentos SET
           nombre = ?, kcal_por_100g = ?, proteinas_por_100g = ?,
           carbohidratos_por_100g = ?, grasas_por_100g = ?
           WHERE id = ?''',
        [nombre, kcalPor100g, proteinasPor100g,
         carbohidratosPor100g, grasasPor100g, id],
      );
      final results = await _db.query(
        'SELECT * FROM alimentos WHERE id = ?', [id],
      );
      return Alimento.fromJson(Map<String, dynamic>.from(results.first));
// Retorna el alimento creado con sus datos completos
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<Comida> crearComida({
    required int idRegistroDiario,
    required String tipoComida,
    String? hora,
  }) async {
    try {
      
      final insertId = await _db.insert(
        'INSERT INTO comidas (id_registro_diario, tipo_comida, hora) VALUES (?, ?, ?)',
        [idRegistroDiario, tipoComida, hora],
      );
      final results = await _db.query(
        'SELECT * FROM comidas WHERE id = ?', [insertId],
      );
      return Comida.fromJson({
        ...Map<String, dynamic>.from(results.first),
        'alimentos': const [],
      });
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  
  Future<ComidaAlimento> anadirAlimentoAComida({
    required int idComida,
    required int idAlimento,
    required double cantidadGramos,
  }) async {
    try {
      final alimentoRows = await _db.query(
        'SELECT kcal_por_100g FROM alimentos WHERE id = ?', [idAlimento],
      );
      final kcalPor100g = double.parse(
// Calcula kcal reales del alimento segun la cantidad en gramos
        alimentoRows.first['kcal_por_100g'].toString(),
      );
      final kcalCalculadas =
          ((kcalPor100g * cantidadGramos) / 100).toStringAsFixed(2);

      final insertId = await _db.insert(
        '''INSERT INTO comida_alimento
           (id_comida, id_alimento, cantidad_gramos, kcal_calculadas)
           VALUES (?, ?, ?, ?)''',
        [idComida, idAlimento, cantidadGramos, kcalCalculadas],
      );

      final results = await _db.query(
        '''SELECT
            ca.id, ca.id_comida, ca.id_alimento,
            ca.cantidad_gramos, ca.kcal_calculadas,
            a.id         AS a_id,
            a.id_usuario AS a_id_usuario,
            a.nombre     AS a_nombre,
            a.kcal_por_100g,
            a.proteinas_por_100g,
            a.carbohidratos_por_100g,
            a.grasas_por_100g,
            a.es_personalizado
           FROM comida_alimento ca
           JOIN alimentos a ON ca.id_alimento = a.id
           WHERE ca.id = ?''',
        [insertId],
      );

      final row = results.first;
      return ComidaAlimento.fromJson({
        'id': row['id'],
        'id_comida': row['id_comida'],
        'id_alimento': row['id_alimento'],
        'cantidad_gramos': row['cantidad_gramos'],
        'kcal_calculadas': row['kcal_calculadas'],
        'alimento': {
          'id': row['a_id'],
          'id_usuario': row['a_id_usuario'],
          'nombre': row['a_nombre'],
          'kcal_por_100g': row['kcal_por_100g'],
          'proteinas_por_100g': row['proteinas_por_100g'],
          'carbohidratos_por_100g': row['carbohidratos_por_100g'],
          'grasas_por_100g': row['grasas_por_100g'],
          'es_personalizado': row['es_personalizado'],
        },
      });
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<void> eliminarAlimentoDeComida(int idComidaAlimento) async {
    try {
      await _db.query(
        'DELETE FROM comida_alimento WHERE id = ?',
        [idComidaAlimento],
      );
    } catch (e) {
      throw Exception('error.unknown');
    }
  }
}