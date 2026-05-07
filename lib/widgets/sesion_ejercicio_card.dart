import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/models/sesion_ejercicio.dart';

// Tarjeta de un ejercicio dentro de la sesión activa
class SesionEjercicioCard extends StatefulWidget {
  final SesionEjercicio sesionEjercicio;
  final void Function(List<SerieDetalle> series, int? duracionMinutos)? onGuardar;
  final VoidCallback? onEliminar;

  const SesionEjercicioCard({
    super.key,
    required this.sesionEjercicio,
    this.onGuardar,
    this.onEliminar,
  });

  @override
  State<SesionEjercicioCard> createState() => _SesionEjercicioCardState();
}

class _SesionEjercicioCardState extends State<SesionEjercicioCard> {
  bool _expandido = false;

  void _abrirEdicion() {
    showDialog(
      context: context,
      builder: (_) => _EditarSeriesDialog(
        sesionEjercicio: widget.sesionEjercicio,
        onGuardar: widget.onGuardar,
      ),
    );
  }

  // /BUILD/
  @override
  Widget build(BuildContext context) {
    final ejercicio    = widget.sesionEjercicio.ejercicio;
    final esCardio     = ejercicio.esCardio;
    final nombre       = ejercicio.nombrePara(context.locale.languageCode);
    final series       = widget.sesionEjercicio.seriesRealizadas;
    final tieneDatos   = series.isNotEmpty || widget.sesionEjercicio.duracionMinutos != null;

    //Solo se expande con ejercicio de fuerza que tengan datos.
    return GestureDetector(
      onTap: (!esCardio && tieneDatos)
          ? () => setState(() => _expandido = !_expandido)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: _expandido
              ? Border.all(color: const Color(0xFFD32F2F).withOpacity(0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // /CABECERA/
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  esCardio
                      ? Icons.directions_run_outlined
                      : Icons.fitness_center_outlined,
                  color: const Color(0xFFD32F2F), size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (ejercicio.grupoMuscular != null)
                      Text(ejercicio.grupoMuscular!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
                 // Solo se muestra la fecha si es un ejercicio de
              if (!esCardio && tieneDatos)
                AnimatedRotation(
                  turns: _expandido ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey, size: 20),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Color(0xFFD32F2F), size: 20),
                tooltip: esCardio
                    ? 'sesion.edit_duration'.tr()
                    : 'sesion.edit_sets'.tr(),
                onPressed: _abrirEdicion,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (widget.onEliminar != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFCF6679), size: 20),
                  onPressed: widget.onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ]),

            // /RESUMEN/
            const SizedBox(height: 6),
            if (esCardio) ...[
              Text(
                _textoDuracionCardio(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            ] else if (!tieneDatos)
              Text('sesion.no_sets_yet'.tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12))
            else
              Text(_resumenFuerza(series),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),

            // /DETALLES/
            if (!esCardio && _expandido && tieneDatos) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF333333), height: 1),
              const SizedBox(height: 8),
              ...List.generate(series.length, (i) {
                final s = series[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 20,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.reps} reps'
                      '${s.peso != null ? ' · ${s.peso} kg' : ''}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _textoDuracionCardio() {
    final dur = widget.sesionEjercicio.duracionMinutos;
    if (dur != null) return '$dur min';
    final series = widget.sesionEjercicio.seriesRealizadas;
    if (series.isNotEmpty) return '${series.first.reps} min';
    return 'sesion.no_duration_yet'.tr();
  }

  // Agrupa reps y pesos distintos con / para el texto resumen
  String _resumenFuerza(List<SerieDetalle> series) {
    final n    = series.length;
    final reps = series.map((s) => s.reps).toSet();
    final kg   = series.where((s) => s.peso != null).map((s) => s.peso!).toSet();
    final partes = <String>['$n series'];
    partes.add(reps.length == 1
        ? '${reps.first} reps'
        : '${series.map((s) => s.reps).join('/')} reps');
    if (kg.isNotEmpty) {
      partes.add(kg.length == 1
          ? '${kg.first} kg'
          : '${series.where((s) => s.peso != null).map((s) => s.peso).join('/')} kg');
    }
    return partes.join(' · ');
  }
}

// /DIÁLOGO DE EDICIÓN/
//Si es cardio se edita la duración, si es fuerza se edita las series enteras y comprobamos que no hay 0 reps
class _EditarSeriesDialog extends StatefulWidget {
  final SesionEjercicio sesionEjercicio;
  final void Function(List<SerieDetalle> series, int? duracionMinutos)? onGuardar;

  const _EditarSeriesDialog({
    required this.sesionEjercicio,
    this.onGuardar,
  });

  @override
  State<_EditarSeriesDialog> createState() => _EditarSeriesDialogState();
}

class _EditarSeriesDialogState extends State<_EditarSeriesDialog> {
  late List<_SerieCtrl> _ctrls;
  late TextEditingController _minCtrl;

  bool get _esCardio => widget.sesionEjercicio.ejercicio.esCardio;

  @override
  void initState() {
    super.initState();
    final series = widget.sesionEjercicio.seriesRealizadas;

    if (_esCardio) {
      final minutos = widget.sesionEjercicio.duracionMinutos ??
          (series.isNotEmpty ? series.first.reps : 0);
      _minCtrl = TextEditingController(
          text: minutos > 0 ? minutos.toString() : '');
      _ctrls = [];
    } else {
      _minCtrl = TextEditingController();
      // Si no hay series guardadas empezamos con una fila vacía
      final fuente =
          series.isNotEmpty ? series : [const SerieDetalle(reps: 0)];
      _ctrls = fuente
          .map((s) => _SerieCtrl(
                reps: s.reps > 0 ? s.reps.toString() : '',
                peso: s.peso?.toString() ?? '',
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  // Avisa si alguna serie tiene 0 reps antes de guardar
  void _mostrarErrorReps() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          'sesion.min_one_rep'.tr(),
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
  }

  // /GUARDAR/
  void _guardar() {
    //no pueden haber series con 0 repes
    if (!_esCardio) {
      final tieneRepsCero = _ctrls.any((c) {
        final val = int.tryParse(c.repsCtr.text.trim());
        return val == null || val <= 0;
      });
      if (tieneRepsCero) {
        _mostrarErrorReps();
        return;
      }
    }

    if (_esCardio) {
      final minutos = int.tryParse(_minCtrl.text.trim()) ?? 0;
      widget.onGuardar?.call(const [], minutos > 0 ? minutos : null);
    } else {
      final series = _ctrls
          .map((c) => SerieDetalle(
                reps: int.tryParse(c.repsCtr.text.trim()) ?? 0,
                peso: c.pesoCtr.text.isEmpty
                    ? null
                    : double.tryParse(c.pesoCtr.text),
              ))
          .toList();
      widget.onGuardar?.call(series, null);
    }
    Navigator.pop(context);
  }

  // /BUILD DIÁLOGO/
  @override
  Widget build(BuildContext context) {
    final nombre = widget.sesionEjercicio.ejercicio
        .nombrePara(context.locale.languageCode);

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombre,
              style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(
            _esCardio
                ? 'sesion.edit_duration'.tr()
                : 'sesion.edit_sets'.tr(),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _esCardio

            // /CARDIO/
            ? TextField(
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'rutina.duration_min'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey),
                  suffixText: 'min',
                  suffixStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              )

            // /FUERZA/
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 28, bottom: 6),
                      child: Row(children: [
                        Expanded(
                            child: Text('Reps',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center)),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text('Peso (kg)',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center)),
                        SizedBox(width: 28),
                      ]),
                    ),
                    ...List.generate(_ctrls.length, (i) {
                      final c = _ctrls[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(
                            width: 20,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _Campo(ctrl: c.repsCtr, hint: '10')),
                          const SizedBox(width: 8),
                          Expanded(child: _Campo(ctrl: c.pesoCtr, hint: 'kg')),
                          const SizedBox(width: 4),
                          // Mínimo 1 serie — botón quitar solo si hay más de una
                          if (_ctrls.length > 1)
                            GestureDetector(
                              onTap: () => setState(() {
                                _ctrls[i].dispose();
                                _ctrls.removeAt(i);
                              }),
                              child: const Icon(Icons.remove_circle_outline,
                                  color: Color(0xFFCF6679), size: 18),
                            )
                          else
                            const SizedBox(width: 18),
                        ]),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _ctrls.add(_SerieCtrl())),
                      icon: const Icon(Icons.add_circle_outline,
                          color: Color(0xFFD32F2F), size: 16),
                      label: Text('sesion.add_set'.tr(),
                          style: const TextStyle(
                              color: Color(0xFFD32F2F), fontSize: 13)),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _guardar,
          child: Text('common.save'.tr(),
              style: const TextStyle(
                  color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// /WIDGETS AUXILIARES/

// Campo numérico compacto reutilizado en reps y peso
class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _Campo({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFF555555), fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// Agrupa los controladores de una fila de serie
class _SerieCtrl {
  final TextEditingController repsCtr;
  final TextEditingController pesoCtr;

  _SerieCtrl({String reps = '', String peso = ''})
      : repsCtr = TextEditingController(text: reps),
        pesoCtr = TextEditingController(text: peso);

  void dispose() {
    repsCtr.dispose();
    pesoCtr.dispose();
  }
}