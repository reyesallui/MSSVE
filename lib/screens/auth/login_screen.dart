import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/primary_button.dart';

// Pantalla de inicio de sesión.
// Muestra el logo, los campos de email y contraseña,
// y el botón de login. También permite cambiar el idioma
// desde el selector del AppBar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // _formKey nos permite validar todos los campos del formulario a la vez
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama automáticamente cuando cambia el locale,
    // forzando el rebuild para actualizar los textos traducidos
    setState(() {});
  }

  @override
  void dispose() {
    // Liberamos los controladores al salir de la pantalla
    // para evitar fugas de memoria
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Valida el formulario y manda el evento de login al AuthBloc
  void _login() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginEvent(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Leer context.locale registra este widget como dependiente
    // de EasyLocalization, lo que dispara el rebuild al cambiar idioma
    final _ = context.locale;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Selector de idioma en la esquina superior derecha
        actions: const [LanguageSelector(), SizedBox(width: 8)],
      ),
      // BlocListener escucha los cambios del AuthBloc sin reconstruir la UI.
      // Solo reacciona a eventos concretos: navega al home si el login
      // fue bien, o muestra un snackbar si hubo un error.
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go('/home');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message.tr()),
              backgroundColor: const Color(0xFFCF6679),
            ));
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo de la app — si no existe el archivo muestra el nombre
                  Image.asset(
                    'assets/logo/logo.jpeg',
                    height: 300,
                    errorBuilder: (_, __, ___) => const Text(
                      'MSSVE',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _emailCtrl,
                    label: 'login.email'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'common.required_field'.tr();
                      if (!v.contains('@')) return 'common.invalid_value'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordCtrl,
                    label: 'login.password'.tr(),
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    // Icono para mostrar u ocultar la contraseña
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'common.required_field'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // BlocBuilder reconstruye solo el botón para mostrar
                  // el spinner de carga mientras se procesa el login
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => PrimaryButton(
                      label: 'login.button'.tr(),
                      isLoading: state is AuthLoading,
                      onPressed: _login,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('login.no_account'.tr(),
                          style: const TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text('login.register_link'.tr(),
                            style: const TextStyle(color: Color(0xFFD32F2F))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}