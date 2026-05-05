import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../models/alimento.dart';
import '../../../models/registro_diario.dart';
import '../../../repositories/repository_nutricion.dart';

part 'nutricion_event.dart';
part 'nutricion_state.dart';

class NutricionBloc extends Bloc<NutricionEvent, NutricionState> {
  final RepositoryNutricion _repository;

  NutricionBloc({required RepositoryNutricion repository})
      : _repository = repository,
        super(const NutricionInitial()) {
    on<NutricionLoadEvent>(_onLoad);
    on<NutricionCambiarTipoComidaEvent>(_onCambiarTipoComida);
    on<NutricionBuscarAlimentosEvent>(_onBuscarAlimentos);
    on<NutricionCrearAlimentoEvent>(_onCrearAlimento);
    on<NutricionEditarAlimentoEvent>(_onEditarAlimento);
    on<NutricionAnadirAlimentoEvent>(_onAnadirAlimento);
    on<NutricionEliminarAlimentoEvent>(_onEliminarAlimento);
  }

  Future<void> _onLoad(
    NutricionLoadEvent event,
    Emitter<NutricionState> emit,
  ) async {
    emit(const NutricionLoading());
    try {
      final registro = await _repository.getOCCreateRegistroDiario(
        idUsuario: event.idUsuario,
        fecha: event.fecha,
      );
      emit(NutricionLoaded(
        registroDiario: registro,
        tipoComidaActivo: 'Desayuno',
      ));
    } catch (e) {
      emit(NutricionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Cambiar de pestaña no requiere consulta a la BD,
  // solo actualizamos el campo tipoComidaActivo con copyWith
  void _onCambiarTipoComida(
    NutricionCambiarTipoComidaEvent event,
    Emitter<NutricionState> emit,
  ) {
    if (state is NutricionLoaded) {
      emit((state as NutricionLoaded).copyWith(
        tipoComidaActivo: event.tipoComida,
      ));
    }
  }

  Future<void> _onBuscarAlimentos(
    NutricionBuscarAlimentosEvent event,
    Emitter<NutricionState> emit,
  ) async {
    if (state is! NutricionLoaded) return;
    try {
      final alimentos = await _repository.buscarAlimentos(
        search: event.search,
        idUsuario: event.idUsuario,
      );
      emit((state as NutricionLoaded).copyWith(
        resultadosBusqueda: alimentos,
      ));
    } catch (e) {
      emit(NutricionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCrearAlimento(
    NutricionCrearAlimentoEvent event,
    Emitter<NutricionState> emit,
  ) async {
    if (state is! NutricionLoaded) return;
    try {
      await _repository.crearAlimento(
        idUsuario: event.idUsuario,
        nombre: event.nombre,
        kcalPor100g: event.kcalPor100g,
        proteinasPor100g: event.proteinasPor100g,
        carbohidratosPor100g: event.carbohidratosPor100g,
        grasasPor100g: event.grasasPor100g,
      );
      // Limpiamos los resultados de búsqueda para que el usuario
      // vea el buscador vacío y pueda buscar el alimento recién creado
      emit((state as NutricionLoaded).copyWith(
        resultadosBusqueda: [],
      ));
    } catch (e) {
      emit(NutricionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onEditarAlimento(
    NutricionEditarAlimentoEvent event,
    Emitter<NutricionState> emit,
  ) async {
    if (state is! NutricionLoaded) return;
    try {
      await _repository.editarAlimento(
        id: event.id,
        nombre: event.nombre,
        kcalPor100g: event.kcalPor100g,
        proteinasPor100g: event.proteinasPor100g,
        carbohidratosPor100g: event.carbohidratosPor100g,
        grasasPor100g: event.grasasPor100g,
      );
      emit((state as NutricionLoaded).copyWith(resultadosBusqueda: []));
    } catch (e) {
      emit(NutricionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAnadirAlimento(
    NutricionAnadirAlimentoEvent event,
    Emitter<NutricionState> emit,
  ) async {
    if (state is! NutricionLoaded) return;
    final loaded = state as NutricionLoaded;
    try {
      // Si la comida de ese tipo ya existe la reutilizamos,
      // si no la creamos. Así no se duplican las tomas del día
      final comidaExistente = loaded.registroDiario.comidas
          .where((c) => c.tipoComida == event.tipoComida)
          .firstOrNull;

      int idComida;
      if (comidaExistente != null) {
        idComida = comidaExistente.id;
      } else {
        final nuevaComida = await _repository.crearComida(
          idRegistroDiario: event.idRegistroDiario,
          tipoComida: event.tipoComida,
        );
        idComida = nuevaComida.id;
      }

      await _repository.anadirAlimentoAComida(
        idComida: idComida,
        idAlimento: event.idAlimento,
        cantidadGramos: event.cantidadGramos,
      );

      // Recargamos el registro completo para reflejar los nuevos totales
      final registroActualizado = await _repository.getOCCreateRegistroDiario(
        idUsuario: loaded.registroDiario.idUsuario,
        fecha: DateFormat('yyyy-MM-dd').format(loaded.registroDiario.fecha),
      );

      emit(loaded.copyWith(
        registroDiario: registroActualizado,
        resultadosBusqueda: [],
      ));
    } catch (e) {
      emit(NutricionError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onEliminarAlimento(
    NutricionEliminarAlimentoEvent event,
    Emitter<NutricionState> emit,
  ) async {
    if (state is! NutricionLoaded) return;
    final loaded = state as NutricionLoaded;
    try {
      await _repository.eliminarAlimentoDeComida(event.idComidaAlimento);

      // Recargamos el registro para actualizar los totales del día
      final registroActualizado = await _repository.getOCCreateRegistroDiario(
        idUsuario: loaded.registroDiario.idUsuario,
        fecha: DateFormat('yyyy-MM-dd').format(loaded.registroDiario.fecha),
      );

      emit(loaded.copyWith(registroDiario: registroActualizado));
    } catch (e) {
      emit(NutricionError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}