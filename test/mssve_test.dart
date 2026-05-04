import 'package:flutter_test/flutter_test.dart';
import 'package:mssve/models/ejercicio.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/models/sesion_ejercicio.dart';
import 'package:mssve/models/sesion_entrenamiento.dart';
import 'package:mssve/repositories/repository_sesion.dart';
import 'package:mssve/sesion/sesion_bloc.dart';

// ── REPOSITORIO FALSO ─────────────────────────────────────────────────────
// Simula la BD sin conexión real — devuelve datos controlados para los tests
class _FakeRepo implements RepositorySesion {
  List<SesionEntrenamiento> historial = [];
  SesionEntrenamiento? sesionDelDia;
  SesionEntrenamiento? sesionCreada;
  SesionEntrenamiento? sesionActualizada;

  @override
  Future<List<SesionEntrenamiento>> getHistorial(int idUsuario) async =>
      historial;

  @override
  Future<SesionEntrenamiento> getSesion(int id) async =>
      sesionActualizada ?? historial.firstWhere((s) => s.id == id);

  @override
  Future<SesionEntrenamiento?> getSesionDelDia({
    required int idRutina,
    required int idUsuario,
    required String fecha,
  }) async => sesionDelDia;

  @override
  Future<SesionEntrenamiento> crearSesion({
    required int idRutina,
    required int idUsuario,
    required String fecha,
    String? notas,
    required List<RutinaEjercicio> ejerciciosPlantilla,
  }) async => sesionCreada!;

  @override
  Future<SesionEjercicio> anadirEjercicioASesion({
    required int idSesion,
    required int idEjercicio,
    List<SerieDetalle> seriesRealizadas = const [],
  }) async => _ejercicioFake();

  @override
  Future<void> modificarEjercicioSesion({
    required int id,
    required List<SerieDetalle> seriesRealizadas,
  }) async {}

  @override
  Future<void> eliminarEjercicioDeSesion(int id) async {}

  @override
  Future<void> eliminarSesion(int id) async {
    historial.removeWhere((s) => s.id == id);
  }
}

// ── DATOS DE PRUEBA ───────────────────────────────────────────────────────

SesionEntrenamiento _sesionFake({
  int id = 1,
  List<SesionEjercicio>? ejercicios,
}) =>
    SesionEntrenamiento(
      id: id,
      idRutina: 1,
      idUsuario: 1,
      fecha: DateTime(2025, 1, 15),
      nombreRutina: 'Pecho',
      ejercicios: ejercicios ?? [],
    );

SesionEjercicio _ejercicioFake() => SesionEjercicio(
      id: 10,
      idSesion: 1,
      idEjercicio: 5,
      ejercicio: Ejercicio(
        id: 5,
        nombreEs: 'Press banca',
        nombreEn: 'Bench press',
        nombreFr: 'Développé couché',
        esCardio: false,
        esPersonalizado: false,
      ),
      seriesRealizadas: [const SerieDetalle(reps: 10, peso: 80.0)],
    );

// ── TESTS ─────────────────────────────────────────────────────────────────

void main() {
  late _FakeRepo repo;
  late SesionBloc bloc;

  setUp(() {
    repo = _FakeRepo();
    bloc = SesionBloc(repository: repo);
  });

  tearDown(() => bloc.close());

  // ── 1. PRUEBAS UNITARIAS — Modelos ──────────────────────────────────────
  group('Pruebas unitarias — Modelos', () {
    test('SerieDetalle: toJson y fromJson son simétricos', () {
      const serie = SerieDetalle(reps: 10, peso: 80.0);
      final restored = SerieDetalle.fromJson(serie.toJson());
      expect(restored.reps, equals(10));
      expect(restored.peso, equals(80.0));
    });

    test('SerieDetalle: sin peso serializa como null', () {
      const serie = SerieDetalle(reps: 15);
      expect(serie.toJson()['peso'], isNull);
    });

    test('Ejercicio.nombrePara: devuelve el idioma correcto', () {
      final ej = Ejercicio(
        id: 1,
        nombreEs: 'Sentadilla',
        nombreEn: 'Squat',
        nombreFr: 'Squat',
        esCardio: false,
        esPersonalizado: false,
      );
      expect(ej.nombrePara('es'), equals('Sentadilla'));
      expect(ej.nombrePara('en'), equals('Squat'));
      expect(ej.nombrePara('de'), equals('Sentadilla')); // fallback español
    });

    test('SesionEjercicio.fromJson: deserializa series correctamente', () {
      final json = {
        'id': 1,
        'id_sesion': 1,
        'id_ejercicio': 1,
        'ejercicio': {
          'id': 1,
          'nombre_es': 'Press banca',
          'nombre_en': 'Bench press',
          'nombre_fr': 'Développé couché',
          'es_cardio': 0,
          'es_personalizado': 0,
          'id_usuario': null,
          'grupo_muscular': 'Pecho',
        },
        'series_realizadas':
            '[{"reps":10,"peso":80.0,"dropset":false,"dropsets":[]}]',
      };
      final se = SesionEjercicio.fromJson(json);
      expect(se.seriesRealizadas.length, equals(1));
      expect(se.seriesRealizadas.first.reps, equals(10));
      expect(se.seriesRealizadas.first.peso, equals(80.0));
    });

    test('SesionEjercicio.fromJson: series null devuelve lista vacía', () {
      final json = {
        'id': 2,
        'id_sesion': 1,
        'id_ejercicio': 1,
        'ejercicio': {
          'id': 1,
          'nombre_es': 'Press banca',
          'nombre_en': 'Bench press',
          'nombre_fr': 'Développé couché',
          'es_cardio': 0,
          'es_personalizado': 0,
          'id_usuario': null,
          'grupo_muscular': 'Pecho',
        },
        'series_realizadas': null,
      };
      final se = SesionEjercicio.fromJson(json);
      expect(se.seriesRealizadas, isEmpty);
    });
  });

  // ── 2. PRUEBAS DE INTEGRACIÓN — BLoC ────────────────────────────────────
  group('Pruebas de integración — SesionBloc', () {
    test('Cargar historial: emite SesionLoaded con los datos', () async {
      repo.historial = [_sesionFake(id: 1), _sesionFake(id: 2)];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<SesionLoaded>());
      expect((bloc.state as SesionLoaded).historial.length, equals(2));
    });

    test('Seleccionar sesión: establece sesionActiva', () async {
      repo.historial = [_sesionFake()];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionSeleccionarEvent(_sesionFake()));
      await Future.delayed(const Duration(milliseconds: 100));

      expect((bloc.state as SesionLoaded).sesionActiva?.id, equals(1));
    });

    test('Eliminar sesión: la quita del historial', () async {
      repo.historial = [_sesionFake(id: 1)];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionEliminarEvent(id: 1));
      await Future.delayed(const Duration(milliseconds: 100));

      expect((bloc.state as SesionLoaded).historial, isEmpty);
    });

    test('Añadir ejercicio: actualiza la sesión activa', () async {
      final sesionInicial = _sesionFake();
      final sesionActualizada = _sesionFake(ejercicios: [_ejercicioFake()]);
      repo.historial = [sesionInicial];
      repo.sesionActualizada = sesionActualizada;

      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionSeleccionarEvent(sesionInicial));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionAnadirEjercicioEvent(
        idEjercicio: 5,
        seriesRealizadas: [const SerieDetalle(reps: 10, peso: 80.0)],
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        (bloc.state as SesionLoaded).sesionActiva?.ejercicios.length,
        equals(1),
      );
    });
  });

  // ── 3. PRUEBAS DE ACEPTACIÓN — Flujo completo ────────────────────────────
  group('Pruebas de aceptación — Flujo completo', () {
    test('Crear sesión nueva y navegar a ella', () async {
      repo.historial = [];
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();

      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).historial, isEmpty);

      bloc.add(SesionCrearEvent(
        idRutina: 1,
        idUsuario: 1,
        ejerciciosPlantilla: [],
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect((bloc.state as SesionLoaded).sesionActiva?.id, equals(1));
      expect((bloc.state as SesionLoaded).historial.length, equals(1));
    });

    test('Mismo día: carga sesión existente sin duplicar', () async {
      final sesionExistente = _sesionFake();
      repo.historial = [sesionExistente];
      repo.sesionDelDia = sesionExistente;

      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionCrearEvent(
        idRutina: 1,
        idUsuario: 1,
        ejerciciosPlantilla: [],
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      // Historial sigue con 1 sesión — no se duplicó
      expect((bloc.state as SesionLoaded).historial.length, equals(1));
      expect((bloc.state as SesionLoaded).sesionActiva?.id, equals(1));
    });

    test('Flujo completo: crear → añadir ejercicio → eliminar', () async {
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();
      repo.historial = [];

      // Crear
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).sesionActiva, isNotNull);

      // Añadir ejercicio
      repo.sesionActualizada = _sesionFake(ejercicios: [_ejercicioFake()]);
      bloc.add(SesionAnadirEjercicioEvent(
        idEjercicio: 5,
        seriesRealizadas: [const SerieDetalle(reps: 10, peso: 80.0)],
      ));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        (bloc.state as SesionLoaded).sesionActiva?.ejercicios.length,
        equals(1),
      );

      // Eliminar sesión
      bloc.add(SesionEliminarEvent(id: 1));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).historial, isEmpty);
    });
  });

  // ── 4. PRUEBAS DE REGRESIÓN ───────────────────────────────────────────────
  group('Pruebas de regresión', () {
    test('Eliminar ejercicio no borra la sesión entera', () async {
      final sesionConEjercicio =
          _sesionFake(ejercicios: [_ejercicioFake()]);
      final sesionSinEjercicio = _sesionFake(ejercicios: []);
      repo.historial = [sesionConEjercicio];
      repo.sesionActualizada = sesionSinEjercicio;

      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionSeleccionarEvent(sesionConEjercicio));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionEliminarEjercicioEvent(id: 10));
      await Future.delayed(const Duration(milliseconds: 100));

      // La sesión sigue existiendo pero sin ejercicios
      expect((bloc.state as SesionLoaded).sesionActiva, isNotNull);
      expect(
          (bloc.state as SesionLoaded).sesionActiva?.ejercicios, isEmpty);
    });

    test('Modificar ejercicio actualiza las series', () async {
      final ejercicioOriginal = _ejercicioFake();
      final ejercicioModificado = SesionEjercicio(
        id: 10,
        idSesion: 1,
        idEjercicio: 5,
        ejercicio: ejercicioOriginal.ejercicio,
        seriesRealizadas: [const SerieDetalle(reps: 12, peso: 90.0)],
      );
      final sesionModificada =
          _sesionFake(ejercicios: [ejercicioModificado]);

      repo.historial = [_sesionFake(ejercicios: [ejercicioOriginal])];
      repo.sesionActualizada = sesionModificada;

      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionSeleccionarEvent(
          _sesionFake(ejercicios: [ejercicioOriginal])));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(SesionModificarEjercicioEvent(
        id: 10,
        seriesRealizadas: [const SerieDetalle(reps: 12, peso: 90.0)],
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        (bloc.state as SesionLoaded)
            .sesionActiva
            ?.ejercicios
            .first
            .seriesRealizadas
            .first
            .peso,
        equals(90.0),
      );
    });
  });
}