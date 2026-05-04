import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart'; // Librería de gráficos para Flutter, aquí uso PieChart
import 'package:flutter/material.dart';


class CalorieProgressCard extends StatelessWidget {
  final double kcalConsumidas;
  final double kcalObjetivo;

  const CalorieProgressCard({
    super.key,
    required this.kcalConsumidas,
    required this.kcalObjetivo,
  });


  // BUILD
  @override
  Widget build(BuildContext context) {
    // Calculo el progreso como un valor entre 0.0 y 1.0
    // clamp(0.0, 1.0) evita que el valor se salga de ese rango aunque se supere el objetivo
    final progreso = kcalObjetivo > 0
        ? (kcalConsumidas / kcalObjetivo).clamp(0.0, 1.0)
        : 0.0;

    // Si se superó el objetivo cambio el color a rojo
    final superado = kcalConsumidas > kcalObjetivo;
    final color = superado ? const Color(0xFFCF6679) : const Color(0xFFD32F2F);

    // Las kcal restantes nunca pueden ser negativas,
    final kcalRestantes = (kcalObjetivo - kcalConsumidas).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // GRÁFICO CIRCULAR
          SizedBox(
            height: 100, width: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // PieChart de fl_chart, lo uso como anillo de progreso con dos secciones:
                // la parte rellena (progreso) y la parte vacía (lo que queda)
                PieChart(PieChartData(
                  startDegreeOffset: -90, // Empiezo desde arriba en lugar de desde la derecha
                  sectionsSpace: 0,       // Sin espacio entre las secciones para que parezca continuo
                  centerSpaceRadius: 35,  // El hueco del centro para que sea un anillo y no un pastel
                  sections: [
                    // Sección rellena: el progreso en porcentaje (0-100)
                    PieChartSectionData(
                        value: progreso * 100,
                        color: color,
                        radius: 12,
                        showTitle: false),
                    // Sección vacía: lo que queda hasta completar el 100%
                    PieChartSectionData(
                        value: (1 - progreso) * 100,
                        color: const Color(0xFF333333),
                        radius: 12,
                        showTitle: false),
                  ],
                )),
                // Texto del porcentaje encima del gráfico, centrado gracias al Stack
                Text('${(progreso * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // TEXTO DE INFORMACION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('home.calories'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                // Calorías consumidas en grande, cambia de color si se supera el objetivo
                Text('${kcalConsumidas.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  // Si se superó el objetivo muestro un aviso, si no muestro las kcal restantes
                  superado
                      ? 'home.calories_exceeded'.tr()
                      : '${kcalRestantes.toStringAsFixed(0)} ${'home.calories_remaining'.tr()}',
                  style: TextStyle(
                      color: superado ? const Color(0xFFCF6679) : Colors.grey,
                      fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Objetivo diario de calorías siempre visible abajo
                Text(
                  '${'home.calories_goal'.tr()}: ${kcalObjetivo.toStringAsFixed(0)} kcal',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}