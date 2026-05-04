part of "sesion_bloc.dart";

abstract class SesionEvent extends Equatable{
  const SesionEvent();
  @override
  List<Object?> get props => [];
}

//Historial 
//Carga el historial del usuario

class SesionCargarHistorialEvent extends SesionEvent{
  final int idUsuario;
  const SesionCargarHistorialEvent(this.idUsuario);
  @override
  List<Object?>get props => [idUsuario];
}

//Crear sesión 
//Crea una sesión nueva o carga la existente si hay ya una para esa fecha y rutina
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

//Seleccionar sesion
//Seleccionamos una sesión para ver su historial

class SesionSeleccionarEvent extends SesionEvent{
  final SesionEntrenamiento sesion;
  const SesionSeleccionarEvent(this.sesion);
  @override
  List<Object?> get props => [sesion.id];
}

//Modificar ejercicio 
//Guarda los pesos y series reales que el usuario hizo en un ejercicio 
class SesionModificarEjercicioEvent extends SesionEvent{
  final int id ;
  final List<SerieDetalle>seriesRealizadas;
  const SesionModificarEjercicioEvent({
    required this.id,
    required this.seriesRealizadas,
  });
  @override
  List<Object?>get props => [id];
}

//Añadir ejercicio
//Añade un ejercicio extra a la sesión.
class SesionAnadirEjercicioEvent extends SesionEvent{
  final int idEjercicio;
  final List<SerieDetalle>seriesRealizadas;
  const SesionAnadirEjercicioEvent({
    required this.idEjercicio,
    this.seriesRealizadas = const[],
  });
  @override
  List<Object?> get props => [idEjercicio];
}

//Eliminar ejercicio

class SesionEliminarEjercicioEvent extends SesionEvent{
  final int id; 
  const SesionEliminarEjercicioEvent({required this.id});
  @override 
  List<Object?>get props => [id];

}

//Eliminar Sesión
class SesionEliminarEvent extends SesionEvent{
  final int id; 
  const SesionEliminarEvent({required this.id});
  @override 
  List<Object?> get props=> [id];
}
