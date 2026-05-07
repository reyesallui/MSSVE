part of 'rutina_bloc.dart';

abstract class RutinaEvent extends Equatable {
  const RutinaEvent();

  @override
  List<Object?> get props => [];
}

class RutinaLoadEvent extends RutinaEvent {
  final int idUsuario;
  const RutinaLoadEvent(this.idUsuario);

  @override
  List<Object?> get props => [idUsuario];
}

class RutinaSeleccionarEvent extends RutinaEvent {
  final Rutina rutina;
  const RutinaSeleccionarEvent(this.rutina);

  @override
  List<Object?> get props => [rutina.id];
}

class RutinaCrearEvent extends RutinaEvent {
  final int idUsuario;
  final String nombre;
  final String fecha;
  final String? notas;

  const RutinaCrearEvent({
    required this.idUsuario,
    required this.nombre,
    required this.fecha,
    this.notas,
  });

  @override
  List<Object?> get props => [nombre, fecha];
}

class RutinaModificarEvent extends RutinaEvent {
  final int id;
  final int idUsuario;
  final String? nombre;
  final String? fecha;
  final String? notas;

  const RutinaModificarEvent({
    required this.id,
    required this.idUsuario,
    this.nombre,
    this.fecha,
    this.notas,
  });

  @override
  List<Object?> get props => [id];
}

class RutinaEliminarEvent extends RutinaEvent {
  final int id;
  final int idUsuario;
  const RutinaEliminarEvent({required this.id, required this.idUsuario});

  @override
  List<Object?> get props => [id];
}

class RutinaDuplicarEvent extends RutinaEvent {
  final Rutina rutina;
  final String nuevoNombre;
  final String nuevaFecha;

  const RutinaDuplicarEvent({
    required this.rutina,
    required this.nuevoNombre,
    required this.nuevaFecha,
  });

  @override
  List<Object?> get props => [rutina.id];
}

class RutinaBuscarEjerciciosEvent extends RutinaEvent {
  final String search;
  final int idUsuario;
  final bool? esCardio;
  final String? grupoMuscular;

  const RutinaBuscarEjerciciosEvent({
    required this.search,
    required this.idUsuario,
    this.esCardio,
    this.grupoMuscular,
  });

  @override
  List<Object?> get props => [search, grupoMuscular];
}

class RutinaCrearEjercicioEvent extends RutinaEvent {
  final int idUsuario;
  final String nombre;
  final bool esCardio;
  final String? grupoMuscular;

  const RutinaCrearEjercicioEvent({
    required this.idUsuario,
    required this.nombre,
    required this.esCardio,
    this.grupoMuscular,
  });

  @override
  List<Object?> get props => [nombre];
}

class RutinaAnadirEjercicioEvent extends RutinaEvent {
  final int idRutina;
  final int idEjercicio;
  final int idUsuario;
  final int? series;
  final int? repeticiones;
  final double? pesoKg;
  final int? duracionMinutos;
  final List<SerieDetalle> seriesDetalle;

  const RutinaAnadirEjercicioEvent({
    required this.idRutina,
    required this.idEjercicio,
    required this.idUsuario,
    this.series,
    this.repeticiones,
    this.pesoKg,
    this.duracionMinutos,
    this.seriesDetalle = const [],
  });

  @override
  List<Object?> get props => [idRutina, idEjercicio];
}

// ── MODIFICADO: añadido seriesDetalle ──────────────────────────
class RutinaModificarEjercicioEvent extends RutinaEvent {
  final int id;
  final int idUsuario;
  final int? series;
  final int? repeticiones;
  final double? pesoKg;
  final int? duracionMinutos;
  final List<SerieDetalle> seriesDetalle;

  const RutinaModificarEjercicioEvent({
    required this.id,
    required this.idUsuario,
    this.series,
    this.repeticiones,
    this.pesoKg,
    this.duracionMinutos,
    this.seriesDetalle = const [],
  });

  @override
  List<Object?> get props => [id];
}

class RutinaEliminarEjercicioEvent extends RutinaEvent {
  final int id;
  final int idUsuario;

  const RutinaEliminarEjercicioEvent({
    required this.id,
    required this.idUsuario,
  });

  @override
  List<Object?> get props => [id];
}
