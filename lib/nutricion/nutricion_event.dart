part of 'nutricion_bloc.dart';

abstract class NutricionEvent extends Equatable {
  const NutricionEvent();

  @override
  List<Object?> get props => [];
}

// Carga el registro del día al entrar a la pantalla de nutrición
class NutricionLoadEvent extends NutricionEvent {
  final int idUsuario;
  final String fecha;

  const NutricionLoadEvent({required this.idUsuario, required this.fecha});

  @override
  List<Object?> get props => [idUsuario, fecha];
}

// El usuario cambia de pestaña (Desayuno, Almuerzo, etc.)
class NutricionCambiarTipoComidaEvent extends NutricionEvent {
  final String tipoComida;

  const NutricionCambiarTipoComidaEvent(this.tipoComida);

  @override
  List<Object?> get props => [tipoComida];
}

// El usuario escribe en el buscador de alimentos
class NutricionBuscarAlimentosEvent extends NutricionEvent {
  final String search;
  final int idUsuario;

  const NutricionBuscarAlimentosEvent({
    required this.search,
    required this.idUsuario,
  });

  @override
  List<Object?> get props => [search, idUsuario];
}

// El usuario pulsa "Crear alimento" y rellena el formulario
class NutricionCrearAlimentoEvent extends NutricionEvent {
  final int idUsuario;
  final String nombre;
  final double kcalPor100g;
  final double proteinasPor100g;
  final double carbohidratosPor100g;
  final double grasasPor100g;

  const NutricionCrearAlimentoEvent({
    required this.idUsuario,
    required this.nombre,
    required this.kcalPor100g,
    required this.proteinasPor100g,
    required this.carbohidratosPor100g,
    required this.grasasPor100g,
  });

  @override
  List<Object?> get props => [nombre];
}

// El usuario edita un alimento personalizado existente
class NutricionEditarAlimentoEvent extends NutricionEvent {
  final int id;
  final String nombre;
  final double kcalPor100g;
  final double proteinasPor100g;
  final double carbohidratosPor100g;
  final double grasasPor100g;

  const NutricionEditarAlimentoEvent({
    required this.id,
    required this.nombre,
    required this.kcalPor100g,
    required this.proteinasPor100g,
    required this.carbohidratosPor100g,
    required this.grasasPor100g,
  });

  @override
  List<Object?> get props => [id];
}

// El usuario selecciona un alimento del buscador e introduce los gramos
class NutricionAnadirAlimentoEvent extends NutricionEvent {
  final int idComida;
  final int idAlimento;
  final double cantidadGramos;
  final int idRegistroDiario;
  final String tipoComida;

  const NutricionAnadirAlimentoEvent({
    required this.idComida,
    required this.idAlimento,
    required this.cantidadGramos,
    required this.idRegistroDiario,
    required this.tipoComida,
  });

  @override
  List<Object?> get props => [idComida, idAlimento];
}

// El usuario pulsa el icono de eliminar junto a un alimento
class NutricionEliminarAlimentoEvent extends NutricionEvent {
  final int idComidaAlimento;

  const NutricionEliminarAlimentoEvent(this.idComidaAlimento);

  @override
  List<Object?> get props => [idComidaAlimento];
}