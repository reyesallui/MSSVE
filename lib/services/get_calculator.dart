class GETCalculator {
  
 
  static double calcularGET({
    required double peso,
    required int altura,
    required int edad,
    required String genero,
    required String nivelActividad,
  }) {
    double tmb;

    if (genero == 'Hombre') {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) + 5;
    } else {
      tmb = (10 * peso) + (6.25 * altura) - (5 * edad) - 161;
    }

    final double factor = _factorActividad(nivelActividad);
    final double get = tmb * factor;

    return double.parse(get.toStringAsFixed(2));
  }

  static double _factorActividad(String nivelActividad) {
    switch (nivelActividad) {
      case 'Sedentario':
        return 1.2;
      case 'Ligero':
        return 1.375;
      case 'Moderado':
        return 1.55;
      case 'Intenso':
        return 1.725;
      case 'Muy_intenso':
        return 1.9;
      default:
        return 1.2;
    }
  }
}