part of 'perfil_bloc.dart';

abstract class PerfilState extends Equatable{
  const PerfilState();
  @override
  List<Object?> get props => [];
}

class PerfilInitial extends PerfilState{
  const PerfilInitial();

}
class PerfilLoading extends PerfilState{
  const PerfilLoading();
}

//Datos del perfil cargador correctamente

class PerfilLoaded extends PerfilState{
  final Usuario usuario;
  const PerfilLoaded(this.usuario);
  @override
  List<Object?>get props => [usuario];
}

//Operacion completada: perfil actualizado o contraseña cambiada.
//Incluye el usuario actualizado y un mensaje para mostrar en la UI 
class PerfilSucces extends PerfilState{
  final Usuario usuario; 
  final String message;

  const PerfilSucces({required this.usuario, required this.message});

  @override
  List<Object?> get props => [usuario,message];
}

class PerfilError extends PerfilState{
  final String message; 
  const PerfilError(this.message);
  @override 
  List<Object?> get props => [message];
}
