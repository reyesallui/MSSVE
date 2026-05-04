import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 
import '../../models/registro_diario.dart';
import '../../models/rutina.dart';
import '../../repositories/repository_nutricion.dart';
import '../../repositories/repository_rutina.dart';
 
part 'home_event.dart';
part 'home_state.dart';


//HomeBloc carga el resumen del dia que se muestra en la pantalla principal.
//Las 2 consultas (registro y rutinas) se lanzan en paralelo con Future.wait para reducir el tiempo de carga a la mitad
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final RepositoryNutricion _repositoryNutricion;
  final RepositoryRutina _repositoryRutina;
 
  HomeBloc({
    required RepositoryNutricion repositoryNutricion,
    required RepositoryRutina repositoryRutina,
  })  : _repositoryNutricion = repositoryNutricion,
        _repositoryRutina = repositoryRutina,
        super(const HomeInitial()) {
    on<HomeLoadEvent>(_onLoad);
  }

  Future<void> _onLoad(
    HomeLoadEvent event,
    Emitter<HomeState>emit,
  )async{
    emit(const HomeLoading());
    try{
      //Future.wait lanza ambas consultas al mismo tiempo y espera a que las 2 terminen antes de continuar
      final results = await Future.wait([
        _repositoryNutricion.getOCCreateRegistroDiario(
        idUsuario: event.idUsuario,
         fecha: event.fecha),
         _repositoryRutina.getRutinas(event.idUsuario),
      ]);

      emit(HomeLoaded(
        registroDiario: results[0] as RegistroDiario,
        rutinas: results[1] as List<Rutina>,
      ));

    }catch (e){
      emit(HomeError(e.toString().replaceAll("Excpecion: ", "")));
    }
  }
}