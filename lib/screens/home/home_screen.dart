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


// Pantalla principal con resumen del dia: kcal, macros, progreso y acceso rapido
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    _cargarDatos(); 
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    
    
    
    
    setState(() {});
  }


  void _cargarDatos() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<HomeBloc>().add(HomeLoadEvent(
        idUsuario: authState.usuario.id,
        fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()), 
      ));
    }
  }


  
  @override
  Widget build(BuildContext context) {
    
    
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

            
            
            final kcalObjetivo = (usuario?.gastoEnergeticoTotal ?? 0) > 0
                ? usuario!.gastoEnergeticoTotal
                : 2000.0;

            
            
            final proteinasObj = (kcalObjetivo * 0.30) / 4; 
            final carbosObj    = (kcalObjetivo * 0.45) / 4; 
            final grasasObj    = (kcalObjetivo * 0.25) / 9; 

            
            return RefreshIndicator(
              onRefresh: () async => _cargarDatos(),
              color: const Color(0xFFD32F2F),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  
                  
                  Text(
                    DateFormat('EEEE, d MMMM', locale.toString())
                        .format(DateTime.now()),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    
                    usuario != null
                        ? 'home.welcome'.tr(args: [usuario.nombre])
                        : 'home.welcome_generic'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  CalorieProgressCard(
                    kcalConsumidas: registro.kcalConsumidas,
                    kcalObjetivo: kcalObjetivo,
                  ),
                  const SizedBox(height: 12),
                  
                  MacroProgressCard(
                    proteinas: macros['proteinas'] ?? 0,
                    carbohidratos: macros['carbohidratos'] ?? 0,
                    grasas: macros['grasas'] ?? 0,
                    proteinasObjetivo: proteinasObj,
                    carbohidratosObjetivo: carbosObj,
                    grasasObjetivo: grasasObj,
                  ),
                  const SizedBox(height: 12),
                  
                  _AccesoRapido(
                    icon: Icons.restaurant_menu_outlined,
                    label: 'home.log_meal'.tr(),
                    onTap: () => context.go('/nutricion'),
                  ),
                  const SizedBox(height: 12),
                  
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
            const Spacer(), 
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFFD32F2F), size: 16),
          ],
        ),
      ),
    );
  }
}