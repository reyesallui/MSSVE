part of "sesion_bloc.dart";

abstract class SesionEvent extends Equatable{
  const SesionEvent();
  @override
  List<Object?> get props => [];
}

// Evento para cargar todo el historial de entrenamientos del usuario
class SesionCargarHistorialEvent extends SesionEvent{
  final int idUsuario;
  const SesionCargarHistorialEvent(this.idUsuario);
  @override
  List<Object?>get props => [idUsuario];
}

// Crea una sesion nueva. Si ya existe una para la misma fecha y rutina,
// el BLoC la carga directamente sin duplicar (logica en _onCrear).
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

// Selecciona una sesion del historial para verla en detalle o trabajar con ella
class SesionSeleccionarEvent extends SesionEvent{
  final SesionEntrenamiento sesion;
  const SesionSeleccionarEvent(this.sesion);
  @override
  List<Object?> get props => [sesion.id];
}

// Guarda los pesos, repeticiones y series reales que el usuario hizo en un ejercicio
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

// Anade un ejercicio extra a la sesion activa (por si el usuario decide anadir algo sobre la marcha)
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

// Elimina un ejercicio de la sesion activa

class SesionEliminarEjercicioEvent extends SesionEvent{
  final int id; 
  const SesionEliminarEjercicioEvent({required this.id});
  @override 
  List<Object?>get props => [id];

}

// Elimina una sesion completa del historial
class SesionEliminarEvent extends SesionEvent{
  final int id; 
  const SesionEliminarEvent({required this.id});
  @override 
  List<Object?> get props=> [id];
}
