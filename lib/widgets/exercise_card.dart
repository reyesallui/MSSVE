import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mssve/models/rutina_ejercicio.dart';


// Tarjeta  que muestra un ejercicio de la rutina.
// Es un StatefulWidget porque tiene estado propio si está expandida o no.
class ExerciseCard extends StatefulWidget {
  final RutinaEjercicio rutinaEjercicio;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  // Callback que devuelve la lista de series modificadas para
  // que el BLoC pueda guardarlas en la BD
  final void Function(List<SerieDetalle>)? onGuardarDetalle;

  const ExerciseCard({
    super.key,
    required this.rutinaEjercicio,
    this.onEditar,
    this.onEliminar,
    this.onGuardarDetalle,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}


// Estado de ExerciseCard. Aquí vive la lógica de expandir/contraer la tarjeta.
class _ExerciseCardState extends State<ExerciseCard> {
  bool _expandido = false;

  // Abre el diálogo de edición con todos los detalles del ejercicio
  void _abrirEdicion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EditarDetalleDialog(
        rutinaEjercicio: widget.rutinaEjercicio,
        onGuardar: widget.onGuardarDetalle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ejercicio    = widget.rutinaEjercicio.ejercicio;
    final esCardio     = ejercicio.esCardio;
    final nombre       = ejercicio.nombrePara(context.locale.languageCode);
    final detalle      = widget.rutinaEjercicio.seriesDetalle;
    // Solo mostramos el detalle si es fuerza Y tiene series guardadas
    final tieneDetalle = !esCardio && detalle.isNotEmpty;

    return GestureDetector(
      // Solo es clickable si tiene detalle que mostrar
      onTap: tieneDetalle ? () => setState(() => _expandido = !_expandido) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          // El borde rojo solo aparece cuando la tarjeta está expandida
          border: _expandido
              ? Border.all(color: const Color(0xFFD32F2F).withOpacity(0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //CABECERA 
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                // Icono diferente según si es cardio o fuerza
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
              // AnimatedRotation gira la flecha 180° cuando se expande.
              // turns: 0.5 equivale a media vuelta (180°)
              if (tieneDetalle)
                AnimatedRotation(
                  turns: _expandido ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey, size: 20),
                ),
              if (tieneDetalle) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFFD32F2F), size: 18),
                  tooltip: 'Editar series',
                  onPressed: () => _abrirEdicion(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              if (widget.onEliminar != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFCF6679), size: 18),
                  onPressed: widget.onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ]),

            //RESUMEN 
            const SizedBox(height: 6),
            if (esCardio && widget.rutinaEjercicio.duracionMinutos != null)
              Text('${widget.rutinaEjercicio.duracionMinutos} min',
                  style: const TextStyle(color: Colors.grey, fontSize: 12))
            else if (tieneDetalle)
              Text(_resumenSeries(detalle),
                  style: const TextStyle(color: Colors.grey, fontSize: 12))
            else if (!esCardio)
              Text(_labelFuerza(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),

            //DETALLE EXPANDIDO 
            if (_expandido && tieneDetalle) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xFF333333), height: 1),
              const SizedBox(height: 8),
              // List.generate es como un for loop que devuelve widgets
              ...List.generate(detalle.length, (i) {
                final serie = detalle[i];
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
                        '${serie.reps} reps'
                        '${serie.peso != null ? ' · ${serie.peso} kg' : ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      // Badge "DROP" que solo aparece si la serie tiene dropset
                      if (serie.dropset) ... //los ... es un objeto que permite recorrer secuencialmente una colección de elementos como una lista,
                      [
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
                    // Si tiene dropsets, los mostramos en una fila debajo
                    if (serie.dropset && serie.dropsets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 2),
                        child: Row(
                          // .asMap().entries nos da el índice y el valor a la vez
                          children: serie.dropsets.asMap().entries.map((e) =>
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('↓${e.value} kg',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ),
                          ).toList(),
                        ),
                      ),
                    if (i < detalle.length - 1)
                      const Divider(color: Color(0xFF222222), height: 12),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Genera un texto resumen como "3 series · 10/8/6 reps · 50/45 kg".
  // Usa Set para detectar si todos los valores son iguales o varían entre series.
  String _resumenSeries(List<SerieDetalle> detalle) {
    final numSeries = detalle.length;
    final pesos = detalle.where((s) => s.peso != null).map((s) => s.peso!).toSet();
    final reps  = detalle.map((s) => s.reps).toSet();
    //Cambiar series para traducirlo
    final partes = <String>['$numSeries series'];
    if (reps.length == 1) {
      partes.add('${reps.first} reps');
    } else {
      partes.add('${detalle.map((s) => '${s.reps}').join('/')} reps');
    }
    if (pesos.isNotEmpty) {
      if (pesos.length == 1) {
        partes.add('${pesos.first} kg');
      } else {
        partes.add('${detalle.where((s) => s.peso != null).map((s) => '${s.peso}').join('/')} kg');
      }
    }
    return partes.join(' · ');
  }

  // Genera el texto de resumen cuando no hay series detalladas guardadas todavía.
  // Solo muestra los campos que no sean null.
  String _labelFuerza() {
    final partes = <String>[];
    //Cambiar el texto para traducirlo
    if (widget.rutinaEjercicio.series != null) {
      partes.add('${widget.rutinaEjercicio.series} series');
    }
    if (widget.rutinaEjercicio.repeticiones != null) {
      partes.add('${widget.rutinaEjercicio.repeticiones} reps');
    }
    if (widget.rutinaEjercicio.pesoKg != null) {
      partes.add('${widget.rutinaEjercicio.pesoKg} kg');
    }
    return partes.isEmpty ? '' : partes.join(' · ');
  }
}


// Diálogo para editar las series de un ejercicio.
// Es StatefulWidget porque gestiona los controladores de texto de cada serie.
class _EditarDetalleDialog extends StatefulWidget {
  final RutinaEjercicio rutinaEjercicio;
  final void Function(List<SerieDetalle>)? onGuardar;

  const _EditarDetalleDialog({
    required this.rutinaEjercicio,
    this.onGuardar,
  });

  @override
  State<_EditarDetalleDialog> createState() => _EditarDetalleDialogState();
}


class _EditarDetalleDialogState extends State<_EditarDetalleDialog> {
  late List<_SerieEditCtrl> _ctrls;

  @override
  void initState() {
    super.initState();
    // Creamos un controlador por cada serie existente, precargando sus valores
    _ctrls = widget.rutinaEjercicio.seriesDetalle.map((s) {
      return _SerieEditCtrl(
        reps: s.reps.toString(),
        peso: s.peso?.toString() ?? '',
        dropset: s.dropset,
        dropsets: s.dropsets.map((d) => d.toString()).toList(),
      );
    }).toList();
  }

  @override
  void dispose() {
    // Importante: liberar todos los TextEditingController para evitar memory leaks
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    // Convertimos los textos de los campos a los tipos correctos (int, double)
    // int.tryParse devuelve null si el texto no es un número, por eso usamos ??
    final nuevasSeries = _ctrls.map((c) {
      return SerieDetalle(
        reps: int.tryParse(c.repsCtr.text) ?? 0,
        peso: c.pesoCtr.text.isEmpty ? null : double.tryParse(c.pesoCtr.text),
        dropset: c.dropset,
        dropsets: c.dropset
            ? c.dropsetCtrls
                .map((d) => double.tryParse(d.text) ?? 0.0)
                .toList()
            : [],
      );
    }).toList();

    widget.onGuardar?.call(nuevasSeries);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.rutinaEjercicio.ejercicio
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
          const Text('Editar series',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera de columnas
              const Padding(
                padding: EdgeInsets.only(left: 28, bottom: 6),
                child: Row(children: [
                  Expanded(child: Text('Reps',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Peso (kg)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center)),
                  SizedBox(width: 8),
                  SizedBox(width: 48,
                      child: Text('Drop',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center)),
                ]),
              ),

              // Fila por cada serie
              ...List.generate(_ctrls.length, (i) {
                final ctrl = _ctrls[i];
                // StatefulBuilder nos permite hacer setState solo en esta fila
                // sin reconstruir todo el diálogo por lo que lo usamos para las casillas de dropset
                return StatefulBuilder(
                  builder: (context, setRow) => Column(
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
                        Expanded(child: _CampoEdicion(ctrl: ctrl.repsCtr, hint: '10')),
                        const SizedBox(width: 8),
                        Expanded(child: _CampoEdicion(ctrl: ctrl.pesoCtr, hint: 'kg')),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: Checkbox(
                            value: ctrl.dropset,
                            activeColor: const Color(0xFFD32F2F),
                            side: const BorderSide(color: Colors.grey),
                            onChanged: (v) {
                              setRow(() {
                                ctrl.dropset = v ?? false;
                                // Si desmarcamos, limpiamos y liberamos los controladores de dropsets
                                if (!ctrl.dropset) {
                                  for (final d in ctrl.dropsetCtrls) {
                                    d.dispose();
                                  }
                                  ctrl.dropsetCtrls.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ]),

                      // Sección de dropsets, solo visible si el checkbox está marcado
                      if (ctrl.dropset) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 6, bottom: 4),
                          child: Row(children: [
                            const Icon(Icons.arrow_downward,
                                color: Color(0xFFD32F2F), size: 13),
                            const SizedBox(width: 4),
                            const Text('Dropsets',
                                style: TextStyle(
                                    color: Color(0xFFD32F2F), fontSize: 12)),
                            const Spacer(),
                            // Botón para añadir un dropset nuevo
                            GestureDetector(
                              onTap: () => setRow(() =>
                                  ctrl.dropsetCtrls.add(TextEditingController())),
                              child: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFFD32F2F), size: 18),
                            ),
                          ]),
                        ),
                        ...List.generate(ctrl.dropsetCtrls.length, (di) =>
                          Padding(
                            padding: const EdgeInsets.only(left: 28, bottom: 4),
                            child: Row(children: [
                              Text('Drop ${di + 1}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: _CampoEdicion(
                                    ctrl: ctrl.dropsetCtrls[di], hint: 'kg'),
                              ),
                              const SizedBox(width: 8),
                              // Elimina este dropset y libera su controlador
                              GestureDetector(
                                onTap: () => setRow(() {
                                  ctrl.dropsetCtrls[di].dispose();
                                  ctrl.dropsetCtrls.removeAt(di);
                                }),
                                child: const Icon(Icons.close,
                                    color: Colors.grey, size: 14),
                              ),
                            ]),
                          ),
                        ),
                      ],
                      if (i < _ctrls.length - 1)
                        const Divider(color: Color(0xFF333333), height: 16),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _guardar,
          child: const Text('Guardar',
              style: TextStyle(color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}


// Campo de texto
class _CampoEdicion extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _CampoEdicion({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12),
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


// Clase auxiliar que agrupa los TextEditingController de una sola serie.
// Centraliza la creación y el dispose de todos los controladores de una fila.
class _SerieEditCtrl {
  final TextEditingController repsCtr;
  final TextEditingController pesoCtr;
  bool dropset;
  List<TextEditingController> dropsetCtrls;

  _SerieEditCtrl({
    required String reps,
    required String peso,
    required this.dropset,
    required List<String> dropsets,
  })  : repsCtr = TextEditingController(text: reps),
        pesoCtr = TextEditingController(text: peso),
        // Creamos un controlador por cada valor de dropset existente
        dropsetCtrls =
            dropsets.map((d) => TextEditingController(text: d)).toList();

  // Libera todos los controladores de esta serie de una vez
  void dispose() {
    repsCtr.dispose();
    pesoCtr.dispose();
    for (final d in dropsetCtrls) {
      d.dispose();
    }
  }
}