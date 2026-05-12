import 'package:equatable/equatable.dart';

// Modelo de usuario con datos antropometricos, objetivo y gasto energetico total (GET)
class Usuario extends Equatable {
  final int id;
  final String nombre;
  final String apellidos;
  final String email;
  final double peso;
  final int altura;
  final String genero;
  final String objetivo;
  final String nivelActividad;
  final double gastoEnergeticoTotal;
  final int edad;
  final DateTime fechaRegistro;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.peso,
    required this.altura,
    required this.genero,
    required this.objetivo,
    required this.nivelActividad,
    required this.gastoEnergeticoTotal,
    required this.edad,
    required this.fechaRegistro,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      email: json['email'] as String,
      peso: double.parse(json['peso'].toString()),
      altura: json['altura'] as int,
      genero: json['genero'] as String,
      objetivo: json['objetivo'] as String,
      nivelActividad: json['nivel_actividad'] as String,
      
      gastoEnergeticoTotal: double.parse(
        (json['gasto_energetico_total'] ?? json['get'] ?? 0).toString(),
      ),
      edad: json['edad'] as int,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'peso': peso,
      'altura': altura,
      'genero': genero,
      'objetivo': objetivo,
      'nivel_actividad': nivelActividad,
      
      
      
      
      'gasto_energetico_total': gastoEnergeticoTotal,
      'edad': edad,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }

  Usuario copyWith({
    int? id,
    String? nombre,
    String? apellidos,
    String? email,
    double? peso,
    int? altura,
    String? genero,
    String? objetivo,
    String? nivelActividad,
    double? gastoEnergeticoTotal,
    int? edad,
    DateTime? fechaRegistro,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      genero: genero ?? this.genero,
      objetivo: objetivo ?? this.objetivo,
      nivelActividad: nivelActividad ?? this.nivelActividad,
      gastoEnergeticoTotal: gastoEnergeticoTotal ?? this.gastoEnergeticoTotal,
      edad: edad ?? this.edad,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  List<Object?> get props => [
        id, nombre, apellidos, email, peso, altura,
        genero, objetivo, nivelActividad,
        gastoEnergeticoTotal, edad, fechaRegistro,
      ];
}