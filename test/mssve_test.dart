import 'package:flutter_test/flutter_test.dart';

import 'package:mssve/models/alimento.dart';
import 'package:mssve/models/ejercicio.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/models/sesion_ejercicio.dart';
import 'package:mssve/models/sesion_entrenamiento.dart';
import 'package:mssve/repositories/repository_sesion.dart';
import 'package:mssve/sesion/sesion_bloc.dart';
import 'package:mssve/services/crypto_helper.dart';
import 'package:mssve/services/get_calculator.dart';

 
// REPOSITORIO FALSO — simula la BD sin conexión real

class _FakeRepo implements RepositorySesion {
  List<SesionEntrenamiento> historial = [];
  SesionEntrenamiento? sesionDelDia;
  SesionEntrenamiento? sesionCreada;
  SesionEntrenamiento? sesionActualizada;
  List<Alimento> alimentos = [_alimentoPollo];

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
  Future<void> eliminarSesion(int id) async =>
      historial.removeWhere((s) => s.id == id);
}

//Datos de prueba compartidos 
const _alimentoPollo = Alimento(
  id: 1,
  nombre: 'Pechuga de pollo',
  kcalPor100g: 165,
  proteinasPor100g: 31,
  carbohidratosPor100g: 0,
  grasasPor100g: 3.6,
);

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

SesionEjercicio _ejercicioFake() => const SesionEjercicio(
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
      seriesRealizadas: [SerieDetalle(reps: 10, peso: 80.0)],
    );

Ejercicio _ejMultilingue() => const Ejercicio(
      id: 1,
      nombreEs: 'Press banca',
      nombreEn: 'Bench press',
      nombreFr: 'Développé couché',
      esCardio: false,
      esPersonalizado: false,
    );

//Validadores replican la lógica de los formularios 
String? _validarEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Campo requerido';
  if (!v.contains('@')) return 'Email inválido';
  return null;
}

String? _validarPassword(String? v) {
  if (v == null || v.isEmpty) return 'Campo requerido';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? _validarRequerido(String? v) {
  if (v == null || v.trim().isEmpty) return 'Campo requerido';
  return null;
}

String? _validarNumero(String? v) {
  if (v == null || double.tryParse(v) == null) return 'Valor inválido';
  return null;
}

void main() {

  //7.1 PRUEBAS UNITARIAS 
  group('7.1 Unitarias — Cifrado SHA-256', () {
    test('Hash tiene 64 caracteres hexadecimales', () {
      final hash = CryptoHelper.hashPassword('miPassword123');
      expect(hash.length, equals(64));
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
    });

    test('La misma contraseña siempre produce el mismo hash', () {
      expect(CryptoHelper.hashPassword('abc123'),
          equals(CryptoHelper.hashPassword('abc123')));
    });

    test('Contraseñas distintas producen hashes distintos', () {
      expect(CryptoHelper.hashPassword('pass1'),
          isNot(equals(CryptoHelper.hashPassword('pass2'))));
    });

    test('Hash conocido de "1234"', () {
      expect(
        CryptoHelper.hashPassword('1234'),
        equals(
            '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'),
      );
    });
  });

  group('7.1 Unitarias — Cálculo de macros', () {
    test('calcularKcal: 200g de pollo = 330 kcal', () {
      expect(_alimentoPollo.calcularKcal(200), equals(330.0));
    });

    test('calcularKcal: 0g devuelve 0', () {
      expect(_alimentoPollo.calcularKcal(0), equals(0.0));
    });

    test('calcularMacros: valores correctos para 150g', () {
      final macros = _alimentoPollo.calcularMacros(150);
      expect(macros['proteinas'], equals(46.5));
      expect(macros['carbohidratos'], equals(0.0));
      expect(macros['grasas'], equals(5.4));
    });

    test('GET hombre moderado 75kg/175cm/25 años', () {
      final get = GETCalculator.calcularGET(
        peso: 75, altura: 175, edad: 25,
        genero: 'Hombre', nivelActividad: 'Moderado',
      );
      expect(get, closeTo(2671.81, 1.0));
    });

    test('GET mujer sedentaria 60kg/165cm/30 años', () {
      final get = GETCalculator.calcularGET(
        peso: 60, altura: 165, edad: 30,
        genero: 'Mujer', nivelActividad: 'Sedentario',
      );
      expect(get, closeTo(1584.3, 1.0));
    });

    test('Nivel de actividad desconocido usa factor sedentario', () {
      final g1 = GETCalculator.calcularGET(
          peso: 70, altura: 170, edad: 25,
          genero: 'Hombre', nivelActividad: 'Desconocido');
      final g2 = GETCalculator.calcularGET(
          peso: 70, altura: 170, edad: 25,
          genero: 'Hombre', nivelActividad: 'Sedentario');
      expect(g1, equals(g2));
    });
  });

  group('7.1 Unitarias — Lógica de AuthBloc', () {
    test('Hash de contraseña vacía no es vacío', () {
      final hash = CryptoHelper.hashPassword('');
      expect(hash.isNotEmpty, isTrue);
      expect(hash.length, equals(64));
    });

    test('SerieDetalle: Equatable compara correctamente', () {
      const a = SerieDetalle(reps: 10, peso: 80.0);
      const b = SerieDetalle(reps: 10, peso: 80.0);
      const c = SerieDetalle(reps: 12, peso: 80.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('SesionEjercicio.fromJson deserializa series', () {
      final json = {
        'id': 1, 'id_sesion': 1, 'id_ejercicio': 1,
        'ejercicio': {
          'id': 1, 'nombre_es': 'Press banca', 'nombre_en': 'Bench press',
          'nombre_fr': 'Développé couché', 'es_cardio': 0,
          'es_personalizado': 0, 'id_usuario': null, 'grupo_muscular': 'Pecho',
        },
        'series_realizadas':
            '[{"reps":10,"peso":80.0,"dropset":false,"dropsets":[]}]',
      };
      final se = SesionEjercicio.fromJson(json);
      expect(se.seriesRealizadas.length, equals(1));
      expect(se.seriesRealizadas.first.reps, equals(10));
    });
  });

  //7.2 PRUEBAS DE INTEGRACIÓN 
  group('7.2 Integración — CRUD completo de alimentos', () {
    late _FakeRepo repo;
    setUp(() => repo = _FakeRepo());

    test('Leer: devuelve la lista inicial', () {
      expect(repo.alimentos.length, equals(1));
      expect(repo.alimentos.first.nombre, equals('Pechuga de pollo'));
    });

    test('Crear: añade alimento a la lista', () {
      repo.alimentos.add(const Alimento(
        id: 2, nombre: 'Arroz',
        kcalPor100g: 130, proteinasPor100g: 2.7,
        carbohidratosPor100g: 28, grasasPor100g: 0.3,
      ));
      expect(repo.alimentos.length, equals(2));
      expect(repo.alimentos.last.nombre, equals('Arroz'));
    });

    test('Editar: actualiza los valores', () {
      repo.alimentos[0] =
          repo.alimentos.first.copyWith(nombre: 'Pollo editado');
      expect(repo.alimentos.first.nombre, equals('Pollo editado'));
      expect(repo.alimentos.first.kcalPor100g, equals(165));
    });

    test('Eliminar: borra el alimento', () {
      repo.alimentos.removeWhere((a) => a.id == 1);
      expect(repo.alimentos, isEmpty);
    });
  });

  group('7.2 Integración — Flujo de registro de comida', () {
    test('Añadir alimento calcula kcal y macros correctamente', () {
      const avena = Alimento(
        id: 2, nombre: 'Avena',
        kcalPor100g: 389, proteinasPor100g: 17,
        carbohidratosPor100g: 66, grasasPor100g: 7,
      );
      expect(avena.calcularKcal(80), equals(311.2));
      final macros = avena.calcularMacros(80);
      expect(macros['proteinas'], equals(13.6));
      expect(macros['carbohidratos'], equals(52.8));
    });

    test('Suma de kcal de múltiples alimentos', () {
      const alimentos = [
        Alimento(id: 1, nombre: 'Avena', kcalPor100g: 389,
            proteinasPor100g: 17, carbohidratosPor100g: 66, grasasPor100g: 7),
        Alimento(id: 2, nombre: 'Leche', kcalPor100g: 42,
            proteinasPor100g: 3.4, carbohidratosPor100g: 5, grasasPor100g: 1),
      ];
      final gramos = [80.0, 200.0];
      final total = alimentos.asMap().entries.fold<double>(
          0, (s, e) => s + e.value.calcularKcal(gramos[e.key]));
      expect(total, closeTo(395.2, 0.1));
    });
  });

  group('7.2 Integración — Conexión BD (SesionBloc con FakeRepo)', () {
    late _FakeRepo repo;
    late SesionBloc bloc;
    setUp(() {
      repo = _FakeRepo();
      bloc = SesionBloc(repository: repo);
    });
    tearDown(() => bloc.close());

    test('Cargar historial emite SesionLoaded', () async {
      repo.historial = [_sesionFake(id: 1), _sesionFake(id: 2)];
      bloc.add(const SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(bloc.state, isA<SesionLoaded>());
      expect((bloc.state as SesionLoaded).historial.length, equals(2));
    });

    test('Crear sesión nueva actualiza historial', () async {
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();
      bloc.add(const SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).sesionActiva?.id, equals(1));
    });

    test('Añadir ejercicio actualiza la sesión activa', () async {
      repo.historial = [_sesionFake()];
      repo.sesionActualizada = _sesionFake(ejercicios: [_ejercicioFake()]);
      bloc.add(const SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(SesionSeleccionarEvent(_sesionFake()));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const SesionAnadirEjercicioEvent(
          idEjercicio: 5,
          seriesRealizadas: [SerieDetalle(reps: 10, peso: 80.0)]));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
          (bloc.state as SesionLoaded).sesionActiva?.ejercicios.length,
          equals(1));
    });

    test('Eliminar sesión la quita del historial', () async {
      repo.historial = [_sesionFake(id: 1)];
      bloc.add(const SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const SesionEliminarEvent(id: 1));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).historial, isEmpty);
    });
  });

  //7.3 PRUEBAS DE INTERFAZ
  group('7.3 Interfaz — Validación de formularios', () {
    test('Email vacío no válido', () =>
        expect(_validarEmail(''), isNotNull));
    test('Email sin @ no válido', () =>
        expect(_validarEmail('correosinArroba.com'), isNotNull));
    test('Email correcto válido', () =>
        expect(_validarEmail('usuario@gmail.com'), isNull));
    test('Contraseña < 6 caracteres no válida', () =>
        expect(_validarPassword('123'), isNotNull));
    test('Contraseña >= 6 caracteres válida', () =>
        expect(_validarPassword('abc123'), isNull));
    test('Campo requerido vacío no válido', () =>
        expect(_validarRequerido(''), isNotNull));
    test('Campo requerido con texto válido', () =>
        expect(_validarRequerido('Juan'), isNull));
    test('Peso no numérico no válido', () =>
        expect(_validarNumero('abc'), isNotNull));
    test('Peso numérico válido', () =>
        expect(_validarNumero('75.5'), isNull));
  });

  group('7.3 Interfaz — Cambio de idioma en tiempo real', () {
    test('nombrePara devuelve español', () =>
        expect(_ejMultilingue().nombrePara('es'), equals('Press banca')));
    test('nombrePara devuelve inglés', () =>
        expect(_ejMultilingue().nombrePara('en'), equals('Bench press')));
    test('nombrePara devuelve francés', () =>
        expect(_ejMultilingue().nombrePara('fr'), equals('Développé couché')));
    test('Idioma desconocido usa español como fallback', () =>
        expect(_ejMultilingue().nombrePara('de'), equals('Press banca')));
    test('Cambiar idioma no modifica el modelo subyacente', () {
      final ej = _ejMultilingue();
      ej.nombrePara('en');
      expect(ej.nombreEs, equals('Press banca'));
    });
  });

  //7.4 PRUEBAS DE REGRESIÓN
  group('7.4 Regresión', () {
    test('Eliminar ejercicio no borra la sesión', () async {
      final repo = _FakeRepo();
      final bloc = SesionBloc(repository: repo);
      final sesion = _sesionFake(ejercicios: [_ejercicioFake()]);
      repo.historial = [sesion];
      repo.sesionActualizada = _sesionFake(ejercicios: []);
      bloc.add(const SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(SesionSeleccionarEvent(sesion));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const SesionEliminarEjercicioEvent(id: 10));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).sesionActiva, isNotNull);
      expect((bloc.state as SesionLoaded).sesionActiva?.ejercicios, isEmpty);
      await bloc.close();
    });

    test('SerieDetalle.fromJson no pierde datos', () {
      const original =
          SerieDetalle(reps: 12, peso: 90.0, dropset: true, dropsets: [70.0]);
      final restored = SerieDetalle.fromJson(original.toJson());
      expect(restored.reps, equals(12));
      expect(restored.peso, equals(90.0));
      expect(restored.dropset, isTrue);
    });

    test('calcularKcal es idempotente', () {
      expect(_alimentoPollo.calcularKcal(100),
          equals(_alimentoPollo.calcularKcal(100)));
    });

    test('GET es determinista', () {
      final g1 = GETCalculator.calcularGET(
          peso: 75, altura: 175, edad: 25,
          genero: 'Hombre', nivelActividad: 'Moderado');
      final g2 = GETCalculator.calcularGET(
          peso: 75, altura: 175, edad: 25,
          genero: 'Hombre', nivelActividad: 'Moderado');
      expect(g1, equals(g2));
    });

    test('SHA-256 es determinista para la misma entrada', () {
      const pass = 'TestPassword99!';
      final hashes = List.generate(5, (_) => CryptoHelper.hashPassword(pass));
      expect(hashes.toSet().length, equals(1));
    });

    test('SesionLoaded.copyWith preserva historial', () {
      final sesion = _sesionFake();
      final estado = SesionLoaded(historial: [sesion]);
      final copia = estado.copyWith(sesionActiva: sesion);
      expect(copia.historial.length, equals(1));
      expect(copia.sesionActiva?.id, equals(1));
    });

    test('Alimento.copyWith no modifica el original', () {
      const original = _alimentoPollo;
      final copia = original.copyWith(nombre: 'Editado');
      expect(original.nombre, equals('Pechuga de pollo'));
      expect(copia.nombre, equals('Editado'));
    });

    test('Mismo día no duplica sesión', () async {
      final repo = _FakeRepo();
      final bloc = SesionBloc(repository: repo);
      final sesionExistente = _sesionFake();
      repo.historial = [sesionExistente];
      repo.sesionDelDia = sesionExistente;
      bloc.add(const SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 100));
      expect((bloc.state as SesionLoaded).historial.length, equals(1));
      await bloc.close();
    });
  });
}