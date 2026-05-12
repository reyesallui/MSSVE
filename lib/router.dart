import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/BLoC/home/home_bloc.dart';
import 'package:mssve/BLoC/nutricion/nutricion_bloc.dart';
import 'package:mssve/BLoC/perfil/perfil_bloc.dart';
import 'package:mssve/BLoC/rutina/rutina_bloc.dart';
import 'package:mssve/BLoC/sesion/sesion_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/nutricion/nutricion_screen.dart';
import 'screens/perfil/perfil_screen.dart';
import 'screens/rutina/rutina_screen.dart';
import 'screens/sesion/historial_screen.dart';
import 'screens/sesion/sesion_screen.dart';
import 'service_locator.dart';


// Configuracion centralizada de rutas con GoRouter. Protege rutas segun estado de autenticacion
class AppRouter {
  AppRouter._();

  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/login',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
// Refresca el router cuando cambia el estado de autenticacion
// Redirige al login si no hay sesion, o al home si ya esta autenticado
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthPage = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        if (authState is AuthLoading || authState is AuthInitial) return null;
        if (authState is AuthUnauthenticated || authState is AuthFailure) {
          return isAuthPage ? null : '/login';
        }
        if (authState is AuthSuccess && isAuthPage) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        GoRoute(
          path: '/home',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<HomeBloc>(), child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/nutricion',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<NutricionBloc>(), child: const NutricionScreen(),
          ),
        ),
        GoRoute(
          path: '/rutina',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<RutinaBloc>(), child: const RutinaScreen(),
          ),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<PerfilBloc>(), child: const PerfilScreen(),
          ),
        ),
        GoRoute(
          path: '/historial',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<SesionBloc>()),
              BlocProvider(create: (_) => sl<RutinaBloc>()),
            ],
            child: const HistorialScreen(),
          ),
        ),
        GoRoute(
          path: '/sesion',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<SesionBloc>()),
              BlocProvider(create: (_) => sl<RutinaBloc>()),
            ],
            child: const SesionScreen(),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Text('Ruta no encontrada: ${state.uri}',
              style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}


// Convierte un Stream en ChangeNotifier para que GoRouter sepa cuando recalcular rutas
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() { _subscription.cancel(); super.dispose(); }
}