import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';




// Tarjeta de macronutrientes: proteinas, carbohidratos y grasas con color coding
class MacroProgressCard extends StatelessWidget {
  final double proteinas;
  final double carbohidratos;
  final double grasas;
  final double proteinasObjetivo;
  final double carbohidratosObjetivo;
  final double grasasObjetivo;

  const MacroProgressCard({
    super.key,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
    required this.proteinasObjetivo,
    required this.carbohidratosObjetivo,
    required this.grasasObjetivo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('home.macros'.tr(),
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _MacroBar(label: 'macro.proteins'.tr(), valor: proteinas,
              objetivo: proteinasObjetivo, color: const Color(0xFF4FC3F7)),
          const SizedBox(height: 12),
          _MacroBar(label: 'macro.carbs'.tr(), valor: carbohidratos,
              objetivo: carbohidratosObjetivo, color: const Color(0xFFFFB74D)),
          const SizedBox(height: 12),
          _MacroBar(label: 'macro.fats'.tr(), valor: grasas,
              objetivo: grasasObjetivo, color: const Color(0xFFA5D6A7)),
        ],
      ),
    );
  }
}




class _MacroBar extends StatelessWidget {
  final String label;
  final double valor;
  final double objetivo;
  final Color color;

  const _MacroBar({required this.label, required this.valor,
      required this.objetivo, required this.color});

  @override
  Widget build(BuildContext context) {
    
    
    
    final progreso = objetivo > 0 ? (valor / objetivo).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            
            Text('${valor.toStringAsFixed(1)}g / ${objetivo.toStringAsFixed(0)}g',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progreso,
            backgroundColor: const Color(0xFF333333),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}