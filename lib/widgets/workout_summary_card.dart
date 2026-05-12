import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mssve/models/rutina.dart';

// Resumen de rutinas en la pantalla principal con acceso rapido
class WorkoutSummaryCard extends StatelessWidget {
  final List<Rutina> rutinas;
  final VoidCallback onVerTodas;

  const WorkoutSummaryCard({
    super.key, required this.rutinas, required this.onVerTodas,
  });

  @override
  Widget build(BuildContext context) {
    final rutinasVisibles = rutinas.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('home.routines'.tr(),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: onVerTodas,
                child: Text('home.see_all'.tr(),
                    style: const TextStyle(color: Color(0xFFD32F2F))),
              ),
            ],
          ),
          if (rutinasVisibles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('home.no_routines'.tr(),
                  style: const TextStyle(color: Colors.grey)),
            )
          else
            ...rutinasVisibles.map((r) => _RutinaItem(rutina: r)),
        ],
      ),
    );
  }
}

class _RutinaItem extends StatelessWidget {
  final Rutina rutina;
  const _RutinaItem({required this.rutina});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: Color(0xFFD32F2F), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rutina.nombre,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Text('${rutina.ejercicios.length} ejercicios',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )),
        ],
      ),
    );
  }
}