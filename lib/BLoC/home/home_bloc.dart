import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mssve/models/usuario.dart';
import 'package:mssve/repositories/repository_perfil.dart';
 
import '../../../models/registro_diario.dart';
import '../../../models/rutina.dart';
import '../../../repositories/repository_nutricion.dart';
import '../../../repositories/repository_rutina.dart';
 
part 'home_event.dart';
part 'home_state.dart';

// Carga el resumen del día para la pantalla principal.
// Las 3 consultas se lanzan en paralelo con Future.wait para reducir el tiempo de carga.
// Incluimos el usuario fresco de la BD para que las kcal objetivo reflejen
// siempre el perfil actual — no el usuario cacheado en el login.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RepositoryNutricion _repositoryNutricion;
  final RepositoryRutina _repositoryRutina;
  final RepositoryPerfil _repositoryPerfil;
 
  HomeBloc({
    required RepositoryNutricion repositoryNutricion,
    required RepositoryRutina repositoryRutina,
    required RepositoryPerfil repositoryPerfil,
  })  : _repositoryNutricion = repositoryNutricion,
        _repositoryRutina = repositoryRutina,
        _repositoryPerfil = repositoryPerfil,
        super(const HomeInitial()) {
    on<HomeLoadEvent>(_onLoad);
  }
 
  // *** Cargar resumen del día ***
  Future<void> _onLoad(
    HomeLoadEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      // Lanzamos las 3 consultas en paralelo — registro, rutinas y usuario fresco
      final results = await Future.wait([
        _repositoryNutricion.getOCCreateRegistroDiario(
          idUsuario: event.idUsuario,
          fecha: event.fecha,
        ),
        _repositoryRutina.getRutinas(event.idUsuario),
        _repositoryPerfil.getUsuario(event.idUsuario),
      ]);
 
      emit(HomeLoaded(
        registroDiario: results[0] as RegistroDiario,
        rutinas:        results[1] as List<Rutina>,
        usuario:        results[2] as Usuario,
      ));
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception:', '')));
    }
  }
}
 