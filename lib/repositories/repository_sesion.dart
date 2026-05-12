import 'dart:convert';
import '../models/rutina_ejercicio.dart';
import '../models/sesion_ejercicio.dart';
import '../models/sesion_entrenamiento.dart';
import '../services/database_service.dart';




// Capa de datos de sesiones de entrenamiento: historial, CRUD de ejercicios en sesion
class RepositorySesion {
  final DatabaseService _db;

  RepositorySesion({required DatabaseService db}) : _db = db;

  
  
// Obtiene historial de sesiones ordenado por fecha descendente con nombre de rutina
  Future<List<SesionEntrenamiento>> getHistorial(int idUsuario) async {
    try {
      final sesionesRows = await _db.query(
        '''SELECT s.*, r.nombre AS nombre_rutina
           FROM sesiones_entrenamiento s
           JOIN rutinas r ON s.id_rutina = r.id
           WHERE s.id_usuario = ?
           ORDER BY s.fecha DESC''',
        [idUsuario],
      );

      final List<SesionEntrenamiento> sesiones = [];
      for (final sesion in sesionesRows) {
        final ejercicios =
            await _cargarEjerciciosDeSesion(sesion['id'] as int);
        sesiones.add(SesionEntrenamiento.fromJson({
          ...Map<String, dynamic>.from(sesion),
          'ejercicios': ejercicios,
        }));
      }
      return sesiones;
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  
// Busca sesion existente para reanudarla; permite entrenar la misma rutina varias veces al dia
  Future<SesionEntrenamiento?> getSesionDelDia({
    required int idRutina,
    required int idUsuario,
    required String fecha,
  }) async {
    try {
      final rows = await _db.query(
        '''SELECT s.*, r.nombre AS nombre_rutina
           FROM sesiones_entrenamiento s
           JOIN rutinas r ON s.id_rutina = r.id
           WHERE s.id_rutina = ? AND s.id_usuario = ? AND s.fecha = ?
           LIMIT 1''',
        [idRutina, idUsuario, fecha],
      );
      if (rows.isEmpty) return null;
      final ejercicios = await _cargarEjerciciosDeSesion(rows.first['id'] as int);
      return SesionEntrenamiento.fromJson({
        ...Map<String, dynamic>.from(rows.first),
        'ejercicios': ejercicios,
      });
    } catch (e) {
      return null;
    }
  }

  
  
// Crea sesion desde plantilla de rutina copiando ejercicios y series detalle
  Future<SesionEntrenamiento> crearSesion({
    required int idRutina,
    required int idUsuario,
    required String fecha,
    String? notas,
    required List<RutinaEjercicio> ejerciciosPlantilla,
  }) async {
    try {
      final insertId = await _db.insert(
        'INSERT INTO sesiones_entrenamiento (id_rutina, id_usuario, fecha, notas) VALUES (?, ?, ?, ?)',
        [idRutina, idUsuario, fecha, notas],
      );

      
      for (final re in ejerciciosPlantilla) {
        final seriesJson = re.seriesDetalle.isEmpty
            ? null
            : jsonEncode(re.seriesDetalle.map((s) => s.toJson()).toList());

        await _db.insert(
          'INSERT INTO sesion_ejercicio (id_sesion, id_ejercicio, series_realizadas, duracion_minutos) VALUES (?, ?, ?, ?)',
          [insertId, re.idEjercicio, seriesJson, re.duracionMinutos],
        );
      }

      return await getSesion(insertId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  Future<SesionEntrenamiento> getSesion(int idSesion) async {
    try {
      final rows = await _db.query(
        '''SELECT s.*, r.nombre AS nombre_rutina
           FROM sesiones_entrenamiento s
           JOIN rutinas r ON s.id_rutina = r.id
           WHERE s.id = ?''',
        [idSesion],
      );
      final ejercicios = await _cargarEjerciciosDeSesion(idSesion);
      return SesionEntrenamiento.fromJson({
        ...Map<String, dynamic>.from(rows.first),
        'ejercicios': ejercicios,
      });
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  Future<void> modificarEjercicioSesion({
    required int id,
    required List<SerieDetalle> seriesRealizadas,
    int? duracionMinutos,
  }) async {
    try {
      final seriesJson = seriesRealizadas.isEmpty
          ? null
          : jsonEncode(seriesRealizadas.map((s) => s.toJson()).toList());

      await _db.query(
        'UPDATE sesion_ejercicio SET series_realizadas = ?, duracion_minutos = ? WHERE id = ?',
        [seriesJson, duracionMinutos, id],
      );
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  Future<SesionEjercicio> anadirEjercicioASesion({
    required int idSesion,
    required int idEjercicio,
    List<SerieDetalle> seriesRealizadas = const [],
    int? duracionMinutos,
  }) async {
    try {
      final seriesJson = seriesRealizadas.isEmpty
          ? null
          : jsonEncode(seriesRealizadas.map((s) => s.toJson()).toList());
      final insertId = await _db.insert(
        'INSERT INTO sesion_ejercicio (id_sesion, id_ejercicio, series_realizadas, duracion_minutos) VALUES (?, ?, ?, ?)',
        [idSesion, idEjercicio, seriesJson, duracionMinutos],
      );
      return await _getSesionEjercicioById(insertId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  Future<void> eliminarEjercicioDeSesion(int id) async {
    try {
      await _db.query('DELETE FROM sesion_ejercicio WHERE id = ?', [id]);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  Future<void> eliminarSesion(int id) async {
    try {
      await _db.query(
          'DELETE FROM sesiones_entrenamiento WHERE id = ?', [id]);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  
  
  Future<List<Map<String, dynamic>>> _cargarEjerciciosDeSesion(
      int idSesion) async {
    final rows = await _db.query(
      '''SELECT
          se.id, se.id_sesion, se.id_ejercicio, se.series_realizadas, se.duracion_minutos,
          e.id             AS e_id,
          e.id_usuario     AS e_id_usuario,
          e.nombre_es      AS e_nombre_es,
          e.nombre_en      AS e_nombre_en,
          e.nombre_fr      AS e_nombre_fr,
          e.es_cardio,
          e.grupo_muscular AS e_grupo_muscular,
          e.es_personalizado AS e_es_personalizado
        FROM sesion_ejercicio se
        JOIN ejercicios e ON se.id_ejercicio = e.id
        WHERE se.id_sesion = ?''',
      [idSesion],
    );

    
    return rows.map((row) => {
      'id':                row['id'],
      'id_sesion':         row['id_sesion'],
      'id_ejercicio':      row['id_ejercicio'],
      'series_realizadas': row['series_realizadas'],
      'duracion_minutos':  row['duracion_minutos'],
      'ejercicio': {
        'id':               row['e_id'],
        'id_usuario':       row['e_id_usuario'],
        'nombre_es':        row['e_nombre_es'],
        'nombre_en':        row['e_nombre_en'],
        'nombre_fr':        row['e_nombre_fr'],
        'es_cardio':        row['es_cardio'],
        'grupo_muscular':   row['e_grupo_muscular'],
        'es_personalizado': row['e_es_personalizado'],
      },
    }).toList();
  }

  Future<SesionEjercicio> _getSesionEjercicioById(int id) async {
    final rows = await _db.query(
      '''SELECT
          se.id, se.id_sesion, se.id_ejercicio, se.series_realizadas, se.duracion_minutos,
          e.id             AS e_id,
          e.id_usuario     AS e_id_usuario,
          e.nombre_es      AS e_nombre_es,
          e.nombre_en      AS e_nombre_en,
          e.nombre_fr      AS e_nombre_fr,
          e.es_cardio,
          e.grupo_muscular AS e_grupo_muscular,
          e.es_personalizado AS e_es_personalizado
        FROM sesion_ejercicio se
        JOIN ejercicios e ON se.id_ejercicio = e.id
        WHERE se.id = ?''',
      [id],
    );
    final row = rows.first;
    return SesionEjercicio.fromJson({
      'id':                row['id'],
      'id_sesion':         row['id_sesion'],
      'id_ejercicio':      row['id_ejercicio'],
      'series_realizadas': row['series_realizadas'],
      'duracion_minutos':  row['duracion_minutos'],
      'ejercicio': {
        'id':               row['e_id'],
        'id_usuario':       row['e_id_usuario'],
        'nombre_es':        row['e_nombre_es'],
        'nombre_en':        row['e_nombre_en'],
        'nombre_fr':        row['e_nombre_fr'],
        'es_cardio':        row['es_cardio'],
        'grupo_muscular':   row['e_grupo_muscular'],
        'es_personalizado': row['e_es_personalizado'],
      },
    });
  }

}