import 'dart:convert';
import '../models/rutina_ejercicio.dart';
import '../models/sesion_ejercicio.dart';
import '../models/sesion_entrenamiento.dart';
import '../services/database_service.dart';

// Gestiona todas las operaciones de BD del diario de entrenamiento.
// Sigue el mismo patrón que RepositoryRutina — todos los métodos
// son async y lanzan Exception si algo falla.
class RepositorySesion {
  final DatabaseService _db;

  RepositorySesion({required DatabaseService db}) : _db = db;

  // Carga todo el historial del usuario, del más reciente al más antiguo.
  // Hace JOIN con rutinas para traer el nombre de la plantilla usada.
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

  // Busca si ya existe una sesión de esta rutina para el usuario en la fecha dada.
  // Devuelve la sesión si existe, o null si no hay ninguna.
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

  // Crea una sesión nueva copiando los ejercicios de la plantilla como punto
  // de partida. El usuario puede modificar los pesos reales después.
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

      // Copiamos cada ejercicio de la plantilla con sus series como punto de partida
      for (final re in ejerciciosPlantilla) {
        final seriesJson = re.seriesDetalle.isEmpty
            ? null
            : jsonEncode(re.seriesDetalle.map((s) => s.toJson()).toList());

        await _db.insert(
          'INSERT INTO sesion_ejercicio (id_sesion, id_ejercicio, series_realizadas) VALUES (?, ?, ?)',
          [insertId, re.idEjercicio, seriesJson],
        );
      }

      return await getSesion(insertId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  // Carga una sesión concreta con todos sus ejercicios
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

  // Guarda los pesos y series reales que el usuario hizo en un ejercicio
  Future<void> modificarEjercicioSesion({
    required int id,
    required List<SerieDetalle> seriesRealizadas,
  }) async {
    try {
      final seriesJson = seriesRealizadas.isEmpty
          ? null
          : jsonEncode(seriesRealizadas.map((s) => s.toJson()).toList());

      await _db.query(
        'UPDATE sesion_ejercicio SET series_realizadas = ? WHERE id = ?',
        [seriesJson, id],
      );
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  // Añade un ejercicio extra a la sesión con sus series ya definidas
  Future<SesionEjercicio> anadirEjercicioASesion({
    required int idSesion,
    required int idEjercicio,
    List<SerieDetalle> seriesRealizadas = const [],
  }) async {
    try {
      final seriesJson = seriesRealizadas.isEmpty
          ? null
          : jsonEncode(seriesRealizadas.map((s) => s.toJson()).toList());
      final insertId = await _db.insert(
        'INSERT INTO sesion_ejercicio (id_sesion, id_ejercicio, series_realizadas) VALUES (?, ?, ?)',
        [idSesion, idEjercicio, seriesJson],
      );
      return await _getSesionEjercicioById(insertId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  // Elimina un ejercicio de la sesión
  Future<void> eliminarEjercicioDeSesion(int id) async {
    try {
      await _db.query('DELETE FROM sesion_ejercicio WHERE id = ?', [id]);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  // Elimina una sesión completa — los ejercicios se borran en cascada por la FK
  Future<void> eliminarSesion(int id) async {
    try {
      await _db.query(
          'DELETE FROM sesiones_entrenamiento WHERE id = ?', [id]);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  // Carga los ejercicios de una sesión con JOIN para traer los datos del ejercicio.
  // Devuelve una lista de Maps que luego SesionEjercicio.fromJson convierte a objetos.
  Future<List<Map<String, dynamic>>> _cargarEjerciciosDeSesion(
      int idSesion) async {
    final rows = await _db.query(
      '''SELECT
          se.id, se.id_sesion, se.id_ejercicio, se.series_realizadas,
          e.id           AS e_id,
          e.id_usuario   AS e_id_usuario,
          e.nombre_es    AS e_nombre_es,
          e.nombre_en    AS e_nombre_en,
          e.nombre_fr    AS e_nombre_fr,
          e.es_cardio,
          e.grupo_muscular,
          e.es_personalizado
        FROM sesion_ejercicio se
        JOIN ejercicios e ON se.id_ejercicio = e.id
        WHERE se.id_sesion = ?''',
      [idSesion],
    );

    // Construimos el Map anidado que espera SesionEjercicio.fromJson
    return rows.map((row) => {
      'id':                row['id'],
      'id_sesion':         row['id_sesion'],
      'id_ejercicio':      row['id_ejercicio'],
      'series_realizadas': row['series_realizadas'],
      'ejercicio': {
        'id':               row['e_id'],
        'id_usuario':       row['e_id_usuario'],
        'nombre_es':        row['e_nombre_es'],
        'nombre_en':        row['e_nombre_en'],
        'nombre_fr':        row['e_nombre_fr'],
        'es_cardio':        row['es_cardio'],
        'grupo_muscular':   row['grupo_muscular'],
        'es_personalizado': row['es_personalizado'],
      },
    }).toList();
  }

  Future<SesionEjercicio> _getSesionEjercicioById(int id) async {
    final rows = await _db.query(
      '''SELECT
          se.id, se.id_sesion, se.id_ejercicio, se.series_realizadas,
          e.id           AS e_id,
          e.id_usuario   AS e_id_usuario,
          e.nombre_es    AS e_nombre_es,
          e.nombre_en    AS e_nombre_en,
          e.nombre_fr    AS e_nombre_fr,
          e.es_cardio,
          e.grupo_muscular,
          e.es_personalizado
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
      'ejercicio': {
        'id':               row['e_id'],
        'id_usuario':       row['e_id_usuario'],
        'nombre_es':        row['e_nombre_es'],
        'nombre_en':        row['e_nombre_en'],
        'nombre_fr':        row['e_nombre_fr'],
        'es_cardio':        row['es_cardio'],
        'grupo_muscular':   row['grupo_muscular'],
        'es_personalizado': row['es_personalizado'],
      },
    });
  }
}