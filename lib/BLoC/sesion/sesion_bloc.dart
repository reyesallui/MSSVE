import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../models/rutina_ejercicio.dart';
import '../../models/sesion_entrenamiento.dart';
import '../../repositories/repository_sesion.dart';

part 'sesion_event.dart';
part 'sesion_state.dart';



// BloC de sesiones de entrenamiento: historial, crear desde plantilla y registrar ejercicios en vivo
class SesionBloc extends Bloc<SesionEvent, SesionState> {
  final RepositorySesion _repository;

  SesionBloc({required RepositorySesion repository})
      : _repository = repository,
        super(const SesionInitial()) {
    on<SesionCargarHistorialEvent>(_onCargarHistorial);
    on<SesionCrearEvent>(_onCrear);
    on<SesionSeleccionarEvent>(_onSeleccionar);
    on<SesionModificarEjercicioEvent>(_onModificarEjercicio);
    on<SesionAnadirEjercicioEvent>(_onAnadirEjercicio);
    on<SesionEliminarEjercicioEvent>(_onEliminarEjercicio);
    on<SesionEliminarEvent>(_onEliminar);
  }

  
  Future<void> _onCargarHistorial(
    SesionCargarHistorialEvent event,
    Emitter<SesionState> emit,
  ) async {
    emit(const SesionLoading());
    try {
      final historial = await _repository.getHistorial(event.idUsuario);
      emit(SesionLoaded(historial: historial));
    } catch (e) {
      emit(SesionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  
  
  
  Future<void> _onCrear(
    SesionCrearEvent event,
    Emitter<SesionState> emit,
  ) async {
    final loaded = state is SesionLoaded
        ? state as SesionLoaded
        : SesionLoaded(historial: const []);

    final fecha =
        event.fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final sesionExistente = await _repository.getSesionDelDia(
// Si ya hay sesion para esa rutina y fecha, la reanuda en vez de crear otra
        idRutina:  event.idRutina,
        idUsuario: event.idUsuario,
        fecha:     fecha,
      );

      if (sesionExistente != null) {
        
        emit(loaded.copyWith(sesionActiva: sesionExistente));
        return;
      }

      
      final sesion = await _repository.crearSesion(
        idRutina:            event.idRutina,
        idUsuario:           event.idUsuario,
        fecha:               fecha,
        notas:               event.notas,
        ejerciciosPlantilla: event.ejerciciosPlantilla,
      );
      emit(loaded.copyWith(
        historial:    [sesion, ...loaded.historial],
        sesionActiva: sesion,
      ));
    } catch (e) {
      emit(SesionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  
  void _onSeleccionar(
    SesionSeleccionarEvent event,
    Emitter<SesionState> emit,
  ) {
    if (state is SesionLoaded) {
      emit((state as SesionLoaded).copyWith(sesionActiva: event.sesion));
    }
  }

  
  
  Future<void> _onModificarEjercicio(
    SesionModificarEjercicioEvent event,
    Emitter<SesionState> emit,
  ) async {
    if (state is! SesionLoaded) return;
    final loaded = state as SesionLoaded;
    try {
      await _repository.modificarEjercicioSesion(
        id:               event.id,
        seriesRealizadas: event.seriesRealizadas,
        duracionMinutos:  event.duracionMinutos,
      );
      final sesionActualizada =
          await _repository.getSesion(loaded.sesionActiva!.id);
      emit(loaded.copyWith(
        historial: loaded.historial
            .map((s) => s.id == sesionActualizada.id ? sesionActualizada : s)
            .toList(),
        sesionActiva: sesionActualizada,
      ));
    } catch (e) {
      emit(SesionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  
  Future<void> _onAnadirEjercicio(
    SesionAnadirEjercicioEvent event,
    Emitter<SesionState> emit,
  ) async {
    if (state is! SesionLoaded) return;
    final loaded = state as SesionLoaded;
    try {
      await _repository.anadirEjercicioASesion(
        idSesion:         loaded.sesionActiva!.id,
        idEjercicio:      event.idEjercicio,
        seriesRealizadas: event.seriesRealizadas,
        duracionMinutos:  event.duracionMinutos,
      );
      final sesionActualizada =
          await _repository.getSesion(loaded.sesionActiva!.id);
      emit(loaded.copyWith(
        historial: loaded.historial
            .map((s) => s.id == sesionActualizada.id ? sesionActualizada : s)
            .toList(),
        sesionActiva: sesionActualizada,
      ));
    } catch (e) {
      emit(SesionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  
  Future<void> _onEliminarEjercicio(
    SesionEliminarEjercicioEvent event,
    Emitter<SesionState> emit,
  ) async {
    if (state is! SesionLoaded) return;
    final loaded = state as SesionLoaded;
    try {
      await _repository.eliminarEjercicioDeSesion(event.id);
      final sesionActualizada =
          await _repository.getSesion(loaded.sesionActiva!.id);
      emit(loaded.copyWith(
        historial: loaded.historial
            .map((s) => s.id == sesionActualizada.id ? sesionActualizada : s)
            .toList(),
        sesionActiva: sesionActualizada,
      ));
    } catch (e) {
      emit(SesionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  
  
  Future<void> _onEliminar(
    SesionEliminarEvent event,
    Emitter<SesionState> emit,
  ) async {
    if (state is! SesionLoaded) return;
    final loaded = state as SesionLoaded;
    try {
      await _repository.eliminarSesion(event.id);
      final eraActiva = loaded.sesionActiva?.id == event.id;
// Si se elimina la sesion activa, la limpia del estado
      emit(loaded.copyWith(
        historial:         loaded.historial.where((s) => s.id != event.id).toList(),
        clearSesionActiva: eraActiva,
      ));
    } catch (e) {
      emit(SesionError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}