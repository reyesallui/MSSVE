import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 
import '../../models/usuario.dart';
import '../../repositories/repository_perfil.dart';
 
part 'perfil_event.dart';
part 'perfil_state.dart';

class PerfilBloc extends Bloc<PerfilEvent,PerfilState>{
  final RepositoryPerfil _repository;

  PerfilBloc({required RepositoryPerfil repository})
  : _repository = repository,
  super(const PerfilInitial()){
    on<PerfilLoadEvent>(_onLoad);
    on<PerfilActualizarEvent>(_onActualizar);
    on<PerfilCambiarPasswordEvent>(_onCambiarPassword);
  }
  Future<void>_onLoad(
    PerfilLoadEvent event,
    Emitter<PerfilState> emit,

  )async{
    emit(const PerfilLoading());
    try{
      final usuario = await _repository.getUsuario(event.idUsuario);
      emit(PerfilLoaded(usuario));
    }catch(e){
      emit(PerfilError(e.toString().replaceAll("Exceptiom", "")));
    }
  }

  Future<void> _onActualizar(
    PerfilActualizarEvent event,
    Emitter<PerfilState> emit,
  )async{
    emit(const PerfilLoading());
    try{
      final usuario = await _repository.actualizarPerfil(
      id: event.id,
      nombre: event.nombre,
      apellidos: event.apellidos,
      email: event.email,
      peso: event.peso,
      altura: event.altura,
      genero: event.genero, 
      objetivo: event.objetivo, 
      nivelActividad: event.nivelActividad, 
      edad: event.edad,
      );

      //PerfilSucces lleva el usuario actualizado y el mensaje para que la UI pueda actualizar los datos y mostrar el snackbar
      emit(PerfilSucces(usuario: usuario, message: "perfil.succes_update"));
    }catch (e){
      emit(PerfilError(e.toString().replaceAll("Exception", "")));
    }
  }

  Future<void> _onCambiarPassword(
    PerfilCambiarPasswordEvent event,
    Emitter<PerfilState> emit,
  )async{
    emit(const PerfilLoading());
    try{
      await _repository.cambiarPassword(
      userId: event.userId,
      currentPassword: event.currentPassword, 
      newPassword: event.newPassword,
      );

      //Recuperamos el usuario para devolverlo en el estado actualizado 
      final usuario = await _repository.getUsuario(event.userId);
      emit(PerfilSucces(usuario: usuario,message:"perfil.succes_password"));

    }catch (e){
      emit(PerfilError(e.toString().replaceAll("Exception", "")));
    }
  }
}