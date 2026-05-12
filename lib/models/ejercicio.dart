import 'package:equatable/equatable.dart';




// Modelo de ejercicio con nombres multidioma (es/en/fr) y clasificacion (cardio/grupo muscular)
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

  
  
  
// Retorna el nombre del ejercicio segun el idioma activo, con fallback a espanol
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

  
  
  String get nombre => nombreEs;

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    
    
    
    final nombreFallback = json['nombre'] as String? ?? '';
// Compatibilidad con datos legacy que usan solo 'nombre' sin sufijo de idioma
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