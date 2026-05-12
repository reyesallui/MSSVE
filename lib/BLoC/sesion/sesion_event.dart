part of "sesion_bloc.dart";

abstract class SesionEvent extends Equatable{
  const SesionEvent();
  @override
  List<Object?> get props => [];
}


class SesionCargarHistorialEvent extends SesionEvent{
  final int idUsuario;
  const SesionCargarHistorialEvent(this.idUsuario);
  @override
  List<Object?>get props => [idUsuario];
}



class SesionCrearEvent extends SesionEvent{
  final int idRutina;
  final int idUsuario;
  final String? notas;
  final String? fecha;
  final List<RutinaEjercicio> ejerciciosPlantilla;

  const SesionCrearEvent ({
    required this.idRutina,
    required this.idUsuario,
    this.notas,
    this.fecha,
    required this.ejerciciosPlantilla,
  });

  @override
  List<Object?> get props => [idRutina,idUsuario,fecha];
}


class SesionSeleccionarEvent extends SesionEvent{
  final SesionEntrenamiento sesion;
  const SesionSeleccionarEvent(this.sesion);
  @override
  List<Object?> get props => [sesion.id];
}


class SesionModificarEjercicioEvent extends SesionEvent{
  final int id ;
  final List<SerieDetalle>seriesRealizadas;
  final int? duracionMinutos;
  const SesionModificarEjercicioEvent({
    required this.id,
    required this.seriesRealizadas,
    this.duracionMinutos,
  });
  @override
  List<Object?>get props => [id, duracionMinutos];
}


class SesionAnadirEjercicioEvent extends SesionEvent{
  final int idEjercicio;
  final List<SerieDetalle>seriesRealizadas;
  final int? duracionMinutos;
  const SesionAnadirEjercicioEvent({
    required this.idEjercicio,
    this.seriesRealizadas = const[],
    this.duracionMinutos,
  });
  @override
  List<Object?> get props => [idEjercicio, duracionMinutos];
}



class SesionEliminarEjercicioEvent extends SesionEvent{
  final int id; 
  const SesionEliminarEjercicioEvent({required this.id});
  @override 
  List<Object?>get props => [id];

}


class SesionEliminarEvent extends SesionEvent{
  final int id; 
  const SesionEliminarEvent({required this.id});
  @override 
  List<Object?> get props=> [id];
}
