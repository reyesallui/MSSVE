
// Calculadora de Gasto Energetico Total usando Mifflin-St Jeor + factor de actividad + ajuste por objetivo
class GETCalculator {

  
  static double calcularGET({
    required double peso,
    required int altura,
    required int edad,
    required String genero,
    required String nivelActividad,
    String objetivo = 'Recomposicion',
  }) {
    
    final double tmb = genero == 'Hombre'
// Formula de Mifflin-St Jeor: varia segun genero (hombres +5, mujeres -161)
        ? (10 * peso) + (6.25 * altura) - (5 * edad) + 5
        : (10 * peso) + (6.25 * altura) - (5 * edad) - 161;

    final double get = tmb * _factorActividad(nivelActividad);

    
    final double ajuste = _ajusteObjetivo(objetivo);

    return double.parse((get + ajuste).toStringAsFixed(2));
  }

  
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

  
  
  
  
// Ajuste calorico: +400 para volumen, -400 para definicion, 0 para recomposicion
  static double _ajusteObjetivo(String objetivo) {
    switch (objetivo) {
      case 'Volumen':    return 400;
      case 'Definicion': return -400;
      default:           return 0;
    }
  }
}