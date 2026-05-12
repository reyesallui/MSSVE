part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckSessionEvent extends AuthEvent {
  const AuthCheckSessionEvent();
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginEvent({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final String nombre;
  final String apellidos;
  final String email;
  final String password;
  final double peso;
  final int altura;
  final String genero;
  final String objetivo;
  final String nivelActividad;
  final double get;
  final int edad;

  const AuthRegisterEvent({
    required this.nombre, required this.apellidos,
    required this.email, required this.password,
    required this.peso, required this.altura,
    required this.genero, required this.objetivo,
    required this.nivelActividad, required this.get, required this.edad,
  });

  @override
  List<Object?> get props => [email];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}




class AuthUpdateUserEvent extends AuthEvent {
  final Usuario usuario;
  const AuthUpdateUserEvent(this.usuario);
  @override
  List<Object?> get props => [usuario];
}