import 'package:equatable/equatable.dart';
import 'alimento.dart';

/// Representa la relación entre una comida y un alimento.
/// Es el modelo de la tabla intermedia (N:M) que almacena
/// cuántos gramos de cada alimento se añaden a una comida.
class ComidaAlimento extends Equatable {
  final int id;
  final int idComida;
  final int idAlimento;
  final double cantidadGramos;
  final double kcalCalculadas;
  final Alimento alimento;

  const ComidaAlimento({
    required this.id,
    required this.idComida,
    required this.idAlimento,
    required this.cantidadGramos,
    required this.kcalCalculadas,
    required this.alimento,
  });

  factory ComidaAlimento.fromJson(Map<String, dynamic> json) {
    return ComidaAlimento( // ← CORREGIDO: era "comidaAlimento" (minúscula), no compilaba
      id: json['id'] as int,
      idComida: json['id_comida'] as int,
      idAlimento: json['id_alimento'] as int,
      cantidadGramos: double.parse(json['cantidad_gramos'].toString()),
      kcalCalculadas: double.parse(json['kcal_calculadas'].toString()),
      // El API devuelve el alimento anidado en el JSON del JOIN
      alimento: Alimento.fromJson(
        json['alimento'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_comida': idComida,
      'id_alimento': idAlimento,
      'cantidad_gramos': cantidadGramos,
      'kcal_calculadas': kcalCalculadas,
      'alimento': alimento.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        idComida,
        idAlimento,
        cantidadGramos,
        kcalCalculadas,
        alimento,
      ];
}