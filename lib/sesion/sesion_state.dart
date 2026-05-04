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

// _version garantiza que cada emit sea único para Equatable.
// Sin esto BlocBase.emit() puede descartar estados que parecen iguales
// aunque sesionActiva o los ejercicios hayan cambiado.
class SesionLoaded extends SesionState {
  final List<SesionEntrenamiento> historial;
  final SesionEntrenamiento? sesionActiva;
  final int _version;

  SesionLoaded({
    required this.historial,
    this.sesionActiva,
  }) : _version = DateTime.now().microsecondsSinceEpoch;

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
  // _version hace único cada estado emitido — BlocBase.emit nunca lo descarta
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