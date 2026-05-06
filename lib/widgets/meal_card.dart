import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/comida.dart';

// Tarjeta expandible que muestra una toma del día (Desayuno, Almuerzo...).
// Se puede expandir para ver los alimentos y sus kcal individuales.
// El botón de añadir abre el buscador de alimentos para esa toma
class MealCard extends StatelessWidget {
  final Comida comida;
  final VoidCallback onAnadirAlimento;
  final void Function(int idComidaAlimento) onEliminarAlimento;

  const MealCard({
    super.key,
    required this.comida,
    required this.onAnadirAlimento,
    required this.onEliminarAlimento,
  });

  @override
  Widget build(BuildContext context) {
    final totalKcal = comida.totalKcal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        iconColor: const Color(0xFFD32F2F),
        collapsedIconColor: Colors.grey,
        title: Row(
          children: [
            _iconoTipoComida(comida.tipoComida),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                comida.tipoComida,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${totalKcal.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          // Lista de alimentos de esta toma
          ...comida.alimentos.map((ca) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  ca.alimento.nombre ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  '${ca.cantidadGramos.toStringAsFixed(0)}g',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${ca.kcalCalculadas.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.grey, size: 18),
                      onPressed: () => onEliminarAlimento(ca.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )),

          // Botón para añadir un alimento a esta toma
          TextButton.icon(
            onPressed: onAnadirAlimento,
            icon: const Icon(Icons.add,
                color: Color(0xFFD32F2F), size: 18),
            label: Text(
              'nutricion.add_food'.tr(),
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }

  // Icono diferente según el tipo de comida para identificarlas visualmente
  Widget _iconoTipoComida(String tipo) {
    final iconos = {
      'Desayuno': Icons.free_breakfast_outlined,
      'Almuerzo': Icons.lunch_dining_outlined,
      'Merienda': Icons.coffee_outlined,
      'Cena': Icons.dinner_dining_outlined,
      'Extra': Icons.add_circle_outline,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconos[tipo] ?? Icons.restaurant_outlined,
        color: const Color(0xFFD32F2F),
        size: 18,
      ),
    );
  }
}