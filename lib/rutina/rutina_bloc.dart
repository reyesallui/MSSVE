import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/ejercicio.dart';
import '../../models/rutina.dart';
import '../../repositories/repository_rutina.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
// Con `part` le digo a Dart que estos dos archivos forman parte de este mismo archivo
// Los eventos y estados están separados en sus propios archivos pero pertenecen al mismo bloque
part 'rutina_event.dart';
part 'rutina_state.dart';



class RutinaBloc extends Bloc<RutinaEvent, RutinaState> {
  final RepositoryRutina _repository; // El repositorio es quien habla con la base de datos

  // Constructor: recibo el repositorio desde fuera (inyección de dependencias)
  // y registro cada evento con su función manejadora usando on<Evento>(función)
  RutinaBloc({required RepositoryRutina repository})
      : _repository = repository,
        super(const RutinaInitial()) { // El estado inicial es RutinaInitial
    on<RutinaLoadEvent>(_onLoad);
    on<RutinaSeleccionarEvent>(_onSeleccionar);
    on<RutinaCrearEvent>(_onCrear);
    on<RutinaModificarEvent>(_onModificar);
    on<RutinaEliminarEvent>(_onEliminar);
    on<RutinaDuplicarEvent>(_onDuplicar);
    on<RutinaBuscarEjerciciosEvent>(_onBuscarEjercicios);
    on<RutinaCrearEjercicioEvent>(_onCrearEjercicio);
    on<RutinaAnadirEjercicioEvent>(_onAnadirEjercicio);
    on<RutinaModificarEjercicioEvent>(_onModificarEjercicio);
    on<RutinaEliminarEjercicioEvent>(_onEliminarEjercicio);
  }


  //  Cargar todas las rutinas del usuario 
  Future<void> _onLoad(
    RutinaLoadEvent event,
    Emitter<RutinaState> emit,
  ) async {
    emit(const RutinaLoading()); // Emito loading para que la UI muestre el spinner
    try {
      final rutinas = await _repository.getRutinas(event.idUsuario);
      emit(RutinaLoaded(rutinas: rutinas)); // Si va bien emito el estado con los datos
    } catch (e) {
      // Quito el prefijo "Exception: " para que el mensaje de error sea más limpio
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Seleccionar una rutina como activa 
  void _onSeleccionar(
    RutinaSeleccionarEvent event,
    Emitter<RutinaState> emit,
  ) {
    if (state is RutinaLoaded) {
      // copyWith crea una copia del estado actual cambiando solo rutinaActiva
      // así no pierdo el resto de datos que ya tenía el estado
      emit((state as RutinaLoaded).copyWith(rutinaActiva: event.rutina));
    }
  }


  //  Crear una nueva rutina 
  Future<void> _onCrear(
    RutinaCrearEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return; // Solo actúo si hay datos cargados
    try {
      await _repository.crearRutina(
        idUsuario: event.idUsuario,
        nombre: event.nombre,
        fecha: event.fecha,
        notas: event.notas,
      );
      // Después de crear, recargo la lista para que aparezca la nueva rutina
      final rutinas = await _repository.getRutinas(event.idUsuario);
      emit((state as RutinaLoaded).copyWith(rutinas: rutinas));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Editar una rutina existente 
  Future<void> _onModificar(
    RutinaModificarEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded; // Guardo referencia al estado actual para usarlo luego
    try {
      final rutinaEditada = await _repository.editarRutina(
        id: event.id,
        nombre: event.nombre,
        fecha: event.fecha,
        notas: event.notas,
      );
      // Recorro la lista y reemplazo solo la rutina que se editó, dejando las demás igual
      final rutinasActualizadas = loaded.rutinas
          .map((r) => r.id == event.id ? rutinaEditada : r)
          .toList();
      emit(loaded.copyWith(rutinas: rutinasActualizadas));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Eliminar una rutina 
  Future<void> _onEliminar(
    RutinaEliminarEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      await _repository.eliminarRutina(event.id);
      // Filtro la lista quitando la rutina eliminada con .where()
      final rutinasActualizadas =
          loaded.rutinas.where((r) => r.id != event.id).toList();
      // Compruebo si la rutina que borraron era la que estaba activa
      final eraActiva = loaded.rutinaActiva?.id == event.id;
      emit(loaded.copyWith(
        rutinas: rutinasActualizadas,
        clearRutinaActiva: eraActiva, // Si era la activa, la limpio para que no quede seleccionada
      ));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Duplicar una rutina 
  Future<void> _onDuplicar(
    RutinaDuplicarEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      final nueva = await _repository.duplicarRutina(
        rutina: event.rutina,
        nuevoNombre: event.nuevoNombre,
        nuevaFecha: event.nuevaFecha,
      );
      // En lugar de recargar toda la lista, añado la nueva rutina al final con el spread `...`
      // `[...loaded.rutinas, nueva]` es lo mismo que coger la lista actual y añadir un elemento al final
      emit(loaded.copyWith(rutinas: [...loaded.rutinas, nueva]));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Buscar ejercicios (para el buscador del bottom sheet) 
  Future<void> _onBuscarEjercicios(
    RutinaBuscarEjerciciosEvent event,
    Emitter<RutinaState> emit,
  ) async {
    // Permite buscar aunque las rutinas no estén cargadas todavía
    // necesario cuando se abre el buscador desde la pantalla de sesión
    final rutinasActuales =
        state is RutinaLoaded ? (state as RutinaLoaded).rutinas : <Rutina>[];
    try {
      final ejercicios = await _repository.buscarEjercicios(
        search: event.search,
        idUsuario: event.idUsuario,
        esCardio: event.esCardio,
      );
      if (state is RutinaLoaded) {
        emit((state as RutinaLoaded).copyWith(resultadosBusqueda: ejercicios));
      } else {
        // Si no hay rutinas cargadas emitimos un estado mínimo solo con los resultados
        emit(RutinaLoaded(rutinas: rutinasActuales, resultadosBusqueda: ejercicios));
      }
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Crear un ejercicio personalizado 
  Future<void> _onCrearEjercicio(
    RutinaCrearEjercicioEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    try {
      await _repository.crearEjercicio(
        idUsuario: event.idUsuario,
        nombre: event.nombre,
        esCardio: event.esCardio,
        grupoMuscular: event.grupoMuscular,
      );
      // Limpio los resultados de búsqueda para que el buscador quede vacío tras crear
      emit((state as RutinaLoaded).copyWith(resultadosBusqueda: []));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Añadir un ejercicio a una rutina 
  Future<void> _onAnadirEjercicio(
    RutinaAnadirEjercicioEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      await _repository.anadirEjercicioARutina(
        idRutina: event.idRutina,
        idEjercicio: event.idEjercicio,
        series: event.series,
        repeticiones: event.repeticiones,
        pesoKg: event.pesoKg,
        duracionMinutos: event.duracionMinutos,
        seriesDetalle: event.seriesDetalle,
      );
      // Recargo todas las rutinas para tener los datos actualizados
      final rutinas = await _repository.getRutinas(event.idUsuario);
      // Busco la rutina activa dentro de la lista recién cargada para actualizarla también
      // firstOrNull devuelve null si no encuentra ninguna, en lugar de lanzar un error
      final rutinaActualizada =
          rutinas.where((r) => r.id == event.idRutina).firstOrNull;
      emit(loaded.copyWith(rutinas: rutinas, rutinaActiva: rutinaActualizada));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Modificar un ejercicio de una rutina (series, reps, peso...) 
  Future<void> _onModificarEjercicio(
    RutinaModificarEjercicioEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      await _repository.modificarRutinaEjercicio(
        id: event.id,
        series: event.series,
        repeticiones: event.repeticiones,
        pesoKg: event.pesoKg,
        duracionMinutos: event.duracionMinutos,
        seriesDetalle: event.seriesDetalle,
      );
      final rutinas = await _repository.getRutinas(event.idUsuario);
      // Si había una rutina activa, busco su versión actualizada en la lista nueva
      // El operador `!` en loaded.rutinaActiva! le dice a Dart que estoy seguro de que no es null
      final rutinaActualizada = loaded.rutinaActiva != null
          ? rutinas.where((r) => r.id == loaded.rutinaActiva!.id).firstOrNull
          : null;
      emit(loaded.copyWith(rutinas: rutinas, rutinaActiva: rutinaActualizada));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  //  Eliminar un ejercicio de una rutina 
  Future<void> _onEliminarEjercicio(
    RutinaEliminarEjercicioEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      await _repository.eliminarEjercicioDeRutina(event.id);
      // Igual que en modificar: recargo las rutinas y busco la activa actualizada
      final rutinas = await _repository.getRutinas(event.idUsuario);
      final rutinaActualizada = loaded.rutinaActiva != null
          ? rutinas.where((r) => r.id == loaded.rutinaActiva!.id).firstOrNull
          : null;
      emit(loaded.copyWith(rutinas: rutinas, rutinaActiva: rutinaActualizada));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}