

import 'package:equatable/equatable.dart';

import 'comida.dart';

// Modelo del registro diario: fecha, kcal totales, lista de comidas y macros acumulados
class RegistroDiario extends Equatable{
  final int id; 
  final int idUsuario;
  final DateTime fecha;
  final double kcalTotalesDia;
  final List<Comida> comidas;


  const RegistroDiario({
    required this.id,
    required this.idUsuario,
    required this.fecha,
    required this.kcalTotalesDia,
    this.comidas = const[],
  });

  factory RegistroDiario.fromJson(Map<String,dynamic>json){
    final comidasJson= json["comidas"] as List<dynamic>? ?? [];
    return RegistroDiario(
      id: json["id"]as int,
      idUsuario: json["id_usuario"]as int,
      fecha: DateTime.parse(json["fecha"]as String),
      kcalTotalesDia: double.parse(
        (json["kcal_totales_dia"] ?? 0).toString(),
      ),
      comidas: comidasJson
      .map((c) => Comida.fromJson(c as Map<String,dynamic>))
      .toList(),
    );
  }

  

  double get kcalConsumidas =>
// Calcula kcal totales consumidas en el dia sumando todas las comidas
  comidas.fold(0.0, (sum, c) => sum + c.totalKcal);

  

// Agrega macros de todas las comidas del dia
  Map<String, double> get macrosTotales{
    double proteinas = 0;
    double carbohidratos = 0;
    double grasas = 0;
    for(final comida in comidas){
      final macros = comida.totalMacros;
      proteinas += macros["proteinas"]!;
      carbohidratos += macros["carbohidratos"]!;
      grasas += macros["grasas"]!;
    }
    return{
      "proteinas": double.parse(proteinas.toStringAsFixed(2)),
      "carbohidratos": double.parse(carbohidratos.toStringAsFixed(2)),
      "grasas": double.parse(grasas.toStringAsFixed(2)),
    };
  }

  @override
  List<Object?> get props => [
    id,
    idUsuario,
    fecha,
    kcalTotalesDia,
    comidas
    ];

}