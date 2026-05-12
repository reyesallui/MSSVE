

import 'package:equatable/equatable.dart';

import 'comida_alimento.dart';

// Modelo de comida (Desayuno, Almuerzo, etc.) con lista de alimentos y totales calculados
class Comida extends Equatable{

  final int id;
  final int idRegistroDiario;
  final String tipoComida;
  final String? hora;
  final List<ComidaAlimento>alimentos;

  const Comida({

    required this.id,
    required this.idRegistroDiario,
    required this.tipoComida,
    this.hora,
    this.alimentos =const[],
  });

  factory Comida.fromJson(Map<String,dynamic>json){
    final alimentosJson = json["alimentos"] as List<dynamic>? ??[];
    return Comida(
      id: json["id"] as int,
      idRegistroDiario: json["id_registro_diario"] as int,
      tipoComida: json["tipo_comida"] as String,
      hora: json["hora"] as String ?,
      alimentos: alimentosJson
      .map((a) => ComidaAlimento.fromJson(a as Map<String, dynamic>))
      .toList(),
    );
  }

  
  double get totalKcal => 
// Suma de kcal de todos los alimentos de la comida
  alimentos.fold(0.0,(sum,a)=>sum +a.kcalCalculadas);



  

// Suma de macros (proteinas, carbohidratos, grasas) de todos los alimentos
  Map<String, double>get totalMacros{
    double proteinas = 0;
    double carbohidratos =0;
    double grasas =0;

    for(final ca in alimentos){

      final macros = ca.alimento.calcularMacros(ca.cantidadGramos);
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
  List<Object?> get props => [id,idRegistroDiario,tipoComida,hora,alimentos];
}