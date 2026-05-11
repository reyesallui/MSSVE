part of 'perfil_bloc.dart';

abstract class PerfilState extends Equatable {
  const PerfilState();
  @override
  List<Object?> get props => [];
}

class PerfilInitial extends PerfilState {
  const PerfilInitial();
}

class PerfilLoading extends PerfilState {
  const PerfilLoading();
}

class PerfilLoaded extends PerfilState {
  final Usuario usuario;
  const PerfilLoaded(this.usuario);
  @override
  List<Object?> get props => [usuario];
}

class PerfilSucces extends PerfilState {
  final Usuario usuario;
  final String message;
  const PerfilSucces({required this.usuario, required this.message});
  @override
  List<Object?> get props => [usuario, message];
}

class PerfilError extends PerfilState {
  final String message;
  const PerfilError(this.message);
  @override
  List<Object?> get props => [message];
}
