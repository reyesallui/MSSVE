import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mssve/BLoC/rutina/rutina_bloc.dart';
import 'package:mssve/models/ejercicio.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/widgets/custom_text_field.dart';
import 'package:mssve/widgets/primary_button.dart';

const _maxReps = 999;
const _maxMinutos = 999;
const _maxPeso = 999;

// Bottom sheet para buscar y anadir ejercicios con filtros
class AddExerciseBottomSheet extends StatefulWidget {
  final int idRutina;
  final int idUsuario;

  const AddExerciseBottomSheet({
    super.key,
    required this.idRutina,
    required this.idUsuario,
  });

  @override
  State<AddExerciseBottomSheet> createState() =>
      _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState extends State<AddExerciseBottomSheet> {
  final _searchCtrl   = TextEditingController();
  final _duracionCtrl = TextEditingController();
  Ejercicio? _ejercicioSeleccionado;
  String? _grupoMuscular;
  bool _esCardio = false;

  List<_SerieController> _series = [];

  @override
  void initState() {
    super.initState();
    _series = List.generate(3, (_) => _SerieController());
    
    context.read<RutinaBloc>().add(RutinaBuscarEjerciciosEvent(
      search: '',
      idUsuario: widget.idUsuario,
    ));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _duracionCtrl.dispose();
    for (final s in _series) {
      s.dispose();
    }
    super.dispose();
  }

  void _addSerie() {
    setState(() => _series.add(_SerieController()));
  }

  void _removeSerie(int index) {
    if (_series.length <= 1) return;
    setState(() {
      _series[index].dispose();
      _series.removeAt(index);
    });
  }

  bool _validar() {
    if (_ejercicioSeleccionado == null) return false;

    if (_ejercicioSeleccionado!.esCardio) {
      final min = int.tryParse(_duracionCtrl.text);
      if (min != null && (min < 1 || min > _maxMinutos)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La duración debe estar entre 1 y 999 minutos'),
          backgroundColor: Color(0xFFCF6679),
        ));
        return false;
      }
    } else {
      for (final s in _series) {
        final reps = int.tryParse(s.repsCtr.text) ?? 0;
        if (reps < 1 || reps > _maxReps) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Las repeticiones deben estar entre 1 y $_maxReps'),
            backgroundColor: Color(0xFFCF6679),
          ));
          return false;
        }
        final peso = double.tryParse(s.pesoCtr.text);
        if (peso != null && (peso < 0 || peso > _maxPeso)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('El peso debe estar entre 0 y $_maxPeso kg'),
            backgroundColor: Color(0xFFCF6679),
          ));
          return false;
        }
      }
    }
    return true;
  }

  void _confirmar() {
    if (!_validar()) return;

    if (_ejercicioSeleccionado!.esCardio) {
      context.read<RutinaBloc>().add(RutinaAnadirEjercicioEvent(
        idRutina: widget.idRutina,
        idEjercicio: _ejercicioSeleccionado!.id,
        idUsuario: widget.idUsuario,
        duracionMinutos: int.tryParse(_duracionCtrl.text),
        seriesDetalle: const [],
      ));
    } else {
      final detalle = _series.map((s) {
        final dropsets = s.dropsetActivo
            ? s.dropsetCtrls
                .map((c) => double.tryParse(c.text) ?? 0.0)
                .toList()
            : <double>[];

        return SerieDetalle(
          reps: int.tryParse(s.repsCtr.text) ?? 0,
          peso: double.tryParse(s.pesoCtr.text),
          dropset: s.dropsetActivo,
          dropsets: dropsets,
        );
      }).toList();

      context.read<RutinaBloc>().add(RutinaAnadirEjercicioEvent(
        idRutina: widget.idRutina,
        idEjercicio: _ejercicioSeleccionado!.id,
        idUsuario: widget.idUsuario,
        series: _series.length,
        repeticiones: int.tryParse(_series.first.repsCtr.text),
        pesoKg: double.tryParse(_series.first.pesoCtr.text),
        seriesDetalle: detalle,
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),

          if (_ejercicioSeleccionado == null) ...[
            Text('rutina.add_exercise'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _searchCtrl,
              label: 'rutina.search_exercise'.tr(),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              onChanged: (value) {
                setState(() {
                  _grupoMuscular = null;
                  _esCardio = false;
                });
                context.read<RutinaBloc>().add(RutinaBuscarEjerciciosEvent(
                  search: value,
                  idUsuario: widget.idUsuario,
                ));
              },
            ),
            const SizedBox(height: 12),
            BlocBuilder<RutinaBloc, RutinaState>(
              builder: (context, state) {
                if (state is! RutinaLoaded) return const SizedBox();
                final resultados = state.resultadosBusqueda;
                final grupos = resultados
                    .map((e) => e.grupoMuscular)
                    .whereType<String>()
                    .where((g) => g.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                final hayCardio = resultados.any((e) => e.esCardio);
                if (grupos.isEmpty && !hayCardio) return const SizedBox();
                return SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (hayCardio ? 1 : 0) + grupos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (hayCardio && i == 0) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _esCardio = !_esCardio;
                              if (_esCardio) _grupoMuscular = null;
                            });
                            context.read<RutinaBloc>().add(
                              RutinaBuscarEjerciciosEvent(
                                search: _searchCtrl.text,
                                idUsuario: widget.idUsuario,
                                esCardio: _esCardio ? true : null,
                                grupoMuscular: _esCardio ? null : _grupoMuscular,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _esCardio
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Cardio',
                              style: TextStyle(
                                  color: _esCardio ? Colors.white : Colors.grey,
                                  fontSize: 12)),
                          ),
                        );
                      }
                      final idx = hayCardio ? i - 1 : i;
                      final g = grupos[idx];
                      final selected = g == _grupoMuscular;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _grupoMuscular = selected ? null : g;
                            if (_grupoMuscular != null) _esCardio = false;
                          });
                          context.read<RutinaBloc>().add(
                            RutinaBuscarEjerciciosEvent(
                              search: _searchCtrl.text,
                              idUsuario: widget.idUsuario,
                              grupoMuscular: _grupoMuscular,
                              esCardio: _grupoMuscular != null ? null : _esCardio ? true : null,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(g,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.grey,
                                fontSize: 12,
                              )),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            BlocBuilder<RutinaBloc, RutinaState>(
              builder: (context, state) {
                if (state is! RutinaLoaded) return const SizedBox();
                final resultados = state.resultadosBusqueda;
                return SizedBox(
                  height: 200,
                  child: resultados.isEmpty
                      ? Center(child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'rutina.search_exercise'.tr()
                              : 'nutricion.no_results'.tr(),
                          style: const TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: resultados.length,
                          itemBuilder: (context, index) {
                            final e = resultados[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                e.esCardio
                                    ? Icons.directions_run_outlined
                                    : Icons.fitness_center_outlined,
                                color: const Color(0xFFD32F2F),
                              ),
                              title: Text(
                                e.nombrePara(context.locale.languageCode),
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: e.grupoMuscular != null
                                  ? Text(e.grupoMuscular!,
                                      style: const TextStyle(color: Colors.grey))
                                  : null,
                              onTap: () =>
                                  setState(() => _ejercicioSeleccionado = e),
                            );
                          },
                        ),
                );
              },
            ),
          ]

          else ...[
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _ejercicioSeleccionado!.nombrePara(
                        context.locale.languageCode),
                    style: const TextStyle(
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _ejercicioSeleccionado = null),
                child: Text('common.change'.tr(),
                    style: const TextStyle(color: Colors.grey)),
              ),
            ]),
            const SizedBox(height: 16),

            if (_ejercicioSeleccionado!.esCardio)
              CustomTextField(
                controller: _duracionCtrl,
                label: 'rutina.duration_min'.tr(),
                keyboardType: TextInputType.number,
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Row(children: [
                  Expanded(child: Text('rutina.reps'.tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('rutina.weight_kg'.tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  const Text('Drop',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 32),
                ]),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_series.length, (i) =>
                      _SerieRow(
                        numero: i + 1,
                        ctrl: _series[i],
                        onRemove: _series.length > 1
                            ? () => _removeSerie(i)
                            : null,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addSerie,
                icon: const Icon(Icons.add,
                    color: Color(0xFFD32F2F), size: 18),
                label: Text('rutina.add_set'.tr(),
                    style: const TextStyle(color: Color(0xFFD32F2F))),
              ),
            ],

            const SizedBox(height: 16),
            PrimaryButton(label: 'common.add'.tr(), onPressed: _confirmar),
          ],
        ],
      ),
    );
  }
}

class _SerieRow extends StatelessWidget {
  final int numero;
  final _SerieController ctrl;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _SerieRow({
    required this.numero,
    required this.ctrl,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SizedBox(
            width: 28,
            child: Text('$numero',
                style: const TextStyle(
                    color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: ctrl.repsCtr,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: _inputDeco('10'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl.pesoCtr,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: _inputDeco('kg'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Checkbox(
              value: ctrl.dropsetActivo,
              activeColor: const Color(0xFFD32F2F),
              side: const BorderSide(color: Colors.grey),
              onChanged: (v) {
                ctrl.dropsetActivo = v ?? false;
                if (!ctrl.dropsetActivo) ctrl.dropsetCtrls.clear();
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 24,
            child: onRemove != null
                ? GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close,
                        color: Colors.grey, size: 16),
                  )
                : const SizedBox(),
          ),
        ]),

        if (ctrl.dropsetActivo) ...[
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 6, bottom: 4),
            child: Row(children: [
              const Icon(Icons.arrow_downward,
                  color: Color(0xFFD32F2F), size: 14),
              const SizedBox(width: 4),
              const Text('Dropsets',
                  style: TextStyle(
                      color: Color(0xFFD32F2F), fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ctrl.dropsetCtrls.add(TextEditingController());
                  onChanged();
                },
                child: const Icon(Icons.add_circle_outline,
                    color: Color(0xFFD32F2F), size: 18),
              ),
            ]),
          ),
          ...List.generate(ctrl.dropsetCtrls.length, (di) => Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 4),
            child: Row(children: [
              Text('Drop ${di + 1}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: ctrl.dropsetCtrls[di],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                  decoration: _inputDeco('kg'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ctrl.dropsetCtrls[di].dispose();
                  ctrl.dropsetCtrls.removeAt(di);
                  onChanged();
                },
                child: const Icon(Icons.close,
                    color: Colors.grey, size: 14),
              ),
            ]),
          )),
        ],

        const Divider(color: Color(0xFF222222), height: 12),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFF555555), fontSize: 13),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      filled: true,
      fillColor: const Color(0xFF0A0A0A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SerieController {
  final repsCtr = TextEditingController(text: '10');
  final pesoCtr = TextEditingController();
  bool dropsetActivo = false;
  List<TextEditingController> dropsetCtrls = [];

  void dispose() {
    repsCtr.dispose();
    pesoCtr.dispose();
    for (final c in dropsetCtrls) {
      c.dispose();
    }
  }
}