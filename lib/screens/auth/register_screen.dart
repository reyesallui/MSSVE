import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// CORREGIDO: import duplicado eliminado, solo uno
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import '../../utils/get_calculator.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  bool _obscurePassword = true;
  String _genero = 'Hombre';
  String _objetivo = 'Recomposicion';
  String _nivelActividad = 'Moderado';
  int _paso = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama automáticamente cuando cambia el locale,
    // forzando el rebuild para actualizar los textos traducidos
    setState(() {});
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidosCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _pesoCtrl.dispose();
    _alturaCtrl.dispose(); _edadCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    final get = GETCalculator.calcularGET(
      peso: double.parse(_pesoCtrl.text),
      altura: int.parse(_alturaCtrl.text),
      edad: int.parse(_edadCtrl.text),
      genero: _genero,
      nivelActividad: _nivelActividad,
    );
    context.read<AuthBloc>().add(AuthRegisterEvent(
      nombre: _nombreCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      peso: double.parse(_pesoCtrl.text),
      altura: int.parse(_alturaCtrl.text),
      genero: _genero,
      objetivo: _objetivo,
      nivelActividad: _nivelActividad,
      get: get,
      edad: int.parse(_edadCtrl.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _paso == 1
              ? context.go('/login')
              : setState(() => _paso = 1),
        ),
        title: Text(
          'register.step'.tr(args: ['$_paso', '2']),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) context.go('/home');
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message.replaceAll('Exception: ', '').tr()),
              backgroundColor: const Color(0xFFCF6679),
            ));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: _paso == 1 ? _buildPaso1() : _buildPaso2(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('register.personal_data'.tr(),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _nombreCtrl,
          label: 'register.name'.tr(),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'common.required_field'.tr()
              : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _apellidosCtrl,
          label: 'register.surnames'.tr(),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'common.required_field'.tr()
              : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _emailCtrl,
          label: 'register.email'.tr(),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'common.required_field'.tr();
            if (!v.contains('@')) return 'common.invalid_value'.tr();
            return null;
          },
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _passwordCtrl,
          label: 'register.password'.tr(),
          obscureText: _obscurePassword,
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
            if (v.length < 6) return 'common.password_short'.tr();
            return null;
          },
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'common.next'.tr(),
          onPressed: () {
            if (_formKey.currentState!.validate()) setState(() => _paso = 2);
          },
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('register.physical_data'.tr(),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: CustomTextField(
            controller: _pesoCtrl,
            label: 'register.weight'.tr(),
            keyboardType: TextInputType.number,
            validator: (v) => double.tryParse(v ?? '') == null
                ? 'common.invalid_value'.tr()
                : null,
          )),
          const SizedBox(width: 12),
          Expanded(child: CustomTextField(
            controller: _alturaCtrl,
            label: 'register.height'.tr(),
            keyboardType: TextInputType.number,
            validator: (v) => int.tryParse(v ?? '') == null
                ? 'common.invalid_value'.tr()
                : null,
          )),
          const SizedBox(width: 12),
          Expanded(child: CustomTextField(
            controller: _edadCtrl,
            label: 'register.age'.tr(),
            keyboardType: TextInputType.number,
            validator: (v) => int.tryParse(v ?? '') == null
                ? 'common.invalid_value'.tr()
                : null,
          )),
        ]),
        const SizedBox(height: 16),
        _Selector(
          label: 'register.gender'.tr(),
          value: _genero,
          opciones: const ['Hombre', 'Mujer'],
          onChanged: (v) => setState(() => _genero = v),
        ),
        const SizedBox(height: 12),
        _Selector(
          label: 'register.objective'.tr(),
          value: _objetivo,
          opciones: const ['Recomposicion', 'Volumen', 'Definicion'],
          onChanged: (v) => setState(() => _objetivo = v),
        ),
        const SizedBox(height: 12),
        _Selector(
          label: 'register.activity_level'.tr(),
          value: _nivelActividad,
          opciones: const ['Sedentario', 'Ligero', 'Moderado', 'Intenso', 'Muy_intenso'],
          onChanged: (v) => setState(() => _nivelActividad = v),
        ),
        const SizedBox(height: 32),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => PrimaryButton(
            label: 'register.button'.tr(),
            isLoading: state is AuthLoading,
            onPressed: _register,
          ),
        ),
      ],
    );
  }
}

class _Selector extends StatelessWidget {
  final String label;
  final String value;
  final List<String> opciones;
  final void Function(String) onChanged;

  const _Selector({
    required this.label,
    required this.value,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF333333))),
          ),
          items: opciones
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ],
    );
  }
}