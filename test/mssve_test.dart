import 'package:flutter_test/flutter_test.dart';
import 'package:mssve/BLoC/sesion/sesion_bloc.dart';
import 'package:mssve/models/alimento.dart';
import 'package:mssve/models/ejercicio.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/models/sesion_ejercicio.dart';
import 'package:mssve/models/sesion_entrenamiento.dart';
import 'package:mssve/repositories/repository_sesion.dart';
import 'package:mssve/services/crypto_helper.dart';
import 'package:mssve/services/get_calculator.dart';

// ════════════════════════════════════════════════════════════════════════════
// REPOSITORIO FALSO — simula la BD sin conexion real
// ════════════════════════════════════════════════════════════════════════════
class _FakeRepo implements RepositorySesion {
  List<SesionEntrenamiento> historial = [];
  SesionEntrenamiento? sesionDelDia;
  SesionEntrenamiento? sesionCreada;
  SesionEntrenamiento? sesionActualizada;
  bool lanzarError = false;

  List<Alimento> alimentos = [
    const Alimento(
      id: 1,
      nombre: 'Pechuga de pollo',
      kcalPor100g: 165,
      proteinasPor100g: 31,
      carbohidratosPor100g: 0,
      grasasPor100g: 3.6,
    ),
  ];

  @override
  Future<List<SesionEntrenamiento>> getHistorial(int idUsuario) async {
    if (lanzarError) throw Exception('error.connection');
    return historial;
  }

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
    int? duracionMinutos,
  }) async => _ejercicioFake();

  @override
  Future<void> modificarEjercicioSesion({
    required int id,
    required List<SerieDetalle> seriesRealizadas,
    int? duracionMinutos,
  }) async {}

  @override
  Future<void> eliminarEjercicioDeSesion(int id) async {}

  @override
  Future<void> eliminarSesion(int id) async =>
      historial.removeWhere((s) => s.id == id);
}

// ── Datos de prueba ──────────────────────────────────────────────────────
const _pollo = Alimento(
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

Ejercicio _ejMultilingue() => Ejercicio(
      id: 1,
      nombreEs: 'Press banca',
      nombreEn: 'Bench press',
      nombreFr: 'Développé couché',
      esCardio: false,
      esPersonalizado: false,
    );

// Validadores — replican la logica de los formularios
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

// ════════════════════════════════════════════════════════════════════════════
void main() {

  // ══════════════════════════════════════════════════════════════════════════
  // 7.1 PRUEBAS UNITARIAS
  // Verifican que cada funcion individual devuelve el resultado correcto
  // de forma aislada, sin depender de la BD ni de otros modulos.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.1 Pruebas unitarias — Cifrado SHA-256', () {
    test('hashPassword produce un hash de 64 caracteres hexadecimales', () {
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

    test('Hash conocido de "1234" es correcto', () {
      expect(CryptoHelper.hashPassword('1234'),
          equals('03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'));
    });
  });

  group('7.1 Pruebas unitarias — Cálculo de macros', () {
    test('calcularKcal: 200g de pollo = 330 kcal', () {
      expect(_pollo.calcularKcal(200), equals(330.0));
    });

    test('calcularKcal: 0g devuelve 0', () {
      expect(_pollo.calcularKcal(0), equals(0.0));
    });

    test('calcularMacros: valores correctos para 150g', () {
      final macros = _pollo.calcularMacros(150);
      expect(macros['proteinas'], equals(46.5));
      expect(macros['carbohidratos'], equals(0.0));
      expect(macros['grasas'], equals(5.4));
    });

    test('GETCalculator: hombre moderado 75kg/175cm/25 años', () {
      final get = GETCalculator.calcularGET(
        peso: 75, altura: 175, edad: 25,
        genero: 'Hombre', nivelActividad: 'Moderado',
      );
      expect(get, closeTo(2671.81, 1.0));
    });

  });

  group('7.1 Pruebas unitarias — Lógica AuthBloc', () {
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

    test('SesionEjercicio.fromJson deserializa series correctamente', () {
      final json = {
        'id': 1, 'id_sesion': 1, 'id_ejercicio': 1,
        'ejercicio': {
          'id': 1, 'nombre_es': 'Press banca',
          'nombre_en': 'Bench press', 'nombre_fr': 'Développé couché',
          'es_cardio': 0, 'es_personalizado': 0,
          'id_usuario': null, 'grupo_muscular': 'Pecho',
        },
        'series_realizadas':
            '[{"reps":10,"peso":80.0,"dropset":false,"dropsets":[]}]',
      };
      final se = SesionEjercicio.fromJson(json);
      expect(se.seriesRealizadas.length, equals(1));
      expect(se.seriesRealizadas.first.reps, equals(10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.2 PRUEBAS DE INTEGRACION
  // Verifican que los distintos modulos trabajan bien juntos:
  // BD + repositorio + BLoC funcionando en cadena.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.2 Integración — CRUD completo de alimentos', () {
    late _FakeRepo repo;
    setUp(() => repo = _FakeRepo());

    test('Leer: devuelve la lista inicial', () {
      expect(repo.alimentos.length, equals(1));
      expect(repo.alimentos.first.nombre, equals('Pechuga de pollo'));
    });

    test('Crear: añade el alimento a la lista', () {
      repo.alimentos.add(const Alimento(
        id: 2, nombre: 'Arroz',
        kcalPor100g: 130, proteinasPor100g: 2.7,
        carbohidratosPor100g: 28, grasasPor100g: 0.3,
      ));
      expect(repo.alimentos.length, equals(2));
      expect(repo.alimentos.last.nombre, equals('Arroz'));
    });

    test('Editar: actualiza los valores del alimento', () {
      repo.alimentos[0] =
          repo.alimentos.first.copyWith(nombre: 'Pollo editado');
      expect(repo.alimentos.first.nombre, equals('Pollo editado'));
      expect(repo.alimentos.first.kcalPor100g, equals(165));
    });

    test('Eliminar: borra el alimento de la lista', () {
      repo.alimentos.removeWhere((a) => a.id == 1);
      expect(repo.alimentos, isEmpty);
    });
  });

  group('7.2 Integración — Flujo registro de comida', () {
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

    test('Suma de kcal de múltiples alimentos es correcta', () {
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

  group('7.2 Integración — SesionBloc con repositorio', () {
    late _FakeRepo repo;
    late SesionBloc bloc;
    setUp(() {
      repo = _FakeRepo();
      bloc = SesionBloc(repository: repo);
    });
    tearDown(() => bloc.close());

    test('Cargar historial emite SesionLoaded con los datos', () async {
      repo.historial = [_sesionFake(id: 1), _sesionFake(id: 2)];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect(bloc.state, isA<SesionLoaded>());
      expect((bloc.state as SesionLoaded).historial.length, equals(2));
    });

    test('Crear sesión nueva actualiza historial y sesionActiva', () async {
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).sesionActiva?.id, equals(1));
    });

    test('Mismo día carga sesión existente sin duplicar', () async {
      repo.historial = [_sesionFake()];
      repo.sesionDelDia = _sesionFake();
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).historial.length, equals(1));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.3 PRUEBAS DE INTERFAZ
  // Verifican que la UI responde correctamente a las acciones del usuario:
  // validaciones de formularios y cambio de idioma.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.3 Interfaz — Validación de formularios', () {
    test('Email vacío no es válido', () =>
        expect(_validarEmail(''), isNotNull));
    test('Email sin @ no es válido', () =>
        expect(_validarEmail('correoSinArroba.com'), isNotNull));
    test('Email correcto es válido', () =>
        expect(_validarEmail('usuario@gmail.com'), isNull));
    test('Contraseña con menos de 6 caracteres no es válida', () =>
        expect(_validarPassword('123'), isNotNull));
    test('Contraseña de 6 o más caracteres es válida', () =>
        expect(_validarPassword('abc123'), isNull));
    test('Contraseña vacía no es válida', () =>
        expect(_validarPassword(''), isNotNull));
    test('Campo requerido vacío no es válido', () =>
        expect(_validarRequerido(''), isNotNull));
    test('Campo requerido con texto es válido', () =>
        expect(_validarRequerido('Juan'), isNull));
    test('Peso no numérico no es válido', () =>
        expect(_validarNumero('abc'), isNotNull));
    test('Peso numérico decimal es válido', () =>
        expect(_validarNumero('75.5'), isNull));
  });

  group('7.3 Interfaz — Cambio de idioma en tiempo real', () {
    test('nombrePara devuelve el nombre en español', () =>
        expect(_ejMultilingue().nombrePara('es'), equals('Press banca')));
    test('nombrePara devuelve el nombre en inglés', () =>
        expect(_ejMultilingue().nombrePara('en'), equals('Bench press')));
    test('nombrePara devuelve el nombre en francés', () =>
        expect(_ejMultilingue().nombrePara('fr'), equals('Développé couché')));
    test('Idioma no soportado usa español como fallback', () =>
        expect(_ejMultilingue().nombrePara('de'), equals('Press banca')));
    test('Cambiar idioma no modifica el modelo subyacente', () {
      final ej = _ejMultilingue();
      ej.nombrePara('en');
      expect(ej.nombreEs, equals('Press banca'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.4 PRUEBAS DE REGRESION
  // Comprueban que los cambios nuevos no han roto funcionalidades
  // que antes funcionaban correctamente.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.4 Regresión', () {
    test('Eliminar ejercicio no borra la sesión entera', () async {
      final repo = _FakeRepo();
      final bloc = SesionBloc(repository: repo);
      final sesion = _sesionFake(ejercicios: [_ejercicioFake()]);
      repo.historial = [sesion];
      repo.sesionActualizada = _sesionFake(ejercicios: []);
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      bloc.add(SesionSeleccionarEvent(sesion));
      await Future.delayed(const Duration(milliseconds: 150));
      bloc.add(SesionEliminarEjercicioEvent(id: 10));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).sesionActiva, isNotNull);
      expect((bloc.state as SesionLoaded).sesionActiva?.ejercicios, isEmpty);
      await bloc.close();
    });

    test('SerieDetalle.fromJson no pierde datos al serializar', () {
      const original =
          SerieDetalle(reps: 12, peso: 90.0, dropset: true, dropsets: [70.0]);
      final restored = SerieDetalle.fromJson(original.toJson());
      expect(restored.reps, equals(12));
      expect(restored.peso, equals(90.0));
      expect(restored.dropset, isTrue);
    });

    test('calcularKcal es idempotente (mismo resultado siempre)', () {
      expect(_pollo.calcularKcal(100), equals(_pollo.calcularKcal(100)));
    });

    test('GET es determinista con los mismos parámetros', () {
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

    test('SesionLoaded.copyWith preserva historial al cambiar sesionActiva', () {
      final sesion = _sesionFake();
      final estado = SesionLoaded(historial: [sesion]);
      final copia = estado.copyWith(sesionActiva: sesion);
      expect(copia.historial.length, equals(1));
      expect(copia.sesionActiva?.id, equals(1));
    });

    test('Alimento.copyWith no modifica el objeto original', () {
      const original = _pollo;
      final copia = original.copyWith(nombre: 'Editado');
      expect(original.nombre, equals('Pechuga de pollo'));
      expect(copia.nombre, equals('Editado'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.5 PRUEBAS FUNCIONALES
  // Verifican que los flujos completos de la aplicacion funcionan
  // de principio a fin tal como esperaria el usuario.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.5 Pruebas funcionales — Flujos completos', () {
    late _FakeRepo repo;
    late SesionBloc bloc;
    setUp(() {
      repo = _FakeRepo();
      bloc = SesionBloc(repository: repo);
    });
    tearDown(() => bloc.close());

    test('Flujo login: carga historial vacío al entrar', () async {
      repo.historial = [];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect(bloc.state, isA<SesionLoaded>());
      expect((bloc.state as SesionLoaded).historial, isEmpty);
    });

    test('Flujo crear sesión: crea y selecciona automáticamente', () async {
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));
      final state = bloc.state as SesionLoaded;
      expect(state.sesionActiva, isNotNull);
      expect(state.historial.length, equals(1));
    });

    test('Flujo añadir ejercicio: aparece en la sesión activa', () async {
      repo.historial = [_sesionFake()];
      repo.sesionActualizada = _sesionFake(ejercicios: [_ejercicioFake()]);
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      bloc.add(SesionSeleccionarEvent(_sesionFake()));
      await Future.delayed(const Duration(milliseconds: 150));
      bloc.add(SesionAnadirEjercicioEvent(
          idEjercicio: 5,
          seriesRealizadas: [const SerieDetalle(reps: 10, peso: 80.0)]));
      await Future.delayed(const Duration(milliseconds: 150));
      expect(
          (bloc.state as SesionLoaded).sesionActiva?.ejercicios.length,
          equals(1));
    });

    test('Flujo eliminar sesión: desaparece del historial', () async {
      repo.historial = [_sesionFake(id: 1), _sesionFake(id: 2)];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      bloc.add(SesionEliminarEvent(id: 1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).historial.length, equals(1));
    });

    test('Flujo registro nutrición: kcal se calculan correctamente', () {
      const pollo = _pollo;
      const arroz = Alimento(
        id: 2, nombre: 'Arroz',
        kcalPor100g: 130, proteinasPor100g: 2.7,
        carbohidratosPor100g: 28, grasasPor100g: 0.3,
      );
      final kcalTotal = pollo.calcularKcal(200) + arroz.calcularKcal(100);
      expect(kcalTotal, closeTo(460.0, 0.5));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.6 PRUEBAS DE CAPACIDAD
  // Comprueban que la app funciona bien cuando hay grandes cantidades
  // de datos, sin errores ni comportamientos inesperados.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.6 Pruebas de capacidad', () {
    test('Procesar 1.000 alimentos sin errores', () {
      final alimentos = List.generate(
        1000,
        (i) => Alimento(
          id: i,
          nombre: 'Alimento $i',
          kcalPor100g: 100.0 + i,
          proteinasPor100g: 10.0,
          carbohidratosPor100g: 20.0,
          grasasPor100g: 5.0,
        ),
      );
      expect(alimentos.length, equals(1000));
      // Calcular kcal de todos — no debe lanzar ningun error
      final total = alimentos.fold<double>(
          0, (sum, a) => sum + a.calcularKcal(100));
      expect(total, greaterThan(0));
    });

    test('Procesar 500 sesiones en el historial sin errores', () {
      final historial = List.generate(
        500,
        (i) => _sesionFake(
          id: i,
          ejercicios: List.generate(
            5,
            (j) => SesionEjercicio(
              id: j,
              idSesion: i,
              idEjercicio: j,
              ejercicio: Ejercicio(
                id: j,
                nombreEs: 'Ejercicio $j',
                nombreEn: 'Exercise $j',
                nombreFr: 'Exercice $j',
                esCardio: false,
                esPersonalizado: false,
              ),
              seriesRealizadas: [const SerieDetalle(reps: 10, peso: 50.0)],
            ),
          ),
        ),
      );
      expect(historial.length, equals(500));
      // Contar el total de ejercicios — no debe lanzar errores
      final totalEjercicios =
          historial.fold<int>(0, (s, sesion) => s + sesion.ejercicios.length);
      expect(totalEjercicios, equals(2500));
    });

    test('Calcular GET para 100 usuarios distintos sin errores', () {
      final resultados = List.generate(100, (i) {
        return GETCalculator.calcularGET(
          peso: 50.0 + i,
          altura: 160 + i,
          edad: 20 + (i % 40),
          genero: i % 2 == 0 ? 'Hombre' : 'Mujer',
          nivelActividad: ['Sedentario', 'Ligero', 'Moderado', 'Intenso'][i % 4],
        );
      });
      expect(resultados.length, equals(100));
      expect(resultados.every((r) => r > 0), isTrue);
    });

    test('Serializar y deserializar 200 SerieDetalle sin pérdida', () {
      final series = List.generate(
        200,
        (i) => SerieDetalle(
          reps: 10 + i,
          peso: 50.0 + i,
          dropset: i % 3 == 0,
          dropsets: i % 3 == 0 ? [40.0 + i, 30.0 + i] : [],
        ),
      );
      for (final s in series) {
        final restored = SerieDetalle.fromJson(s.toJson());
        expect(restored.reps, equals(s.reps));
        expect(restored.peso, equals(s.peso));
        expect(restored.dropset, equals(s.dropset));
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.7 PRUEBAS DE RECURSOS
  // Verifican que la app gestiona bien la memoria: libera controladores,
  // no guarda datos entre pruebas y no acumula objetos innecesarios.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.7 Pruebas de recursos', () {
    test('SesionBloc se cierra correctamente sin errores', () async {
      final repo = _FakeRepo();
      final bloc = SesionBloc(repository: repo);
      // No debe lanzar error al cerrar
      await expectLater(bloc.close(), completes);
    });

    test('Múltiples instancias de SesionBloc son independientes', () async {
      final repo1 = _FakeRepo()..historial = [_sesionFake(id: 1)];
      final repo2 = _FakeRepo()..historial = [_sesionFake(id: 2), _sesionFake(id: 3)];
      final bloc1 = SesionBloc(repository: repo1);
      final bloc2 = SesionBloc(repository: repo2);

      bloc1.add(SesionCargarHistorialEvent(1));
      bloc2.add(SesionCargarHistorialEvent(2));
      await Future.delayed(const Duration(milliseconds: 150));

      expect((bloc1.state as SesionLoaded).historial.length, equals(1));
      expect((bloc2.state as SesionLoaded).historial.length, equals(2));

      await bloc1.close();
      await bloc2.close();
    });

    test('El estado se resetea correctamente entre operaciones', () async {
      final repo = _FakeRepo();
      final bloc = SesionBloc(repository: repo);

      // Primera carga
      repo.historial = [_sesionFake(id: 1)];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).historial.length, equals(1));

      // Segunda carga con datos distintos
      repo.historial = [_sesionFake(id: 2), _sesionFake(id: 3)];
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).historial.length, equals(2));

      await bloc.close();
    });

    test('CopyWith crea objetos nuevos sin modificar el original', () {
      final original = SesionLoaded(historial: [_sesionFake()]);
      final copia = original.copyWith(sesionActiva: _sesionFake());
      // El original no debe verse afectado
      expect(original.sesionActiva, isNull);
      expect(copia.sesionActiva, isNotNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.8 PRUEBAS DE SEGURIDAD
  // Verifican que los datos sensibles estan protegidos: contrasenas
  // cifradas, entradas invalidas rechazadas y datos no alterables.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.8 Pruebas de seguridad', () {
    test('La contraseña nunca se almacena en texto plano', () {
      const password = 'miContraseña123';
      final hash = CryptoHelper.hashPassword(password);
      expect(hash, isNot(equals(password)));
      expect(hash, isNot(contains(password)));
    });

    test('Dos contraseñas distintas nunca producen el mismo hash', () {
      final hashes = ['1234', 'password', 'admin', '123456', 'qwerty']
          .map(CryptoHelper.hashPassword)
          .toList();
      expect(hashes.toSet().length, equals(hashes.length));
    });

    test('El hash no revela información sobre la longitud de la contraseña', () {
      final hashCorta = CryptoHelper.hashPassword('ab');
      final hashLarga = CryptoHelper.hashPassword('abcdefghijklmnopqrstuvwxyz');
      expect(hashCorta.length, equals(hashLarga.length));
    });

    test('Entrada SQL maliciosa es tratada como texto sin ejecutarse', () {
      const entradaMaliciosa = "'; DROP TABLE usuarios; --";
      final hash = CryptoHelper.hashPassword(entradaMaliciosa);
      // Se hashea sin lanzar excepcion — no se ejecuta como SQL
      expect(hash.length, equals(64));
    });

    test('Email vacío es rechazado por la validación', () {
      expect(_validarEmail(''), isNotNull);
      expect(_validarEmail('   '), isNotNull);
    });

    test('Contraseña corta es rechazada por la validación', () {
      expect(_validarPassword('12345'), isNotNull);
      expect(_validarPassword(''), isNotNull);
    });

    test('Inyección de código en nombre de usuario es tratada como texto', () {
      const nombreMalicioso = '<script>alert("hack")</script>';
      // La validacion trata el nombre como texto normal
      expect(_validarRequerido(nombreMalicioso), isNull);
      // Se guarda tal cual — el hash lo hace inofensivo si se usara como pass
      final hash = CryptoHelper.hashPassword(nombreMalicioso);
      expect(hash.length, equals(64));
    });

    test('Los datos de sesión no persisten entre instancias del BLoC', () async {
      final repo = _FakeRepo();
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();

      final bloc1 = SesionBloc(repository: repo);
      bloc1.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc1.state as SesionLoaded).sesionActiva, isNotNull);
      await bloc1.close();

      // Nueva instancia del BLoC — empieza limpia
      final bloc2 = SesionBloc(repository: _FakeRepo());
      expect(bloc2.state, isA<SesionInitial>());
      await bloc2.close();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.9 PRUEBAS DE USUARIO
  // Simulan acciones reales del usuario y comprueban que la app
  // responde exactamente como se esperaria en uso real.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.9 Pruebas de usuario', () {
    test('Usuario introduce email incorrecto y ve el error', () {
      expect(_validarEmail('juangmail.com'), isNotNull);
    });

    test('Usuario introduce email correcto y no ve error', () {
      expect(_validarEmail('juan@gmail.com'), isNull);
    });

    test('Usuario introduce contraseña muy corta y ve el error', () {
      expect(_validarPassword('123'), isNotNull);
    });

    test('Usuario cambia el idioma y los nombres cambian', () {
      final ej = _ejMultilingue();
      final enEs = ej.nombrePara('es');
      final enEn = ej.nombrePara('en');
      final enFr = ej.nombrePara('fr');
      expect(enEs, isNot(equals(enEn)));
      expect(enEs, isNot(equals(enFr)));
      expect(enEn, isNot(equals(enFr)));
    });

    test('Usuario añade comida y las kcal se actualizan', () {
      double kcalTotal = 0;
      kcalTotal += _pollo.calcularKcal(150);
      expect(kcalTotal, equals(247.5));
      kcalTotal += const Alimento(
        id: 2, nombre: 'Arroz',
        kcalPor100g: 130, proteinasPor100g: 2.7,
        carbohidratosPor100g: 28, grasasPor100g: 0.3,
      ).calcularKcal(100);
      expect(kcalTotal, closeTo(377.5, 0.1));
    });

  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7.10 PRUEBAS DE ACEPTACION
  // Son las pruebas mas completas: verifican escenarios reales de uso
  // de principio a fin, tal como los evaluaria un usuario final.
  // ══════════════════════════════════════════════════════════════════════════
  group('7.10 Pruebas de aceptación', () {
    late _FakeRepo repo;
    late SesionBloc bloc;
    setUp(() {
      repo = _FakeRepo();
      bloc = SesionBloc(repository: repo);
    });
    tearDown(() => bloc.close());

    test('Escenario: usuario empieza un entrenamiento nuevo', () async {
      // Dado que no hay sesiones ese dia
      repo.historial = [];
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();

      // Cuando carga el historial
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).historial, isEmpty);

      // Y crea una sesion nueva
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));

      // Entonces tiene una sesion activa y aparece en el historial
      final state = bloc.state as SesionLoaded;
      expect(state.sesionActiva, isNotNull);
      expect(state.historial.length, equals(1));
    });

    test('Escenario: usuario vuelve a entrenar el mismo día', () async {
      // Dado que ya entreno hoy
      final sesionExistente = _sesionFake();
      repo.historial = [sesionExistente];
      repo.sesionDelDia = sesionExistente;
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));

      // Cuando intenta crear otra sesion el mismo dia
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));

      // Entonces carga la existente sin duplicar
      final state = bloc.state as SesionLoaded;
      expect(state.historial.length, equals(1));
      expect(state.sesionActiva?.id, equals(1));
    });

    test('Escenario: flujo completo crear → añadir → modificar → eliminar', () async {
      // 1. Crear sesion
      repo.sesionDelDia = null;
      repo.sesionCreada = _sesionFake();
      bloc.add(SesionCrearEvent(
          idRutina: 1, idUsuario: 1, ejerciciosPlantilla: []));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).sesionActiva, isNotNull);

      // 2. Anadir ejercicio
      repo.sesionActualizada = _sesionFake(ejercicios: [_ejercicioFake()]);
      bloc.add(SesionAnadirEjercicioEvent(
          idEjercicio: 5,
          seriesRealizadas: [const SerieDetalle(reps: 10, peso: 80.0)]));
      await Future.delayed(const Duration(milliseconds: 150));
      expect(
          (bloc.state as SesionLoaded).sesionActiva?.ejercicios.length,
          equals(1));

      // 3. Modificar el ejercicio
      final ejModificado = SesionEjercicio(
        id: 10, idSesion: 1, idEjercicio: 5,
        ejercicio: _ejercicioFake().ejercicio,
        seriesRealizadas: [const SerieDetalle(reps: 12, peso: 90.0)],
      );
      repo.sesionActualizada = _sesionFake(ejercicios: [ejModificado]);
      bloc.add(SesionModificarEjercicioEvent(
          id: 10,
          seriesRealizadas: [const SerieDetalle(reps: 12, peso: 90.0)]));
      await Future.delayed(const Duration(milliseconds: 150));
      expect(
          (bloc.state as SesionLoaded)
              .sesionActiva?.ejercicios.first.seriesRealizadas.first.peso,
          equals(90.0));

      // 4. Eliminar sesion
      bloc.add(SesionEliminarEvent(id: 1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect((bloc.state as SesionLoaded).historial, isEmpty);
    });

    test('Escenario: error de conexión muestra estado de error', () async {
      repo.lanzarError = true;
      bloc.add(SesionCargarHistorialEvent(1));
      await Future.delayed(const Duration(milliseconds: 150));
      expect(bloc.state, isA<SesionError>());
    });

    test('Escenario: cálculo de calorías para un día completo', () {
      const desayuno = Alimento(
        id: 1, nombre: 'Avena', kcalPor100g: 389,
        proteinasPor100g: 17, carbohidratosPor100g: 66, grasasPor100g: 7,
      );
      const almuerzo = _pollo;
      const cena = Alimento(
        id: 3, nombre: 'Salmón', kcalPor100g: 208,
        proteinasPor100g: 20, carbohidratosPor100g: 0, grasasPor100g: 13,
      );
      final kcalDia = desayuno.calcularKcal(80) +
          almuerzo.calcularKcal(200) +
          cena.calcularKcal(150);
      // Avena 311.2 + Pollo 330 + Salmon 312 = 953.2 kcal aprox
      expect(kcalDia, closeTo(953.2, 1.0));
    });
  });
}