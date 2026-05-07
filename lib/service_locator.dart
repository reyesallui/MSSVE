import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/BLoC/home/home_bloc.dart';
import 'package:mssve/BLoC/nutricion/nutricion_bloc.dart';
import 'package:mssve/BLoC/perfil/perfil_bloc.dart';
import 'package:mssve/BLoC/rutina/rutina_bloc.dart';
import 'package:mssve/sesion/sesion_bloc.dart';
import 'repositories/repository_autenticacion.dart';
import 'repositories/repository_nutricion.dart';
import 'repositories/repository_perfil.dart';
import 'repositories/repository_rutina.dart';
import 'repositories/repository_sesion.dart';
import 'router.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton<StorageService>(() => StorageService());

  sl.registerSingleton<DatabaseService>(DatabaseService());

  sl.registerLazySingleton<RepositoryAutenticacion>(
    () => RepositoryAutenticacion(
      db: sl<DatabaseService>(),
      storageService: sl<StorageService>(),
    ),
  );

  sl.registerLazySingleton<RepositoryNutricion>(
    () => RepositoryNutricion(db: sl<DatabaseService>()),
  );

  sl.registerLazySingleton<RepositoryRutina>(
    () => RepositoryRutina(db: sl<DatabaseService>()),
  );

  sl.registerLazySingleton<RepositoryPerfil>(
    () => RepositoryPerfil(
      db: sl<DatabaseService>(),
      storageService: sl<StorageService>(),
    ),
  );

  sl.registerLazySingleton<RepositorySesion>(
    () => RepositorySesion(db: sl<DatabaseService>()),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(repository: sl<RepositoryAutenticacion>()),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      repositoryNutricion: sl<RepositoryNutricion>(),
      repositoryRutina: sl<RepositoryRutina>(),
      repositoryPerfil: sl<RepositoryPerfil>(),
    ),
  );

  sl.registerFactory<NutricionBloc>(
    () => NutricionBloc(repository: sl<RepositoryNutricion>()),
  );

  sl.registerFactory<RutinaBloc>(
    () => RutinaBloc(repository: sl<RepositoryRutina>()),
  );

  sl.registerFactory<PerfilBloc>(
    () => PerfilBloc(repository: sl<RepositoryPerfil>()),
  );

  // LazySingleton para que /rutina y /sesion compartan la misma instancia
  // y la sesión creada en rutina sea visible en sesion_screen
  sl.registerLazySingleton<SesionBloc>(
    () => SesionBloc(repository: sl<RepositorySesion>()),
  );

  sl.registerLazySingleton<GoRouter>(
    () => AppRouter.router(sl<AuthBloc>()),
  );
}