import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/BLoC/rutina/rutina_bloc.dart';
import 'package:mssve/BLoC/sesion/sesion_bloc.dart';
import 'package:mssve/widgets/app_drawer.dart';
import 'package:mssve/models/ejercicio.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/widgets/sesion_ejercicio_card.dart';


const _maxReps = 999;
const _maxMinutos = 999;

// Pantalla de sesion de entrenamiento activa con registro en vivo
class SesionScreen extends StatefulWidget {
  const SesionScreen({super.key});

  @override
  State<SesionScreen> createState() => _SesionScreenState();
}

class _SesionScreenState extends State<SesionScreen> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  
  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final authState = context.read<AuthBloc>().state;
    final idUsuario = authState is AuthSuccess ? authState.usuario.id : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) return AppDrawer(usuario: state.usuario);
          return const SizedBox();
        },
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: Text('sesion.title'.tr(),
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'drawer.home'.tr(),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),

      
      
      
      floatingActionButton: BlocBuilder<SesionBloc, SesionState>(
        buildWhen: (prev, curr) => true,
        builder: (context, state) {
          if (state is! SesionLoaded || state.sesionActiva == null) {
            return const SizedBox();
          }
          return FloatingActionButton(
            backgroundColor: const Color(0xFFD32F2F),
            onPressed: () {
              final sesionBloc = context.read<SesionBloc>();
              final rutinaBloc = context.read<RutinaBloc>();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: rutinaBloc,
                    child: _AddEjercicioSesionSheet(
                      onAnadir: (idEjercicio, series, duracionMinutos) => sesionBloc.add(
                        SesionAnadirEjercicioEvent(
                            idEjercicio: idEjercicio,
                            seriesRealizadas: series,
                            duracionMinutos: duracionMinutos)),
                      idUsuario: idUsuario,
                    ),
                  ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),

      
      
      
      body: BlocBuilder<SesionBloc, SesionState>(
        buildWhen: (prev, curr) => true,
        builder: (context, state) {
          if (state is SesionLoading || state is SesionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SesionError) {
            return Center(
              child: Text(state.message.tr(),
                  style: const TextStyle(color: Colors.grey)),
            );
          }
          if (state is SesionLoaded && state.sesionActiva != null) {
            final sesion = state.sesionActiva!;
            return Column(children: [

              
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF0F0F0F),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    
                    onPressed: () {
                      context
                          .read<SesionBloc>()
                          .add(SesionCargarHistorialEvent(idUsuario));
                      context.go('/historial');
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sesion.nombreRutina,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(
                          DateFormat('EEEE d MMM',
                                  context.locale.toString())
                              .format(sesion.fecha),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              
              Expanded(
                child: sesion.ejercicios.isEmpty
                    ? Center(
                        child: Text('sesion.no_exercises'.tr(),
                            style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sesion.ejercicios.length,
                        itemBuilder: (context, index) {
                          final se = sesion.ejercicios[index];
                          return SesionEjercicioCard(
                            sesionEjercicio: se,
                            onGuardar: (series, duracionMinutos) => context
                                .read<SesionBloc>()
                                .add(SesionModificarEjercicioEvent(
                                  id: se.id,
                                  seriesRealizadas: series,
                                  duracionMinutos: duracionMinutos,
                                )),
                            onEliminar: () => context
                                .read<SesionBloc>()
                                .add(SesionEliminarEjercicioEvent(
                                    id: se.id)),
                          );
                        },
                      ),
              ),
            ]);
          }
          return const SizedBox();
        },
      ),
    );
  }
}



class _AddEjercicioSesionSheet extends StatefulWidget {
  final void Function(int idEjercicio, List<SerieDetalle> series, int? duracionMinutos) onAnadir;
  final int idUsuario;
  const _AddEjercicioSesionSheet(
      {required this.onAnadir, required this.idUsuario});

  @override
  State<_AddEjercicioSesionSheet> createState() =>
      _AddEjercicioSesionSheetState();
}

class _AddEjercicioSesionSheetState
    extends State<_AddEjercicioSesionSheet> {
  final _searchCtrl   = TextEditingController();
  final _duracionCtrl = TextEditingController();
  Ejercicio? _ejercicioSeleccionado;
  String? _grupoMuscular;
  bool _esCardio = false;
  List<_SerieCtrlSesion> _series = [];

  @override
  void initState() {
    super.initState();
    _series = List.generate(3, (_) => _SerieCtrlSesion());
    
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
      }
    }
    return true;
  }

  void _confirmar() {
    if (!_validar()) return;
    if (_ejercicioSeleccionado == null) return;

    if (_ejercicioSeleccionado!.esCardio) {
      final minutos = int.tryParse(_duracionCtrl.text) ?? 0;
      widget.onAnadir(
          _ejercicioSeleccionado!.id, const [], minutos > 0 ? minutos : null);
    } else {
      final series = _series.map((s) {
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
      widget.onAnadir(_ejercicioSeleccionado!.id, series, null);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),

          
          if (_ejercicioSeleccionado == null) ...[
            Text('sesion.add_exercise'.tr(),
                style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'rutina.search_exercise'.tr(),
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) {
                setState(() {
                  _grupoMuscular = null;
                  _esCardio = false;
                });
                context.read<RutinaBloc>().add(
                    RutinaBuscarEjerciciosEvent(
                        search: v, idUsuario: widget.idUsuario));
              },
            ),
            const SizedBox(height: 8),
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
            Expanded(
              child: BlocBuilder<RutinaBloc, RutinaState>(
                buildWhen: (prev, curr) => true,
                builder: (context, state) {
                  if (state is RutinaInitial || state is RutinaLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is! RutinaLoaded) return const SizedBox();
                  final resultados = state.resultadosBusqueda;
                  return resultados.isEmpty
                      ? Center(
                          child: Text(
                            _searchCtrl.text.isEmpty
                                ? 'rutina.search_exercise'.tr()
                                : 'nutricion.no_results'.tr(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: resultados.length,
                          itemBuilder: (context, i) {
                            final ej = resultados[i];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                ej.esCardio
                                    ? Icons.directions_run_outlined
                                    : Icons.fitness_center_outlined,
                                color: const Color(0xFFD32F2F),
                              ),
                              title: Text(
                                ej.nombrePara(context.locale.languageCode),
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: ej.grupoMuscular != null
                                  ? Text(ej.grupoMuscular!,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12))
                                  : null,
                              onTap: () => setState(
                                  () => _ejercicioSeleccionado = ej),
                            );
                          },
                        );
                },
              ),
            ),

          
          ] else ...[
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
              TextField(
                controller: _duracionCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'rutina.duration_min'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_series.length, (i) =>
                      _SerieRowSesion(
                        numero: i + 1,
                        ctrl: _series[i],
                        onRemove: _series.length > 1
                            ? () => setState(() {
                                _series[i].dispose();
                                _series.removeAt(i);
                              })
                            : null,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _series.add(_SerieCtrlSesion())),
                icon: const Icon(Icons.add,
                    color: Color(0xFFD32F2F), size: 18),
                label: Text('rutina.add_set'.tr(),
                    style: const TextStyle(color: Color(0xFFD32F2F))),
              ),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _confirmar,
                child: Text('common.add'.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class _SerieRowSesion extends StatelessWidget {
  final int numero;
  final _SerieCtrlSesion ctrl;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _SerieRowSesion({
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
                  style: TextStyle(color: Color(0xFFD32F2F), fontSize: 12)),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: ctrl.dropsetCtrls[di],
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
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
                child: const Icon(Icons.close, color: Colors.grey, size: 14),
              ),
            ]),
          )),
        ],

        const Divider(color: Color(0xFF222222), height: 12),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    filled: true,
    fillColor: const Color(0xFF0A0A0A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide.none,
    ),
  );
}


class _CampoSesion extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _CampoSesion({required this.ctrl, required this.hint});

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


class _SerieCtrlSesion {
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