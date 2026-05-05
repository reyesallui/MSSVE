part of 'nutricion_bloc.dart';

abstract class NutricionState extends Equatable {
  const NutricionState();

  @override
  List<Object?> get props => [];
}

class NutricionInitial extends NutricionState {
  const NutricionInitial();
}

class NutricionLoading extends NutricionState {
  const NutricionLoading();
}

// Estado principal que contiene todos los datos de la pantalla.
// Usamos copyWith para actualizar solo los campos que cambian
// sin tener que recrear el objeto entero cada vez
class NutricionLoaded extends NutricionState {
  final RegistroDiario registroDiario;
  final String tipoComidaActivo;       // pestaña seleccionada
  final List<Alimento> resultadosBusqueda;

  const NutricionLoaded({
    required this.registroDiario,
    required this.tipoComidaActivo,
    this.resultadosBusqueda = const [],
  });

  NutricionLoaded copyWith({
    RegistroDiario? registroDiario,
    String? tipoComidaActivo,
    List<Alimento>? resultadosBusqueda,
  }) {
    return NutricionLoaded(
      registroDiario: registroDiario ?? this.registroDiario,
      tipoComidaActivo: tipoComidaActivo ?? this.tipoComidaActivo,
      resultadosBusqueda: resultadosBusqueda ?? this.resultadosBusqueda,
    );
  }

  @override
  List<Object?> get props => [
        registroDiario,
        tipoComidaActivo,
        resultadosBusqueda,
      ];
}

class NutricionError extends NutricionState {
  final String message;

  const NutricionError(this.message);

  @override
  List<Object?> get props => [message];
}