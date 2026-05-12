import 'package:equatable/equatable.dart';
import 'sesion_ejercicio.dart';




// Modelo de sesion de entrenamiento completada con ejercicios realizados
class SesionEntrenamiento extends Equatable {
  final int id;
  final int idRutina;
  final int idUsuario;
  final DateTime fecha;
  final String? notas;
  
  final String nombreRutina;
  final List<SesionEjercicio> ejercicios;

  const SesionEntrenamiento({
    required this.id,
    required this.idRutina,
    required this.idUsuario,
    required this.fecha,
    this.notas,
    required this.nombreRutina,
    this.ejercicios = const [],
  });

  factory SesionEntrenamiento.fromJson(Map<String, dynamic> json) {
    return SesionEntrenamiento(
      id:           json['id'] as int,
      idRutina:     json['id_rutina'] as int,
      idUsuario:    json['id_usuario'] as int,
      
      fecha:        DateTime.parse(json['fecha'].toString()),
      notas:        json['notas'] as String?,
      nombreRutina: json['nombre_rutina'] as String? ?? '',
      ejercicios: (json['ejercicios'] as List<dynamic>? ?? [])
          .map((e) => SesionEjercicio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'id_rutina':     idRutina,
    'id_usuario':    idUsuario,
    'fecha':         fecha.toIso8601String(),
    'notas':         notas,
    'nombre_rutina': nombreRutina,
    'ejercicios':    ejercicios.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, idRutina, idUsuario, fecha, ejercicios];
}