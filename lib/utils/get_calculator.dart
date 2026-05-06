// Calcula el GET usando Mifflin-St Jeor y lo ajusta según el objetivo
class GETCalculator {

  // *** GET base (Mifflin-St Jeor) ***
  static double calcularGET({
    required double peso,
    required int altura,
    required int edad,
    required String genero,
    required String nivelActividad,
    String objetivo = 'Recomposicion',
  }) {
    // Fórmula distinta para hombre y mujer
    final double tmb = genero == 'Hombre'
        ? (10 * peso) + (6.25 * altura) - (5 * edad) + 5
        : (10 * peso) + (6.25 * altura) - (5 * edad) - 161;

    final double get = tmb * _factorActividad(nivelActividad);

    // *** Ajuste por objetivo ***
    final double ajuste = _ajusteObjetivo(objetivo);

    return double.parse((get + ajuste).toStringAsFixed(2));
  }

  // *** Factor de actividad ***
  static double _factorActividad(String nivelActividad) {
    switch (nivelActividad) {
      case 'Sedentario':  return 1.2;
      case 'Ligero':      return 1.375;
      case 'Moderado':    return 1.55;
      case 'Intenso':     return 1.725;
      case 'Muy_intenso': return 1.9;
      default:            return 1.2;
    }
  }

  // *** Ajuste calórico según objetivo ***
  // Volumen: +400 kcal (superávit para ganar músculo)
  // Definición: -400 kcal (déficit para perder grasa)
  // Recomposición: sin ajuste (mantener peso)
  static double _ajusteObjetivo(String objetivo) {
    switch (objetivo) {
      case 'Volumen':    return 400;
      case 'Definicion': return -400;
      default:           return 0;
    }
  }
}