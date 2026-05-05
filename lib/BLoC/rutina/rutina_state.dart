part of 'rutina_bloc.dart';

abstract class RutinaState extends Equatable {
  const RutinaState();

  @override
  List<Object?> get props => [];
}

class RutinaInitial extends RutinaState {
  const RutinaInitial();
}

class RutinaLoading extends RutinaState {
  const RutinaLoading();
}

// Estado principal con la lista de rutinas, la rutina seleccionada
// y los resultados del buscador de ejercicios.
// clearRutinaActiva existe porque copyWith no puede pasar null
// a un campo nullable: el ?? lo ignoraría, necesitamos un flag explícito
class RutinaLoaded extends RutinaState {
  final List<Rutina> rutinas;
  final Rutina? rutinaActiva;
  final List<Ejercicio> resultadosBusqueda;

  const RutinaLoaded({
    required this.rutinas,
    this.rutinaActiva,
    this.resultadosBusqueda = const [],
  });

  RutinaLoaded copyWith({
    List<Rutina>? rutinas,
    Rutina? rutinaActiva,
    List<Ejercicio>? resultadosBusqueda,
    bool clearRutinaActiva = false,
  }) {
    return RutinaLoaded(
      rutinas: rutinas ?? this.rutinas,
      rutinaActiva:
          clearRutinaActiva ? null : (rutinaActiva ?? this.rutinaActiva),
      resultadosBusqueda: resultadosBusqueda ?? this.resultadosBusqueda,
    );
  }

  @override
  List<Object?> get props => [rutinas, rutinaActiva, resultadosBusqueda];
}

class RutinaError extends RutinaState {
  final String message;

  const RutinaError(this.message);

  @override
  List<Object?> get props => [message];
}