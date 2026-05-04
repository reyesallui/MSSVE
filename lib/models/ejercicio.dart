import 'package:equatable/equatable.dart';

// Representa un ejercicio de la BD o creado por el usuario.
// Almacena el nombre en los tres idiomas para mostrarlo
// en el idioma activo sin volver a consultar la BD.
class Ejercicio extends Equatable {
  final int id;
  final int? idUsuario;
  final String nombreEs;
  final String nombreEn;
  final String nombreFr;
  final bool esCardio;
  final String? grupoMuscular;
  final bool esPersonalizado;

  const Ejercicio({
    required this.id,
    this.idUsuario,
    required this.nombreEs,
    required this.nombreEn,
    required this.nombreFr,
    required this.esCardio,
    this.grupoMuscular,
    this.esPersonalizado = false,
  });

  // Devuelve el nombre en el idioma activo.
  // Si el idioma no está soportado o el nombre está vacío
  // cae al español como fallback.
  String nombrePara(String languageCode) {
    switch (languageCode) {
      case 'en':
        return nombreEn.isNotEmpty ? nombreEn : nombreEs;
      case 'fr':
        return nombreFr.isNotEmpty ? nombreFr : nombreEs;
      default:
        return nombreEs;
    }
  }

  // Propiedad de conveniencia — nombre en el idioma actual
  // usado en todo el código existente que accede a ejercicio.nombre
  String get nombre => nombreEs;

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    // Soporte para ambos esquemas:
    // - BD nueva: nombre_es / nombre_en / nombre_fr
    // - BD antigua o ejercicio personalizado: nombre (se copia a los tres)
    final nombreFallback = json['nombre'] as String? ?? '';
    return Ejercicio(
      id:              json['id'] as int,
      idUsuario:       json['id_usuario'] as int?,
      nombreEs:        (json['nombre_es'] as String?) ?? nombreFallback,
      nombreEn:        (json['nombre_en'] as String?) ?? nombreFallback,
      nombreFr:        (json['nombre_fr'] as String?) ?? nombreFallback,
      esCardio:        json['es_cardio'] == true || json['es_cardio'] == 1,
      grupoMuscular:   json['grupo_muscular'] as String?,
      esPersonalizado: json['es_personalizado'] == true ||
                       json['es_personalizado'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':               id,
    'id_usuario':       idUsuario,
    'nombre_es':        nombreEs,
    'nombre_en':        nombreEn,
    'nombre_fr':        nombreFr,
    'es_cardio':        esCardio,
    'grupo_muscular':   grupoMuscular,
    'es_personalizado': esPersonalizado,
  };

  @override
  List<Object?> get props => [
    id, idUsuario, nombreEs, nombreEn, nombreFr,
    esCardio, grupoMuscular, esPersonalizado,
  ];
}