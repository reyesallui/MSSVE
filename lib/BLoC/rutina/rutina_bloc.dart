import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/ejercicio.dart';
import '../../../models/rutina.dart';
import '../../../repositories/repository_rutina.dart';
import 'package:mssve/models/rutina_ejercicio.dart';


part 'rutina_event.dart';
part 'rutina_state.dart';



// BloC de rutinas: CRUD completo de rutinas y ejercicios asociados
class RutinaBloc extends Bloc<RutinaEvent, RutinaState> {
  final RepositoryRutina _repository; 

  
  
  RutinaBloc({required RepositoryRutina repository})
      : _repository = repository,
        super(const RutinaInitial()) { 
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


  
  Future<void> _onLoad(
    RutinaLoadEvent event,
    Emitter<RutinaState> emit,
  ) async {
    emit(const RutinaLoading()); 
    try {
      final rutinas = await _repository.getRutinas(event.idUsuario);
      emit(RutinaLoaded(rutinas: rutinas)); 
    } catch (e) {
      
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
  void _onSeleccionar(
    RutinaSeleccionarEvent event,
    Emitter<RutinaState> emit,
  ) {
    if (state is RutinaLoaded) {
      
      
      emit((state as RutinaLoaded).copyWith(rutinaActiva: event.rutina));
    }
  }


  
  Future<void> _onCrear(
    RutinaCrearEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return; 
    try {
      await _repository.crearRutina(
        idUsuario: event.idUsuario,
        nombre: event.nombre,
        fecha: event.fecha,
        notas: event.notas,
      );
      
      final rutinas = await _repository.getRutinas(event.idUsuario);
      emit((state as RutinaLoaded).copyWith(rutinas: rutinas));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
  Future<void> _onModificar(
    RutinaModificarEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded; 
    try {
      final rutinaEditada = await _repository.editarRutina(
        id: event.id,
        nombre: event.nombre,
        fecha: event.fecha,
        notas: event.notas,
      );
      
      final rutinasActualizadas = loaded.rutinas
// Reemplaza in situ la rutina modificada sin recargar toda la lista
          .map((r) => r.id == event.id ? rutinaEditada : r)
          .toList();
      emit(loaded.copyWith(rutinas: rutinasActualizadas));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
  Future<void> _onEliminar(
    RutinaEliminarEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      await _repository.eliminarRutina(event.id);
      
      final rutinasActualizadas =
          loaded.rutinas.where((r) => r.id != event.id).toList();
      
      final eraActiva = loaded.rutinaActiva?.id == event.id;
// Si se elimina la rutina activa, la limpia del estado
      emit(loaded.copyWith(
        rutinas: rutinasActualizadas,
        clearRutinaActiva: eraActiva, 
      ));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
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
      
      
      emit(loaded.copyWith(rutinas: [...loaded.rutinas, nueva]));
// Anade la rutina duplicada al final de la lista
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
  Future<void> _onBuscarEjercicios(
    RutinaBuscarEjerciciosEvent event,
    Emitter<RutinaState> emit,
  ) async {
    
    
    final rutinasActuales =
        state is RutinaLoaded ? (state as RutinaLoaded).rutinas : <Rutina>[];
    try {
      final ejercicios = await _repository.buscarEjercicios(
        search: event.search,
        idUsuario: event.idUsuario,
        esCardio: event.esCardio,
        grupoMuscular: event.grupoMuscular,
      );
      if (state is RutinaLoaded) {
        emit((state as RutinaLoaded).copyWith(resultadosBusqueda: ejercicios));
      } else {
        
        emit(RutinaLoaded(rutinas: rutinasActuales, resultadosBusqueda: ejercicios));
      }
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
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
      
      emit((state as RutinaLoaded).copyWith(resultadosBusqueda: []));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
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
      
      final rutinas = await _repository.getRutinas(event.idUsuario);
      
      
      final rutinaActualizada =
// Refresca la rutina activa con los datos actualizados tras anadir/modificar/eliminar ejercicio
          rutinas.where((r) => r.id == event.idRutina).firstOrNull;
      emit(loaded.copyWith(rutinas: rutinas, rutinaActiva: rutinaActualizada));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
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
      
      // Refresca la rutina activa con los datos actualizados tras anadir/modificar/eliminar ejercicio loaded.rutinaActiva != null
      final rutinaActualizada =
          loaded.rutinaActiva != null
              ? rutinas.where((r) => r.id == loaded.rutinaActiva!.id).firstOrNull
              : null;
      emit(loaded.copyWith(rutinas: rutinas, rutinaActiva: rutinaActualizada));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }


  
  Future<void> _onEliminarEjercicio(
    RutinaEliminarEjercicioEvent event,
    Emitter<RutinaState> emit,
  ) async {
    if (state is! RutinaLoaded) return;
    final loaded = state as RutinaLoaded;
    try {
      await _repository.eliminarEjercicioDeRutina(event.id);
      
      final rutinas = await _repository.getRutinas(event.idUsuario);
      final rutinaActualizada =
// Refresca la rutina activa con los datos actualizados tras anadir/modificar/eliminar ejercicio loaded.rutinaActiva != null
          loaded.rutinaActiva != null
              ? rutinas.where((r) => r.id == loaded.rutinaActiva!.id).firstOrNull
              : null;
      emit(loaded.copyWith(rutinas: rutinas, rutinaActiva: rutinaActualizada));
    } catch (e) {
      emit(RutinaError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}