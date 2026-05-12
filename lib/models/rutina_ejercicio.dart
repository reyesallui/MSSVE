import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'ejercicio.dart';



// Modelo de detalle por serie: repeticiones, peso opcional, dropsets
class SerieDetalle extends Equatable {
  final int reps;
  final double? peso;
  final bool dropset;
  
  final List<double> dropsets;

  const SerieDetalle({
    required this.reps,
    this.peso,
    this.dropset = false,
    this.dropsets = const [],
  });

  factory SerieDetalle.fromJson(Map<String, dynamic> json) {
    return SerieDetalle(
      reps: int.parse((json['reps'] ?? 10).toString()),
      peso: json['peso'] != null ? double.parse(json['peso'].toString()) : null,
      dropset: json['dropset'] == true || json['dropset'] == 1,
      dropsets: (json['dropsets'] as List<dynamic>? ?? [])
          .map((d) => double.parse(d.toString()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'peso': peso,
    'dropset': dropset,
    'dropsets': dropsets,
  };

  SerieDetalle copyWith({
    int? reps,
    double? peso,
    bool? dropset,
    List<double>? dropsets,
  }) {
    return SerieDetalle(
      reps: reps ?? this.reps,
      peso: peso ?? this.peso,
      dropset: dropset ?? this.dropset,
      dropsets: dropsets ?? this.dropsets,
    );
  }

  @override
  List<Object?> get props => [reps, peso, dropset, dropsets];
}

// Relacion N:M entre rutina y ejercicio con series/repeticiones/peso y series detalle en JSON
class RutinaEjercicio extends Equatable {
  final int id;
  final int idRutina;
  final int idEjercicio;
  final int? series;
  final int? repeticiones;
  final double? pesoKg;
  final int? duracionMinutos;
  final Ejercicio ejercicio;
  
  final List<SerieDetalle> seriesDetalle;

  const RutinaEjercicio({
    required this.id,
    required this.idRutina,
    required this.idEjercicio,
    this.series,
    this.repeticiones,
    this.pesoKg,
    this.duracionMinutos,
    required this.ejercicio,
    this.seriesDetalle = const [],
  });

  factory RutinaEjercicio.fromJson(Map<String, dynamic> json) {
    
    List<SerieDetalle> detalle = [];
    final raw = json['series_detalle'];
// Deserializa JSON de series detalle (cada serie con reps, peso, dropsets)
    if (raw != null && raw.toString().isNotEmpty) {
      try {
        final lista = jsonDecode(raw.toString()) as List<dynamic>;
        detalle = lista
            .map((e) => SerieDetalle.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return RutinaEjercicio(
      id: json['id'] as int,
      idRutina: json['id_rutina'] as int,
      idEjercicio: json['id_ejercicio'] as int,
      series: json['series'] as int?,
      repeticiones: json['repeticiones'] as int?,
      pesoKg: json['peso_kg'] != null
          ? double.parse(json['peso_kg'].toString())
          : null,
      duracionMinutos: json['duracion_minutos'] as int?,
      ejercicio: Ejercicio.fromJson(
        json['ejercicio'] as Map<String, dynamic>,
      ),
      seriesDetalle: detalle,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_rutina': idRutina,
    'id_ejercicio': idEjercicio,
    'series': series,
    'repeticiones': repeticiones,
    'peso_kg': pesoKg,
    'duracion_minutos': duracionMinutos,
    'ejercicio': ejercicio.toJson(),
    'series_detalle': seriesDetalle.isEmpty
        ? null
        : jsonEncode(seriesDetalle.map((s) => s.toJson()).toList()),
  };

  RutinaEjercicio copyWith({
    int? series,
    int? repeticiones,
    double? pesoKg,
    int? duracionMinutos,
    List<SerieDetalle>? seriesDetalle,
  }) {
    return RutinaEjercicio(
      id: id,
      idRutina: idRutina,
      idEjercicio: idEjercicio,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
      pesoKg: pesoKg ?? this.pesoKg,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      ejercicio: ejercicio,
      seriesDetalle: seriesDetalle ?? this.seriesDetalle,
    );
  }

  @override
  List<Object?> get props => [
    id, idRutina, idEjercicio, series, repeticiones,
    pesoKg, duracionMinutos, ejercicio, seriesDetalle,
  ];
}