import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';

import 'package:mssve/models/rutina.dart';
import 'package:mssve/BLoC/rutina/rutina_bloc.dart';
import 'package:mssve/widgets/add_exercise_bottom_sheet.dart';
import 'package:mssve/widgets/app_drawer.dart';
import 'package:mssve/widgets/exercise_card.dart';

// Pantalla de rutinas — lista las rutinas del usuario y al pulsar una muestra su detalle
class RutinaScreen extends StatefulWidget {
  const RutinaScreen({super.key});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {

  @override
  void initState() {
    super.initState();
    _cargarRutinas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fuerza rebuild al cambiar idioma
    setState(() {});
  }

  void _cargarRutinas() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<RutinaBloc>().add(RutinaLoadEvent(authState.usuario.id));
    }
  }

  // /CREAR RUTINA/
  Future<void> _mostrarCrearRutina() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    final nombreCtrl = TextEditingController();
    final notasCtrl  = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('rutina.new_routine'.tr(),
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: 'rutina.routine_name'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 12),
          TextField(
              controller: notasCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: 'rutina.notes'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey))),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (nombreCtrl.text.trim().isEmpty) return;
              context.read<RutinaBloc>().add(RutinaCrearEvent(
                    idUsuario: authState.usuario.id,
                    nombre: nombreCtrl.text.trim(),
                    fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    notas: notasCtrl.text.trim().isEmpty
                        ? null
                        : notasCtrl.text.trim(),
                  ));
              Navigator.pop(ctx);
            },
            child: Text('common.create'.tr(),
                style: const TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  // /CREAR EJERCICIO PERSONALIZADO/
  // StatefulBuilder permite hacer setState dentro del AlertDialog
  // sin tener que convertirlo en un widget propio
  Future<void> _mostrarCrearEjercicio(
      BuildContext context, int idUsuario) async {
    final nombreCtrl = TextEditingController();
    bool esCardio = false;
    String? grupoMuscular;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('rutina.create_custom'.tr(),
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'common.name'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF333333))),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD32F2F))),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('rutina.cardio'.tr(),
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Switch(
                  value: esCardio,
                  activeColor: const Color(0xFFD32F2F),
                  onChanged: (v) => setStateDialog(() => esCardio = v),
                ),
              ]),
              // El grupo muscular solo aparece si NO es cardio
              if (!esCardio) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: grupoMuscular,
                  hint: Text('rutina.muscle_group'.tr(),
                      style: const TextStyle(color: Colors.grey)),
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF333333))),
                  ),
                  items: ['Pecho', 'Espalda', 'Pierna', 'Biceps',
                          'Triceps', 'Hombro', 'Abdomen']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => grupoMuscular = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr(),
                  style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                context.read<RutinaBloc>().add(RutinaCrearEjercicioEvent(
                      idUsuario: idUsuario,
                      nombre: nombreCtrl.text.trim(),
                      esCardio: esCardio,
                      grupoMuscular: esCardio ? null : grupoMuscular,
                    ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('rutina.exercise_created'
                      .tr(args: [nombreCtrl.text.trim()])),
                  backgroundColor: const Color(0xFF2E7D32),
                ));
              },
              child: Text('common.create'.tr(),
                  style: const TextStyle(color: Color(0xFFD32F2F))),
            ),
          ],
        ),
      ),
    );
  }

  // /CONFIRMAR ELIMINAR/
  void _confirmarEliminar(BuildContext context, Rutina rutina) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('rutina.delete_routine'.tr(),
            style: const TextStyle(color: Colors.white)),
        content: Text('rutina.confirm_delete'.tr(args: [rutina.nombre]),
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<RutinaBloc>().add(RutinaEliminarEvent(
                  id: rutina.id, idUsuario: authState.usuario.id));
              Navigator.pop(ctx);
            },
            child: Text('common.delete'.tr(),
                style: const TextStyle(color: Color(0xFFCF6679))),
          ),
        ],
      ),
    );
  }

  // /BUILD/
  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

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
        title: Text('drawer.workout'.tr(),
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'drawer.home'.tr(),
            onPressed: () => context.go('/home'),
          ),
          // Botón de crear ejercicio — solo visible cuando hay rutina activa
          BlocBuilder<RutinaBloc, RutinaState>(
            builder: (context, state) {
              if (state is! RutinaLoaded || state.rutinaActiva == null) {
                return const SizedBox();
              }
              // Cast explícito necesario porque Dart solo sabe que es AuthState
              final idUsuario =
                  context.read<AuthBloc>().state is AuthSuccess
                      ? (context.read<AuthBloc>().state as AuthSuccess)
                          .usuario
                          .id
                      : 0;
              return IconButton(
                icon: const Icon(Icons.fitness_center,
                    color: Color(0xFFD32F2F)),
                tooltip: 'rutina.create_custom'.tr(),
                onPressed: () =>
                    _mostrarCrearEjercicio(context, idUsuario),
              );
            },
          ),
        ],
      ),
      // FAB: añade ejercicio si hay rutina activa, crea rutina si no hay ninguna
      // _mostrarCrearRutina sin () = referencia a la función, no llamada inmediata
      floatingActionButton: BlocBuilder<RutinaBloc, RutinaState>(
        builder: (context, state) {
          final rutinaActiva =
              state is RutinaLoaded ? state.rutinaActiva : null;
          final idUsuario =
              context.read<AuthBloc>().state is AuthSuccess
                  ? (context.read<AuthBloc>().state as AuthSuccess).usuario.id
                  : 0;

          return FloatingActionButton(
            backgroundColor: const Color(0xFFD32F2F),
            onPressed: rutinaActiva != null
                ? () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      // BlocProvider.value pasa el bloc existente al sheet
                      // sin crear una instancia nueva
                      builder: (_) => BlocProvider.value(
                        value: context.read<RutinaBloc>(),
                        child: AddExerciseBottomSheet(
                          idRutina: rutinaActiva.id,
                          idUsuario: idUsuario,
                        ),
                      ),
                    )
                : _mostrarCrearRutina,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),

      // /BODY/
      body: BlocBuilder<RutinaBloc, RutinaState>(
        builder: (context, state) {
          if (state is RutinaLoading || state is RutinaInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RutinaError) {
            return Center(
                child: Text(state.message.tr(),
                    style: const TextStyle(color: Colors.grey)));
          }
          if (state is RutinaLoaded) {
            if (state.rutinaActiva != null) {
              return _DetalleRutina(rutina: state.rutinaActiva!);
            }
            if (state.rutinas.isEmpty) {
              return Center(
                  child: Text('rutina.no_routines'.tr(),
                      style: const TextStyle(color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.rutinas.length,
              itemBuilder: (context, index) {
                final rutina = state.rutinas[index];
                return _RutinaItem(
                  rutina: rutina,
                  onTap: () => context
                      .read<RutinaBloc>()
                      .add(RutinaSeleccionarEvent(rutina)),
                  onEliminar: () => _confirmarEliminar(context, rutina),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

// /DETALLE DE RUTINA/
// Muestra la cabecera con el nombre y la lista de ejercicios con ExerciseCard.
// Es lo que aparece al pulsar una rutina de la lista.
class _DetalleRutina extends StatelessWidget {
  final Rutina rutina;
  const _DetalleRutina({required this.rutina});

  // Static porque StatelessWidget no puede tener métodos de instancia con contexto
  static Future<void> _mostrarCrearEjercicioDetalle(
      BuildContext context, int idUsuario) async {
    final nombreCtrl = TextEditingController();
    bool esCardio = false;
    String? grupoMuscular;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('rutina.create_custom'.tr(),
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'common.name'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF333333))),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD32F2F))),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('rutina.cardio'.tr(),
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Switch(
                  value: esCardio,
                  activeColor: const Color(0xFFD32F2F),
                  onChanged: (v) => setStateDialog(() => esCardio = v),
                ),
              ]),
              if (!esCardio) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: grupoMuscular,
                  hint: Text('rutina.muscle_group'.tr(),
                      style: const TextStyle(color: Colors.grey)),
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF333333))),
                  ),
                  items: ['Pecho', 'Espalda', 'Pierna', 'Biceps',
                          'Triceps', 'Hombro', 'Abdomen']
                      .map((g) =>
                          DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => grupoMuscular = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr(),
                  style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isEmpty) return;
                context.read<RutinaBloc>().add(RutinaCrearEjercicioEvent(
                      idUsuario: idUsuario,
                      nombre: nombreCtrl.text.trim(),
                      esCardio: esCardio,
                      grupoMuscular: esCardio ? null : grupoMuscular,
                    ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('rutina.exercise_created'
                      .tr(args: [nombreCtrl.text.trim()])),
                  backgroundColor: const Color(0xFF2E7D32),
                ));
              },
              child: Text('common.create'.tr(),
                  style: const TextStyle(color: Color(0xFFD32F2F))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final authState = context.read<AuthBloc>().state;
    final idUsuario =
        authState is AuthSuccess ? authState.usuario.id : 0;

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF0F0F0F),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            // Recargar rutinas deselecciona la activa automáticamente
            onPressed: () => context
                .read<RutinaBloc>()
                .add(RutinaLoadEvent(idUsuario)),
          ),
          Expanded(
              child: Text(rutina.nombre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold))),
        ]),
      ),
      Expanded(
        child: rutina.ejercicios.isEmpty
            ? Center(
                child: Text('rutina.no_exercises'.tr(),
                    style: const TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rutina.ejercicios.length,
                itemBuilder: (context, index) {
                  final re = rutina.ejercicios[index];
                  return ExerciseCard(
                    rutinaEjercicio: re,
                    onEliminar: () => context.read<RutinaBloc>().add(
                          RutinaEliminarEjercicioEvent(
                              id: re.id, idUsuario: idUsuario),
                        ),
                    onGuardarDetalle: (nuevasSeries) {
                      context.read<RutinaBloc>().add(
                            RutinaModificarEjercicioEvent(
                              id: re.id,
                              idUsuario: idUsuario,
                              series: nuevasSeries.length,
                              repeticiones: nuevasSeries.isNotEmpty
                                  ? nuevasSeries.first.reps
                                  : null,
                              pesoKg: nuevasSeries.isNotEmpty
                                  ? nuevasSeries.first.peso
                                  : null,
                              seriesDetalle: nuevasSeries,
                            ),
                          );
                    },
                  );
                },
              ),
      ),
    ]);
  }
}

// /ITEM DE RUTINA/
// Fila de la lista principal — al pulsar navega al detalle
class _RutinaItem extends StatelessWidget {
  final Rutina rutina;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const _RutinaItem({
    required this.rutina,
    required this.onTap,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        tileColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center_outlined,
              color: Color(0xFFD32F2F)),
        ),
        title: Text(rutina.nombre,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(
          'rutina.exercises_count'.tr(args: [
            rutina.ejercicios.length.toString(),
            DateFormat('dd/MM/yyyy').format(rutina.fecha),
          ]),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFCF6679)),
          onPressed: onEliminar,
        ),
      ),
    );
  }
}