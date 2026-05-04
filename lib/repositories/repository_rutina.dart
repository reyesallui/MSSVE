import 'dart:convert';
import '../models/ejercicio.dart';
import '../models/rutina.dart';
import '../models/rutina_ejercicio.dart';
import '../services/database_service.dart';

class RepositoryRutina {
  final DatabaseService _db;

  RepositoryRutina({required DatabaseService db}) : _db = db;

  Future<List<Rutina>> getRutinas(int idUsuario) async {
    try {
      final rutinasRows = await _db.query(
        'SELECT * FROM rutinas WHERE id_usuario = ? ORDER BY fecha DESC',
        [idUsuario],
      );

      final List<Rutina> rutinas = [];

      for (final rutina in rutinasRows) {
        final ejerciciosRows = await _db.query(
          '''SELECT
              re.id, re.id_rutina, re.id_ejercicio,
              re.series, re.repeticiones, re.peso_kg,
              re.duracion_minutos, re.series_detalle,
              e.id           AS e_id,
              e.id_usuario   AS e_id_usuario,
              e.nombre_es    AS e_nombre_es,
              e.nombre_en    AS e_nombre_en,
              e.nombre_fr    AS e_nombre_fr,
              e.es_cardio,
              e.grupo_muscular,
              e.es_personalizado
            FROM rutina_ejercicio re
            JOIN ejercicios e ON re.id_ejercicio = e.id
            WHERE re.id_rutina = ?''',
          [rutina['id']],
        );

        final ejercicios = ejerciciosRows.map((row) => {
          'id':               row['id'],
          'id_rutina':        row['id_rutina'],
          'id_ejercicio':     row['id_ejercicio'],
          'series':           row['series'],
          'repeticiones':     row['repeticiones'],
          'peso_kg':          row['peso_kg'],
          'duracion_minutos': row['duracion_minutos'],
          'series_detalle':   row['series_detalle'],
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

        rutinas.add(Rutina.fromJson({
          ...Map<String, dynamic>.from(rutina),
          'ejercicios': ejercicios,
        }));
      }

      return rutinas;
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<Rutina> crearRutina({
    required int idUsuario,
    required String nombre,
    required String fecha,
    String? notas,
  }) async {
    try {
      final insertId = await _db.insert(
        'INSERT INTO rutinas (id_usuario, nombre, fecha, notas) VALUES (?, ?, ?, ?)',
        [idUsuario, nombre, fecha, notas],
      );
      final results = await _db.query(
        'SELECT * FROM rutinas WHERE id = ?', [insertId],
      );
      return Rutina.fromJson({
        ...Map<String, dynamic>.from(results.first),
        'ejercicios': [],
      });
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<Rutina> editarRutina({
    required int id,
    String? nombre,
    String? fecha,
    String? notas,
  }) async {
    try {
      final current = await _db.query(
        'SELECT * FROM rutinas WHERE id = ?', [id],
      );
      final c = current.first;
      await _db.query(
        'UPDATE rutinas SET nombre = ?, fecha = ?, notas = ? WHERE id = ?',
        [nombre ?? c['nombre'], fecha ?? c['fecha'], notas ?? c['notas'], id],
      );
      final rutinas = await getRutinas(c['id_usuario'] as int);
      return rutinas.firstWhere((r) => r.id == id);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<void> eliminarRutina(int id) async {
    try {
      await _db.query('DELETE FROM rutinas WHERE id = ?', [id]);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<Rutina> duplicarRutina({
    required Rutina rutina,
    required String nuevoNombre,
    required String nuevaFecha,
  }) async {
    try {
      final insertId = await _db.insert(
        'INSERT INTO rutinas (id_usuario, nombre, fecha, notas) VALUES (?, ?, ?, ?)',
        [rutina.idUsuario, nuevoNombre, nuevaFecha, rutina.notas],
      );
      for (final re in rutina.ejercicios) {
        final detalleJson = re.seriesDetalle.isEmpty
            ? null
            : jsonEncode(re.seriesDetalle.map((s) => s.toJson()).toList());
        await _db.insert(
          '''INSERT INTO rutina_ejercicio
             (id_rutina, id_ejercicio, series, repeticiones, peso_kg,
              duracion_minutos, series_detalle)
             VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [insertId, re.idEjercicio, re.series,
           re.repeticiones, re.pesoKg, re.duracionMinutos, detalleJson],
        );
      }
      final rutinas = await getRutinas(rutina.idUsuario);
      return rutinas.firstWhere((r) => r.id == insertId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<List<Ejercicio>> buscarEjercicios({
    required String search,
    required int idUsuario,
    bool? esCardio,
  }) async {
    try {
      // Buscamos en los tres idiomas para que la búsqueda funcione
      // independientemente del idioma activo
      String sql = '''SELECT * FROM ejercicios
          WHERE (nombre_es LIKE ? OR nombre_en LIKE ? OR nombre_fr LIKE ?)
          AND (id_usuario IS NULL OR id_usuario = ?)''';
      final params = <dynamic>[
        '%$search%', '%$search%', '%$search%', idUsuario,
      ];

      if (esCardio != null) {
        sql += ' AND es_cardio = ?';
        params.add(esCardio ? 1 : 0);
      }

      sql += ' ORDER BY es_personalizado ASC, nombre_es ASC';

      final results = await _db.query(sql, params);
      return results
          .map((row) => Ejercicio.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<Ejercicio> crearEjercicio({
    required int idUsuario,
    required String nombre,
    required bool esCardio,
    String? grupoMuscular,
  }) async {
    try {
      // Para ejercicios personalizados el usuario solo pone un nombre
      // lo guardamos en los tres idiomas para mantener la estructura
      final insertId = await _db.insert(
        '''INSERT INTO ejercicios
           (id_usuario, nombre_es, nombre_en, nombre_fr,
            es_cardio, grupo_muscular, es_personalizado)
           VALUES (?, ?, ?, ?, ?, ?, true)''',
        [idUsuario, nombre, nombre, nombre,
         esCardio ? 1 : 0, grupoMuscular],
      );
      final results = await _db.query(
        'SELECT * FROM ejercicios WHERE id = ?', [insertId],
      );
      return Ejercicio.fromJson(Map<String, dynamic>.from(results.first));
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<RutinaEjercicio> anadirEjercicioARutina({
    required int idRutina,
    required int idEjercicio,
    int? series,
    int? repeticiones,
    double? pesoKg,
    int? duracionMinutos,
    List<SerieDetalle> seriesDetalle = const [],
  }) async {
    try {
      final detalleJson = seriesDetalle.isEmpty
          ? null
          : jsonEncode(seriesDetalle.map((s) => s.toJson()).toList());
      final insertId = await _db.insert(
        '''INSERT INTO rutina_ejercicio
           (id_rutina, id_ejercicio, series, repeticiones, peso_kg,
            duracion_minutos, series_detalle)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [idRutina, idEjercicio, series, repeticiones,
         pesoKg, duracionMinutos, detalleJson],
      );
      return await _getRutinaEjercicioById(insertId);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<RutinaEjercicio> modificarRutinaEjercicio({
    required int id,
    int? series,
    int? repeticiones,
    double? pesoKg,
    int? duracionMinutos,
    List<SerieDetalle> seriesDetalle = const [],
  }) async {
    try {
      final current = await _db.query(
        'SELECT * FROM rutina_ejercicio WHERE id = ?', [id],
      );
      final c = current.first;
      final detalleJson = seriesDetalle.isEmpty
          ? c['series_detalle']
          : jsonEncode(seriesDetalle.map((s) => s.toJson()).toList());
      await _db.query(
        '''UPDATE rutina_ejercicio SET
           series = ?, repeticiones = ?, peso_kg = ?,
           duracion_minutos = ?, series_detalle = ?
           WHERE id = ?''',
        [series ?? c['series'], repeticiones ?? c['repeticiones'],
         pesoKg ?? c['peso_kg'], duracionMinutos ?? c['duracion_minutos'],
         detalleJson, id],
      );
      return await _getRutinaEjercicioById(id);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<void> eliminarEjercicioDeRutina(int id) async {
    try {
      await _db.query('DELETE FROM rutina_ejercicio WHERE id = ?', [id]);
    } catch (e) {
      throw Exception('error.unknown');
    }
  }

  Future<RutinaEjercicio> _getRutinaEjercicioById(int id) async {
    final rows = await _db.query(
      '''SELECT
          re.id, re.id_rutina, re.id_ejercicio,
          re.series, re.repeticiones, re.peso_kg,
          re.duracion_minutos, re.series_detalle,
          e.id           AS e_id,
          e.id_usuario   AS e_id_usuario,
          e.nombre_es    AS e_nombre_es,
          e.nombre_en    AS e_nombre_en,
          e.nombre_fr    AS e_nombre_fr,
          e.es_cardio,
          e.grupo_muscular,
          e.es_personalizado
        FROM rutina_ejercicio re
        JOIN ejercicios e ON re.id_ejercicio = e.id
        WHERE re.id = ?''',
      [id],
    );
    final row = rows.first;
    return RutinaEjercicio.fromJson({
      'id':               row['id'],
      'id_rutina':        row['id_rutina'],
      'id_ejercicio':     row['id_ejercicio'],
      'series':           row['series'],
      'repeticiones':     row['repeticiones'],
      'peso_kg':          row['peso_kg'],
      'duracion_minutos': row['duracion_minutos'],
      'series_detalle':   row['series_detalle'],
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