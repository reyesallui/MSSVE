import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/service_locator.dart';
import 'package:mssve/services/database_service.dart';
import 'package:mssve/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await setupServiceLocator();
  await sl<DatabaseService>().connect();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('es'), Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      child: const MssveApp(),
    ),
  );
}

//Parte del codigo
class MssveApp extends StatelessWidget {
  const MssveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckSessionEvent()),
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'MSSVE',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: sl<GoRouter>(),
          );
        },
      ),
    );
  }
}
