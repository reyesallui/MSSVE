import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:flutter/material.dart';


// Tarjeta de progreso calorico: muestra kcal consumidas vs objetivo con barra de progreso
class CalorieProgressCard extends StatelessWidget {
  final double kcalConsumidas;
  final double kcalObjetivo;

  const CalorieProgressCard({
    super.key,
    required this.kcalConsumidas,
    required this.kcalObjetivo,
  });


  
  @override
  Widget build(BuildContext context) {
    
    
    final progreso = kcalObjetivo > 0
        ? (kcalConsumidas / kcalObjetivo).clamp(0.0, 1.0)
        : 0.0;

    
    final superado = kcalConsumidas > kcalObjetivo;
    final color = superado ? const Color(0xFFCF6679) : const Color(0xFFD32F2F);

    
    final kcalRestantes = (kcalObjetivo - kcalConsumidas).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          
          SizedBox(
            height: 100, width: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                
                
                PieChart(PieChartData(
                  startDegreeOffset: -90, 
                  sectionsSpace: 0,       
                  centerSpaceRadius: 35,  
                  sections: [
                    
                    PieChartSectionData(
                        value: progreso * 100,
                        color: color,
                        radius: 12,
                        showTitle: false),
                    
                    PieChartSectionData(
                        value: (1 - progreso) * 100,
                        color: const Color(0xFF333333),
                        radius: 12,
                        showTitle: false),
                  ],
                )),
                
                Text('${(progreso * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),

          const SizedBox(width: 20),

          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('home.calories'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                
                Text('${kcalConsumidas.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  
                  superado
                      ? 'home.calories_exceeded'.tr()
                      : '${kcalRestantes.toStringAsFixed(0)} ${'home.calories_remaining'.tr()}',
                  style: TextStyle(
                      color: superado ? const Color(0xFFCF6679) : Colors.grey,
                      fontSize: 12),
                ),
                const SizedBox(height: 8),
                
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