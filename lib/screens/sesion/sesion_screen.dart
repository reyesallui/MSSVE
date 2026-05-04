import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mssve/auth/auth_bloc.dart';
import 'package:mssve/rutina/rutina_bloc.dart';
import 'package:mssve/sesion/sesion_bloc.dart';
import 'package:mssve/widgets/app_drawer.dart';
import 'package:mssve/models/ejercicio.dart';
import 'package:mssve/models/rutina_ejercicio.dart';
import 'package:mssve/widgets/sesion_ejercicio_card.dart';

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
                    onAnadir: (idEjercicio, series) => sesionBloc.add(
                      SesionAnadirEjercicioEvent(
                          idEjercicio: idEjercicio,
                          seriesRealizadas: series)),
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
                            onGuardar: (series) => context
                                .read<SesionBloc>()
                                .add(SesionModificarEjercicioEvent(
                                  id: se.id,
                                  seriesRealizadas: series,
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

//  Sheet añadir ejercicio 

class _AddEjercicioSesionSheet extends StatefulWidget {
  final void Function(int idEjercicio, List<SerieDetalle> series) onAnadir;
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
    for (final s in _series) s.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_ejercicioSeleccionado == null) return;

    List<SerieDetalle> series = [];

    if (_ejercicioSeleccionado!.esCardio) {
      final minutos = int.tryParse(_duracionCtrl.text.trim()) ?? 0;
      if (minutos > 0) series = [SerieDetalle(reps: minutos)];
    } else {
      final tieneRepsCero = _series.any((s) {
        final val = int.tryParse(s.repsCtr.text.trim());
        return val == null || val <= 0;
      });
      if (tieneRepsCero) {
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
        return;
      }

      series = _series
          .map((s) => SerieDetalle(
                reps: int.tryParse(s.repsCtr.text.trim()) ?? 0,
                peso: double.tryParse(s.pesoCtr.text),
              ))
          .toList();
    }

    widget.onAnadir(_ejercicioSeleccionado!.id, series);
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
              onChanged: (v) => context.read<RutinaBloc>().add(
                  RutinaBuscarEjerciciosEvent(
                      search: v, idUsuario: widget.idUsuario)),
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
                padding: const EdgeInsets.only(left: 32, bottom: 4),
                child: Row(children: [
                  Expanded(child: Text('rutina.reps'.tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('rutina.weight_kg'.tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center)),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_series.length, (i) {
                      final s = _series[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(
                            width: 24,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _CampoSesion(ctrl: s.repsCtr, hint: '10')),
                          const SizedBox(width: 8),
                          Expanded(child: _CampoSesion(ctrl: s.pesoCtr, hint: 'kg')),
                          const SizedBox(width: 8),
                          if (_series.length > 1)
                            GestureDetector(
                              onTap: () => setState(() {
                                s.dispose();
                                _series.removeAt(i);
                              }),
                              child: const Icon(Icons.close,
                                  color: Colors.grey, size: 16),
                            )
                          else
                            const SizedBox(width: 16),
                        ]),
                      );
                    }),
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

//  Widgets auxiliares 

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

  void dispose() {
    repsCtr.dispose();
    pesoCtr.dispose();
  }
}