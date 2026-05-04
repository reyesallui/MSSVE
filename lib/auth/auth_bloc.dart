import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/usuario.dart';
import '../repositories/repository_autenticacion.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RepositoryAutenticacion _repository;

  AuthBloc({required RepositoryAutenticacion repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthCheckSessionEvent>(_onCheckSession);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthUpdateUserEvent>(_onUpdateUser);
  }

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

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final usuario = await _repository.login(email: event.email, password: event.password);
      emit(AuthSuccess(usuario));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

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

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  void _onUpdateUser(AuthUpdateUserEvent event, Emitter<AuthState> emit) {
    emit(AuthSuccess(event.usuario));
  }
}