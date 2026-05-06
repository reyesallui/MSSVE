import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/models/sesion_entrenamiento.dart';
import 'package:mssve/BLoC/rutina/rutina_bloc.dart';
import 'package:mssve/sesion/sesion_bloc.dart';
import 'package:mssve/widgets/app_drawer.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  DateTime _fechaSeleccionada = DateTime.now();

  DateTime get _fechaNorm => DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day);

  bool get _esHoy {
    final hoy = DateTime.now();
    return _fechaSeleccionada.year == hoy.year &&
        _fechaSeleccionada.month == hoy.month &&
        _fechaSeleccionada.day == hoy.day;
  }

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  void _cargarHistorial() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<SesionBloc>().add(
          SesionCargarHistorialEvent(authState.usuario.id));
    }
  }

  void _diaAnterior() => setState(() =>
      _fechaSeleccionada =
          _fechaSeleccionada.subtract(const Duration(days: 1)));

  void _diaSiguiente() => setState(() =>
      _fechaSeleccionada =
          _fechaSeleccionada.add(const Duration(days: 1)));

  void _confirmarEliminar(BuildContext context, int idSesion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('sesion.delete_session'.tr(),
            style: const TextStyle(color: Colors.white)),
        content: Text('sesion.confirm_delete'.tr(),
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<SesionBloc>()
                  .add(SesionEliminarEvent(id: idSesion));
              Navigator.pop(ctx);
            },
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFCF6679))),
          ),
        ],
      ),
    );
  }

  void _abrirCrearSesion(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    context.read<RutinaBloc>().add(RutinaLoadEvent(authState.usuario.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<RutinaBloc>()),
          BlocProvider.value(value: context.read<SesionBloc>()),
        ],
        child: _SelectorRutinaSheet(
          idUsuario: authState.usuario.id,
          fecha: _fechaSeleccionada,
        ),
      ),
    );
  }

  void _abrirProgresion(
      BuildContext context, List<SesionEntrenamiento> historial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProgresionSheet(historial: historial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    // BlocListener detecta cuando sesionActiva pasa de null a tener valor
    // y navega a /sesion — así evitamos navegar antes de que el bloc procese el evento
    return BlocListener<SesionBloc, SesionState>(
      listenWhen: (prev, curr) {
        if (curr is! SesionLoaded) return false;
        final prevActiva =
            prev is SesionLoaded ? prev.sesionActiva : null;
        return prevActiva == null && curr.sesionActiva != null;
      },
      listener: (context, state) => context.go('/sesion'),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        drawer: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) return AppDrawer(usuario: state.usuario);
            return const SizedBox();
          },
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          title: Text('sesion.history'.tr(),
              style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _diaAnterior,
                  ),
                  Text(
                    DateFormat('EEE d MMM', context.locale.toString())
                        .format(_fechaSeleccionada),
                    style: TextStyle(
                      color: _esHoy
                          ? const Color(0xFFD32F2F)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _diaSiguiente,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            BlocBuilder<SesionBloc, SesionState>(
              builder: (context, state) {
                if (state is! SesionLoaded || state.historial.isEmpty) {
                  return const SizedBox();
                }
                return IconButton(
                  icon: const Icon(Icons.show_chart),
                  tooltip: 'sesion.progression'.tr(),
                  onPressed: () =>
                      _abrirProgresion(context, state.historial),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'drawer.home'.tr(),
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFD32F2F),
          tooltip: 'sesion.start_session'.tr(),
          onPressed: () => _abrirCrearSesion(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocBuilder<SesionBloc, SesionState>(
          buildWhen: (prev, curr) => true,
          builder: (context, state) {
            if (state is SesionLoading || state is SesionInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SesionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message.tr(),
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _cargarHistorial,
                      child: Text('common.retry'.tr(),
                          style: const TextStyle(
                              color: Color(0xFFD32F2F))),
                    ),
                  ],
                ),
              );
            }
            if (state is SesionLoaded) {
              final sesionesDelDia = state.historial.where((s) {
                final f =
                    DateTime(s.fecha.year, s.fecha.month, s.fecha.day);
                return f == _fechaNorm;
              }).toList();

              if (sesionesDelDia.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center_outlined,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text('sesion.no_sessions'.tr(),
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('sesion.no_sessions_hint'.tr(),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sesionesDelDia.length,
                itemBuilder: (context, index) {
                  final sesion = sesionesDelDia[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      // Al pulsar seleccionamos la sesión — el BlocListener
                      // detecta el cambio y navega a /sesion automáticamente
                      onTap: () => context
                          .read<SesionBloc>()
                          .add(SesionSeleccionarEvent(sesion)),
                      tileColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFD32F2F).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fitness_center_outlined,
                            color: Color(0xFFD32F2F)),
                      ),
                      title: Text(sesion.nombreRutina,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE d MMMM yyyy',
                                    context.locale.toString())
                                .format(sesion.fecha),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            'sesion.exercises_count'.tr(args: [
                              sesion.ejercicios.length.toString()
                            ]),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFCF6679)),
                        onPressed: () =>
                            _confirmarEliminar(context, sesion.id),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

// Selector de rutina — la fecha viene del historial, sin navegador propio
class _SelectorRutinaSheet extends StatelessWidget {
  final int idUsuario;
  final DateTime fecha;
  const _SelectorRutinaSheet({
    required this.idUsuario,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('sesion.select_routine'.tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        const Divider(color: Color(0xFF333333), height: 1),
        Expanded(
          child: BlocBuilder<RutinaBloc, RutinaState>(
            builder: (context, state) {
              if (state is RutinaLoading || state is RutinaInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is! RutinaLoaded || state.rutinas.isEmpty) {
                return Center(
                  child: Text('rutina.no_routines'.tr(),
                      style: const TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                itemCount: state.rutinas.length,
                itemBuilder: (context, i) {
                  final rutina = state.rutinas[i];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fitness_center_outlined,
                          color: Color(0xFFD32F2F), size: 20),
                    ),
                    title: Text(rutina.nombre,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${rutina.ejercicios.length} ejercicios',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.grey),
                    onTap: () {
                      final fechaStr =
                          DateFormat('yyyy-MM-dd').format(fecha);
                      context.read<SesionBloc>().add(SesionCrearEvent(
                            idRutina: rutina.id,
                            idUsuario: idUsuario,
                            fecha: fechaStr,
                            ejerciciosPlantilla: rutina.ejercicios,
                          ));
                      Navigator.pop(context);
                      // La navegación la gestiona el BlocListener en HistorialScreen
                    },
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// Gráfico de progresión — dos pasos: lista de ejercicios → gráfico
class _ProgresionSheet extends StatefulWidget {
  final List<SesionEntrenamiento> historial;
  const _ProgresionSheet({required this.historial});

  @override
  State<_ProgresionSheet> createState() => _ProgresionSheetState();
}

class _ProgresionSheetState extends State<_ProgresionSheet> {
  String? _ejercicioSeleccionadoId;
  String? _ejercicioSeleccionadoNombre;

  Map<String, String> _ejerciciosUnicos() {
    final Map<String, String> mapa = {};
    for (final sesion in widget.historial) {
      for (final se in sesion.ejercicios) {
        final id = se.idEjercicio.toString();
        if (!mapa.containsKey(id)) {
          mapa[id] = se.ejercicio.nombrePara(context.locale.languageCode);
        }
      }
    }
    return mapa;
  }

  List<_PuntoProgresion> _calcularPuntos(String idEjercicio) {
    final puntos = <_PuntoProgresion>[];
    final sesionesOrdenadas = [...widget.historial]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    for (final sesion in sesionesOrdenadas) {
      for (final se in sesion.ejercicios) {
        if (se.idEjercicio.toString() != idEjercicio) continue;
        if (se.seriesRealizadas.isEmpty) continue;

        if (se.ejercicio.esCardio) {
          final minutos = se.seriesRealizadas.first.reps;
          puntos.add(_PuntoProgresion(
              fecha: sesion.fecha,
              valor: minutos.toDouble(),
              esMinutos: true));
          break;
        }

        final tienePeso =
            se.seriesRealizadas.any((s) => s.peso != null && s.peso! > 0);

        if (tienePeso) {
          final maxPeso = se.seriesRealizadas
              .where((s) => s.peso != null)
              .map((s) => s.peso!)
              .reduce((a, b) => a > b ? a : b);
          puntos.add(_PuntoProgresion(
              fecha: sesion.fecha, valor: maxPeso, esPeso: true));
        } else {
          final maxReps = se.seriesRealizadas
              .map((s) => s.reps)
              .reduce((a, b) => a > b ? a : b);
          puntos.add(_PuntoProgresion(
              fecha: sesion.fecha,
              valor: maxReps.toDouble(),
              esPeso: false));
        }
        break;
      }
    }
    return puntos;
  }

  @override
  Widget build(BuildContext context) {
    final ejercicios = _ejerciciosUnicos();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (_ejercicioSeleccionadoId != null)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() {
                  _ejercicioSeleccionadoId = null;
                  _ejercicioSeleccionadoNombre = null;
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _ejercicioSeleccionadoNombre ??
                    'sesion.select_exercise'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ),
        const Divider(color: Color(0xFF333333), height: 1),
        Expanded(
          child: _ejercicioSeleccionadoId == null
              ? ListView(
                  children: ejercicios.entries.map((e) {
                    return ListTile(
                      title: Text(e.value,
                          style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.grey),
                      onTap: () => setState(() {
                        _ejercicioSeleccionadoId = e.key;
                        _ejercicioSeleccionadoNombre = e.value;
                      }),
                    );
                  }).toList(),
                )
              : _GraficoProgresion(
                  puntos: _calcularPuntos(_ejercicioSeleccionadoId!),
                  nombreEjercicio: _ejercicioSeleccionadoNombre!,
                ),
        ),
      ]),
    );
  }
}

class _GraficoProgresion extends StatelessWidget {
  final List<_PuntoProgresion> puntos;
  final String nombreEjercicio;

  const _GraficoProgresion({
    required this.puntos,
    required this.nombreEjercicio,
  });

  @override
  Widget build(BuildContext context) {
    if (puntos.isEmpty) {
      return Center(
        child: Text('sesion.no_data'.tr(),
            style: const TextStyle(color: Colors.grey)),
      );
    }

    final esPeso    = puntos.first.esPeso;
    final esMinutos = puntos.first.esMinutos;

    final spots = puntos
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.valor))
        .toList();

    final maxY =
        puntos.map((p) => p.valor).reduce((a, b) => a > b ? a : b);
    final minY =
        puntos.map((p) => p.valor).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              esPeso
                  ? 'sesion.max_weight'.tr()
                  : esMinutos
                      ? 'sesion.max_duration'.tr()
                      : 'sesion.max_reps'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: (minY * 0.9).floorToDouble(),
                maxY: (maxY * 1.1).ceilToDouble(),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFF333333), strokeWidth: 1),
                  getDrawingVerticalLine: (_) => const FlLine(
                      color: Color(0xFF333333), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= puntos.length) {
                          return const SizedBox();
                        }
                        return Text(
                          DateFormat('d/M').format(puntos[i].fecha),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFD32F2F),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFFD32F2F),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFD32F2F).withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)}'
                              '${esPeso ? ' kg' : esMinutos ? ' min' : ' reps'}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                esPeso
                    ? 'sesion.max_weight'.tr()
                    : esMinutos
                        ? 'sesion.max_duration'.tr()
                        : 'sesion.max_reps'.tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PuntoProgresion {
  final DateTime fecha;
  final double valor;
  final bool esPeso;
  final bool esMinutos;

  const _PuntoProgresion({
    required this.fecha,
    required this.valor,
    this.esPeso = false,
    this.esMinutos = false,
  });
}