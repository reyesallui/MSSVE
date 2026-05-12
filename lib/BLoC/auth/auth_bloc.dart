import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/usuario.dart';
import '../../repositories/repository_autenticacion.dart';

part 'auth_event.dart';
part 'auth_state.dart';

// BloC de autenticacion: verifica sesion guardada, login con hash, registro con GET y cierre de sesion
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RepositoryAutenticacion _repository;

  AuthBloc({required RepositoryAutenticacion repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthCheckSessionEvent>(_onCheckSession);
// Cadena de mando: cada evento se asigna a su manejador
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthUpdateUserEvent>(_onUpdateUser);
  }

// Recupera sesion desde almacenamiento local (JSON o SQLite) al arrancar la app
  Future<void> _onCheckSession(AuthCheckSessionEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final usuario = await _repository.getUsuarioCacheado();
      if (usuario != null) {
        emit(AuthSuccess(usuario));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

// Autentica comparando password contra hash almacenado; guarda sesion localmente
  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final usuario = await _repository.login(email: event.email, password: event.password);
      emit(AuthSuccess(usuario));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

// Registra usuario: hashea password, calcula GET, inserta en BD y guarda sesion
  Future<void> _onRegister(AuthRegisterEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final usuario = await _repository.register(
        nombre: event.nombre, apellidos: event.apellidos,
        email: event.email, password: event.password,
        peso: event.peso, altura: event.altura,
        genero: event.genero, objetivo: event.objetivo,
        nivelActividad: event.nivelActividad, get: event.get, edad: event.edad,
      );
      emit(AuthSuccess(usuario));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

// Elimina sesion local y vuelve a estado no autenticado
  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

// Actualiza el usuario en el estado (ej. tras editar perfil)
  void _onUpdateUser(AuthUpdateUserEvent event, Emitter<AuthState> emit) {
    emit(AuthSuccess(event.usuario));
  }
}