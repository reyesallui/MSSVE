part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

// *** Estado cargado ***
// Incluye usuario fresco para que las kcal objetivo estén siempre actualizadas
class HomeLoaded extends HomeState {
  final RegistroDiario registroDiario;
  final List<Rutina> rutinas;
  final Usuario usuario;

  const HomeLoaded({
    required this.registroDiario,
    required this.rutinas,
    required this.usuario,
  });

  @override
  List<Object?> get props => [registroDiario, rutinas, usuario];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}