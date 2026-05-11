import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/BLoC/home/home_bloc.dart';
import 'package:mssve/models/usuario.dart';
import 'package:mssve/widgets/app_drawer.dart';
import 'package:mssve/widgets/calorie_progress_card.dart';
import 'package:mssve/widgets/macro_progress_card.dart';
import 'package:mssve/widgets/workout_summary_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _cargarDatos(); // Cargo los datos nada más abrir la pantalla
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies se ejecuta cuando algo del contexto del que depende este widget cambia,
    // por ejemplo cuando el usuario cambia el idioma de la app
    // A diferencia de initState, aquí sí puedo acceder de forma segura al contexto heredado como el locale
    // Llamo a setState() vacío para forzar que el widget se reconstruya entero,
    // así la fecha, el saludo y todos los textos traducidos se actualizan al instante
    setState(() {});
  }


  void _cargarDatos() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<HomeBloc>().add(HomeLoadEvent(
        idUsuario: authState.usuario.id,
        fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()), // Fecha de hoy formateada para la API
      ));
    }
  }


  // BUILD
  @override
  Widget build(BuildContext context) {
    // Leer context.locale suscribe este widget al locale
    // cuando el usuario cambie de idioma Flutter reconstruye este widget automáticamente
    final locale = context.locale;

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
        title: Text('drawer.home'.tr(),
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hay error muestro el mensaje y un botón para reintentar
          if (state is HomeError) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message.replaceAll('Exception: ', '').tr(),
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _cargarDatos,
                  child: Text('common.retry'.tr(),
                      style: const TextStyle(color: Color(0xFFD32F2F))),
                ),
              ],
            ));
          }
          if (state is HomeLoaded) {
            final registro  = state.registroDiario;
            final macros    = registro.macrosTotales;
            final authState = context.read<AuthBloc>().state;
            Usuario? usuario;
            if (authState is AuthSuccess) usuario = authState.usuario;

            // Si el gasto energético del usuario es mayor que 0 lo uso, si no pongo 2000 por defecto
            // Este valor viene calculado en la BD con la fórmula de Mifflin-St Jeor
            final kcalObjetivo = (usuario?.gastoEnergeticoTotal ?? 0) > 0
                ? usuario!.gastoEnergeticoTotal
                : 2000.0;

            // Calculo los gramos objetivo de cada macro a partir de las kcal totales
            // Proteínas y carbos tienen 4 kcal por gramo, las grasas tienen 9 kcal por gramo
            final proteinasObj = (kcalObjetivo * 0.30) / 4; // 30% de las kcal para proteínas
            final carbosObj    = (kcalObjetivo * 0.45) / 4; // 45% para carbohidratos
            final grasasObj    = (kcalObjetivo * 0.25) / 9; // 25% para grasas

            // RefreshIndicator permite recargar los datos arrastrando la lista hacia abajo
            return RefreshIndicator(
              onRefresh: () async => _cargarDatos(),
              color: const Color(0xFFD32F2F),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Paso locale.toString() para que la fecha se formatee en el idioma activo
                  // en español sale "lunes, 24 marzo", en inglés "Monday, March 24"
                  Text(
                    DateFormat('EEEE, d MMMM', locale.toString())
                        .format(DateTime.now()),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Si hay usuario muestro su nombre en el saludo, si no un saludo genérico
                    usuario != null
                        ? 'home.welcome'.tr(args: [usuario.nombre])
                        : 'home.welcome_generic'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Círculo de progreso de calorías consumidas frente al objetivo
                  CalorieProgressCard(
                    kcalConsumidas: registro.kcalConsumidas,
                    kcalObjetivo: kcalObjetivo,
                  ),
                  const SizedBox(height: 12),
                  // Barras de progreso de proteínas, carbos y grasas
                  MacroProgressCard(
                    proteinas: macros['proteinas'] ?? 0,
                    carbohidratos: macros['carbohidratos'] ?? 0,
                    grasas: macros['grasas'] ?? 0,
                    proteinasObjetivo: proteinasObj,
                    carbohidratosObjetivo: carbosObj,
                    grasasObjetivo: grasasObj,
                  ),
                  const SizedBox(height: 12),
                  // Botón de acceso rápido para ir a registrar una comida
                  _AccesoRapido(
                    icon: Icons.restaurant_menu_outlined,
                    label: 'home.log_meal'.tr(),
                    onTap: () => context.go('/nutricion'),
                  ),
                  const SizedBox(height: 12),
                  // Resumen de las rutinas recientes con botón para ver todas
                  WorkoutSummaryCard(
                    rutinas: state.rutinas,
                    onVerTodas: () => context.go('/rutina'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}


// ACCESO RAPIDO
// Botón genérico con icono, texto y flecha a la derecha para navegar rápido a otra pantalla
class _AccesoRapido extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
 
  const _AccesoRapido({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // InkWell añade el efecto ripple(simula una onda al hacer) al pulsar, más visual que un GestureDetector simple
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFD32F2F).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD32F2F)),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
            const Spacer(), // Empuja la flecha hacia el extremo derecho
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFFD32F2F), size: 16),
          ],
        ),
      ),
    );
  }
}