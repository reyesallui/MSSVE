part of 'sesion_bloc.dart';

abstract class SesionState extends Equatable {
  const SesionState();
  @override
  List<Object?> get props => [];
}

class SesionInitial extends SesionState {
  const SesionInitial();
}

class SesionLoading extends SesionState {
  const SesionLoading();
}




class SesionLoaded extends SesionState {
  final List<SesionEntrenamiento> historial;
  final SesionEntrenamiento? sesionActiva;
  final int _version;

  SesionLoaded({
    required this.historial,
    this.sesionActiva,
  }) : _version = DateTime.now().microsecondsSinceEpoch;
// _version fuerza notificacion aunque historial/sesionActiva sean la misma referencia

  SesionLoaded copyWith({
    List<SesionEntrenamiento>? historial,
    SesionEntrenamiento? sesionActiva,
    bool clearSesionActiva = false,
  }) {
    return SesionLoaded(
      historial:    historial    ?? this.historial,
      sesionActiva: clearSesionActiva
          ? null
          : (sesionActiva ?? this.sesionActiva),
    );
  }

  @override
  
  List<Object?> get props => [_version];
}

class SesionError extends SesionState {
  final String message;
  final int _version;

  SesionError(this.message)
      : _version = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [_version, message];
}