import 'package:equatable/equatable.dart';

/// Representa un alimento, ya sea global del sistema (idUsuario == null)
/// o personalizado creado por el usuario (idUsuario != null, esPersonalizado == true).
class Alimento extends Equatable {
  final int id;
  final int? idUsuario;
  final String nombre;
  final double kcalPor100g;
  final double proteinasPor100g;
  final double carbohidratosPor100g;
  final double grasasPor100g;
  final bool esPersonalizado;

  const Alimento({
    required this.id,
    this.idUsuario,
    required this.nombre,
    required this.kcalPor100g,
    required this.proteinasPor100g,
    required this.carbohidratosPor100g,
    required this.grasasPor100g,
    this.esPersonalizado = false,
  });

  factory Alimento.fromJson(Map<String, dynamic> json) {
    return Alimento(
      id: json['id'] as int,
      idUsuario: json['id_usuario'] as int?,
      nombre: json['nombre'] as String,
      kcalPor100g: double.parse(json['kcal_por_100g'].toString()),
      proteinasPor100g: double.parse(json['proteinas_por_100g'].toString()),
      carbohidratosPor100g:
          double.parse(json['carbohidratos_por_100g'].toString()),
      grasasPor100g: double.parse(json['grasas_por_100g'].toString()),
      esPersonalizado: json['es_personalizado'] == true ||
          json['es_personalizado'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_usuario': idUsuario,
      'nombre': nombre,
      'kcal_por_100g': kcalPor100g,
      'proteinas_por_100g': proteinasPor100g,
      'carbohidratos_por_100g': carbohidratosPor100g,
      'grasas_por_100g': grasasPor100g,
      'es_personalizado': esPersonalizado,
    };
  }

  // copyWith
  Alimento copyWith({
    int? id,
    int? idUsuario,
    String? nombre,
    double? kcalPor100g,
    double? proteinasPor100g,
    double? carbohidratosPor100g,
    double? grasasPor100g,
    bool? esPersonalizado,
  }) {
    return Alimento(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      kcalPor100g: kcalPor100g ?? this.kcalPor100g,
      proteinasPor100g: proteinasPor100g ?? this.proteinasPor100g,
      carbohidratosPor100g:
          carbohidratosPor100g ?? this.carbohidratosPor100g,
      grasasPor100g: grasasPor100g ?? this.grasasPor100g,
      esPersonalizado: esPersonalizado ?? this.esPersonalizado,
    );
  }

  /// Calcula las Kcal para una cantidad específica de gramos.
  /// Lo usamos en el AddFoodDialog.
  double calcularKcal(double gramos) {
    return double.parse(
      ((kcalPor100g * gramos) / 100).toStringAsFixed(2),
    );
  }

  /// Calcula los macros para una cantidad específica de gramos.
  Map<String, double> calcularMacros(double gramos) {
    return {
      'proteinas': double.parse(
          ((proteinasPor100g * gramos) / 100).toStringAsFixed(2)),
      'carbohidratos': double.parse(
          ((carbohidratosPor100g * gramos) / 100).toStringAsFixed(2)),
      'grasas': double.parse(
          ((grasasPor100g * gramos) / 100).toStringAsFixed(2)),
    };
  }

  @override
  List<Object?> get props => [
        id,
        idUsuario,
        nombre,
        kcalPor100g,
        proteinasPor100g,
        carbohidratosPor100g,
        grasasPor100g,
        esPersonalizado,
      ];
}