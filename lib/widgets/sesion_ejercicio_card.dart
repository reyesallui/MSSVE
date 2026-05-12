import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/models/sesion_ejercicio.dart';


const _maxReps = 999;
const _maxMinutos = 999;
const _maxPeso = 999;

// Tarjeta de ejercicio en sesion activa con registro de series
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

  
  @override
  Widget build(BuildContext context) {
    final ejercicio    = widget.sesionEjercicio.ejercicio;
    final esCardio     = ejercicio.esCardio;
    final nombre       = ejercicio.nombrePara(context.locale.languageCode);
    final series       = widget.sesionEjercicio.seriesRealizadas;
    final tieneDatos   = series.isNotEmpty || widget.sesionEjercicio.duracionMinutos != null;

    
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

            
            if (!esCardio && _expandido && tieneDatos) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF333333), height: 1),
              const SizedBox(height: 8),
              ...List.generate(series.length, (i) {
                final s = series[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
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
                      if (s.dropset) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('DROP',
                              style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    if (s.dropset && s.dropsets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 2),
                        child: Row(
                          children: s.dropsets.asMap().entries.map((e) =>
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('↓${e.value} kg',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ),
                          ).toList(),
                        ),
                      ),
                  ],
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
      
      final fuente =
          series.isNotEmpty ? series : [const SerieDetalle(reps: 0)];
      _ctrls = fuente
          .map((s) => _SerieCtrl(
                reps: s.reps > 0 ? s.reps.toString() : '',
                peso: s.peso?.toString() ?? '',
                dropset: s.dropset,
                dropsets: s.dropsets.map((d) => d.toString()).toList(),
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

  
  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          mensaje,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  
  void _guardar() {
    
    if (_esCardio) {
      final minutos = int.tryParse(_minCtrl.text.trim()) ?? 0;
      if (minutos < 1 || minutos > _maxMinutos) {
        _mostrarError('La duración debe estar entre 1 y $_maxMinutos minutos');
        return;
      }
      widget.onGuardar?.call(const [], minutos);
    } else {
      for (final c in _ctrls) {
        final reps = int.tryParse(c.repsCtr.text.trim());
        if (reps == null || reps < 1 || reps > _maxReps) {
          _mostrarError('Las repeticiones deben estar entre 1 y $_maxReps');
          return;
        }
        final peso = double.tryParse(c.pesoCtr.text.trim());
        if (peso != null && (peso < 0 || peso > _maxPeso)) {
          _mostrarError('El peso debe estar entre 0 y $_maxPeso kg');
          return;
        }
      }

      final series = _ctrls
          .map((c) => SerieDetalle(
                reps: int.tryParse(c.repsCtr.text.trim()) ?? 0,
                peso: c.pesoCtr.text.isEmpty
                    ? null
                    : double.tryParse(c.pesoCtr.text),
                dropset: c.dropset,
                dropsets: c.dropset
                    ? c.dropsetCtrls
                        .map((d) => double.tryParse(d.text) ?? 0.0)
                        .toList()
                    : [],
              ))
          .toList();
      widget.onGuardar?.call(series, null);
    }
    Navigator.pop(context);
  }

  
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
                        SizedBox(width: 8),
                        SizedBox(
                            width: 48,
                            child: Text('Drop',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center)),
                        SizedBox(width: 4),
                        SizedBox(width: 18),
                      ]),
                    ),
                    ...List.generate(_ctrls.length, (i) {
                      final c = _ctrls[i];
                      return StatefulBuilder(
                        builder: (context, setRow) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
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
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 48,
                                  child: Checkbox(
                                    value: c.dropset,
                                    activeColor: const Color(0xFFD32F2F),
                                    side: const BorderSide(color: Colors.grey),
                                    onChanged: (v) {
                                      setRow(() {
                                        c.dropset = v ?? false;
                                        if (!c.dropset) {
                                          for (final d in c.dropsetCtrls) {
                                            d.dispose();
                                          }
                                          c.dropsetCtrls.clear();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                            ),
                            if (c.dropset) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 28, top: 2, bottom: 4),
                                child: Row(children: [
                                  const Icon(Icons.arrow_downward,
                                      color: Color(0xFFD32F2F), size: 13),
                                  const SizedBox(width: 4),
                                  const Text('Dropsets',
                                      style: TextStyle(
                                          color: Color(0xFFD32F2F), fontSize: 12)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setRow(() =>
                                        c.dropsetCtrls.add(TextEditingController())),
                                    child: const Icon(Icons.add_circle_outline,
                                        color: Color(0xFFD32F2F), size: 18),
                                  ),
                                ]),
                              ),
                              ...List.generate(c.dropsetCtrls.length, (di) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 28, bottom: 4),
                                  child: Row(children: [
                                    Text('Drop ${di + 1}',
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: _Campo(
                                          ctrl: c.dropsetCtrls[di], hint: 'kg'),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setRow(() {
                                        c.dropsetCtrls[di].dispose();
                                        c.dropsetCtrls.removeAt(di);
                                      }),
                                      child: const Icon(Icons.close,
                                          color: Colors.grey, size: 14),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ],
                        ),
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


class _SerieCtrl {
  final TextEditingController repsCtr;
  final TextEditingController pesoCtr;
  bool dropset;
  List<TextEditingController> dropsetCtrls;

  _SerieCtrl({
    String reps = '',
    String peso = '',
    this.dropset = false,
    List<String> dropsets = const [],
  })  : repsCtr = TextEditingController(text: reps),
        pesoCtr = TextEditingController(text: peso),
        dropsetCtrls =
            dropsets.map((d) => TextEditingController(text: d)).toList();

  void dispose() {
    repsCtr.dispose();
    pesoCtr.dispose();
    for (final d in dropsetCtrls) {
      d.dispose();
    }
  }
}