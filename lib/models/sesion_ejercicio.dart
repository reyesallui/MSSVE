import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'rutina_ejercicio.dart'; // Reutilizamos SerieDetalle que ya existe en el proyecto
import 'ejercicio.dart';

// Representa un ejercicio realizado dentro de una sesión real.
// Los pesos y series son los que el usuario hizo de verdad ese día,
// no los de la plantilla.
class SesionEjercicio extends Equatable {
  final int id;
  final int idSesion;
  final int idEjercicio;
  final Ejercicio ejercicio;
  final List<SerieDetalle> seriesRealizadas;
  final int? duracionMinutos;

  const SesionEjercicio({
    required this.id,
    required this.idSesion,
    required this.idEjercicio,
    required this.ejercicio,
    this.seriesRealizadas = const [],
    this.duracionMinutos,
  });

  factory SesionEjercicio.fromJson(Map<String, dynamic> json) {
    // Mismo patrón que RutinaEjercicio para deserializar el JSON de series
    List<SerieDetalle> series = [];
    final raw = json['series_realizadas'];
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        final lista = jsonDecode(raw.toString()) as List<dynamic>;
        series = lista
            .map((e) => SerieDetalle.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return SesionEjercicio(
      id:               json['id'] as int,
      idSesion:         json['id_sesion'] as int,
      idEjercicio:      json['id_ejercicio'] as int,
      ejercicio:        Ejercicio.fromJson(
          json['ejercicio'] as Map<String, dynamic>),
      seriesRealizadas: series,
      duracionMinutos:  json['duracion_minutos'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'id_sesion':       idSesion,
    'id_ejercicio':    idEjercicio,
    'ejercicio':       ejercicio.toJson(),
    // Si no hay series guardamos null en lugar de un array vacío
    'series_realizadas': seriesRealizadas.isEmpty
        ? null
        : jsonEncode(seriesRealizadas.map((s) => s.toJson()).toList()),
    'duracion_minutos': duracionMinutos,
  };

  @override
  // seriesRealizadas incluido para detectar cambios al modificar pesos/reps
  List<Object?> get props =>
      [id, idSesion, idEjercicio, seriesRealizadas, duracionMinutos];
}