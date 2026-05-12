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

// BloC del home: carga paralela de registro diario, rutinas y perfil del usuario
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

  Future<void> _onLoad(HomeLoadEvent event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
// Carga en paralelo los 3 bloques de datos para la pantalla principal
        _repositoryNutricion.getOCCreateRegistroDiario(idUsuario: event.idUsuario, fecha: event.fecha),
        _repositoryRutina.getRutinas(event.idUsuario),
        _repositoryPerfil.getUsuario(event.idUsuario),
      ]);
      emit(HomeLoaded(
        registroDiario: results[0] as RegistroDiario,
        rutinas: results[1] as List<Rutina>,
        usuario: results[2] as Usuario,
      ));
    } catch (e) {
      emit(HomeError(e.toString().replaceAll('Exception:', '')));
    }
  }
}