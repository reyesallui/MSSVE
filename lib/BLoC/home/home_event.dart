part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadEvent extends HomeEvent {
  final int idUsuario;
  final String fecha;
  const HomeLoadEvent({required this.idUsuario, required this.fecha});
  @override
  List<Object?> get props => [idUsuario, fecha];
}
