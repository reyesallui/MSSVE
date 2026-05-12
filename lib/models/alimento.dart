import 'package:equatable/equatable.dart';



// Modelo de alimento con macros por 100g y metodos de calculo por cantidad
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

  
  
// Calcula kcal segun gramos: (kcal_por_100g * gramos) / 100
  double calcularKcal(double gramos) {
    return double.parse(
      ((kcalPor100g * gramos) / 100).toStringAsFixed(2),
    );
  }

  
// Calcula proteinas/carbohidratos/grasas segun cantidad en gramos
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