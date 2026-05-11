part of 'perfil_bloc.dart';

abstract class PerfilEvent extends Equatable {
  const PerfilEvent();
  @override
  List<Object?> get props => [];
}

class PerfilLoadEvent extends PerfilEvent {
  final int idUsuario;
  const PerfilLoadEvent(this.idUsuario);
  @override
  List<Object?> get props => [idUsuario];
}

class PerfilActualizarEvent extends PerfilEvent {
  final int id; final String nombre; final String apellidos;
  final String email; final double peso; final int altura;
  final String genero; final String objetivo; final String nivelActividad; final int edad;
  const PerfilActualizarEvent({
    required this.id, required this.nombre, required this.apellidos,
    required this.email, required this.peso, required this.altura,
    required this.genero, required this.objetivo, required this.nivelActividad, required this.edad,
  });
  @override
  List<Object?> get props => [id];
}

class PerfilCambiarPasswordEvent extends PerfilEvent {
  final int userId; final String currentPassword; final String newPassword;
  const PerfilCambiarPasswordEvent({
    required this.userId, required this.currentPassword, required this.newPassword,
  });
  @override
  List<Object?> get props => [userId];
}
