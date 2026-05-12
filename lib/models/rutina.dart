
import 'package:equatable/equatable.dart';
import 'rutina_ejercicio.dart';

// Modelo de rutina de entrenamiento con nombre, fecha, notas y lista de ejercicios
class Rutina extends Equatable{

  final int id;
  final int idUsuario;
  final String nombre;
  final DateTime fecha;
  final String? notas;
  final List<RutinaEjercicio> ejercicios;

  const Rutina({
    required this.id,
    required this.idUsuario,
    required this.nombre,
    required this.fecha,
    this.notas,
    this.ejercicios = const [],
  });


  factory Rutina.fromJson(Map<String,dynamic> json){
    final ejerciciosJson = json["ejercicios"] as List<dynamic>? ??[];
    return Rutina(
      id: json["id"] as int,
      idUsuario: json["id_usuario"] as int,
      nombre: json['nombre'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      notas: json['notas'] as String?,
      ejercicios: ejerciciosJson
          .map((e) => RutinaEjercicio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic>toJson(){
    return{
      "id":id,
      "id_usuario":idUsuario,
      "nombre":nombre,
      "fecha": fecha.toIso8601String().split("T").first,
      "notas":notas,
      "ejercicios":ejercicios.map((e) => e.toJson()).toList(),
    };
  }

  Rutina copyWith({
    String? nombre,
    DateTime? fecha,
    String? notas,
    List<RutinaEjercicio>?ejercicios,
  }){
    return Rutina(

      id:id,
      idUsuario: idUsuario,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      ejercicios: ejercicios ?? this.ejercicios,

    );
  }
  @override
  List<Object?> get props => [
    id,
    idUsuario,
    nombre,
    fecha,
    notas,
    ejercicios,
  ];
}