import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/BLoC/perfil/perfil_bloc.dart';
import 'package:mssve/widgets/app_drawer.dart';
import 'package:mssve/widgets/custom_text_field.dart';
import 'package:mssve/widgets/primary_button.dart';


// Pantalla de perfil: edicion de datos personales, cambio de contrasena y seleccion de idioma
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _formKey       = GlobalKey<FormState>();
  final _nombreCtrl    = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _pesoCtrl      = TextEditingController();
  final _alturaCtrl    = TextEditingController();
  final _edadCtrl      = TextEditingController();
  String _genero         = 'Hombre';
  String _objetivo       = 'Recomposicion';
  String _nivelActividad = 'Moderado';

  
  bool _formRellenado = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<PerfilBloc>().add(PerfilLoadEvent(authState.usuario.id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreCtrl.dispose(); _apellidosCtrl.dispose(); _emailCtrl.dispose();
    _pesoCtrl.dispose(); _alturaCtrl.dispose(); _edadCtrl.dispose();
    super.dispose();
  }

  void _rellenarFormulario(dynamic usuario) {
    _nombreCtrl.text    = usuario.nombre;
    _apellidosCtrl.text = usuario.apellidos;
    _emailCtrl.text     = usuario.email;
    _pesoCtrl.text      = usuario.peso.toString();
    _alturaCtrl.text    = usuario.altura.toString();
    _edadCtrl.text      = usuario.edad.toString();
    setState(() {
      _genero         = usuario.genero;
      _objetivo       = usuario.objetivo;
      _nivelActividad = usuario.nivelActividad;
      _formRellenado  = true;
    });
  }

  void _guardarPerfil() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;
    context.read<PerfilBloc>().add(PerfilActualizarEvent(
      id: authState.usuario.id,
      nombre: _nombreCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      peso: double.parse(_pesoCtrl.text),
      altura: int.parse(_alturaCtrl.text),
      genero: _genero,
      objetivo: _objetivo,
      nivelActividad: _nivelActividad,
      edad: int.parse(_edadCtrl.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('perfil.title'.tr(),
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'drawer.home'.tr(),
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD32F2F),
          labelColor: const Color(0xFFD32F2F),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'perfil.personal_data'.tr()),
            Tab(text: 'perfil.password_tab'.tr()),
          ],
        ),
      ),
      
      
      body: BlocConsumer<PerfilBloc, PerfilState>(
        buildWhen: (prev, curr) =>
            curr is! PerfilLoading || prev is PerfilInitial,
        listener: (context, state) {
          if (state is PerfilLoaded && !_formRellenado) {
            _rellenarFormulario(state.usuario);
          }
          if (state is PerfilSucces) {
            _rellenarFormulario(state.usuario);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message.replaceAll('Exception: ', '').tr()),
                backgroundColor: const Color(0xFF2E7D32),
              ));
            }
          }
          if (state is PerfilError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message.replaceAll('Exception: ', '').tr()),
                backgroundColor: const Color(0xFFCF6679),
              ));
            }
          }
        },
        builder: (context, state) {
          if (state is PerfilLoading || state is PerfilInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [_buildDatos(state), _buildContrasena()],
          );
        },
      ),
    );
  }

  
  Widget _buildDatos(PerfilState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFD32F2F),
            child: Text(
              _nombreCtrl.text.isNotEmpty
                  ? _nombreCtrl.text[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: CustomTextField(
              controller: _nombreCtrl,
              label: 'register.name'.tr(),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'common.required_field'.tr() : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: CustomTextField(
              controller: _apellidosCtrl,
              label: 'register.surnames'.tr(),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'common.required_field'.tr() : null,
            )),
          ]),
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
          Row(children: [
            Expanded(child: CustomTextField(
              controller: _pesoCtrl,
              label: 'register.weight'.tr(),
              keyboardType: TextInputType.number,
              validator: (v) => double.tryParse(v ?? '') == null
                  ? 'common.invalid_value'.tr() : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: CustomTextField(
              controller: _alturaCtrl,
              label: 'register.height'.tr(),
              keyboardType: TextInputType.number,
              validator: (v) => int.tryParse(v ?? '') == null
                  ? 'common.invalid_value'.tr() : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: CustomTextField(
              controller: _edadCtrl,
              label: 'register.age'.tr(),
              keyboardType: TextInputType.number,
              validator: (v) => int.tryParse(v ?? '') == null
                  ? 'common.invalid_value'.tr() : null,
            )),
          ]),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'register.gender'.tr(),
            value: _genero,
            opciones: const ['Hombre', 'Mujer'],
            traducciones: {
              'Hombre': 'register.gender_male'.tr(),
              'Mujer': 'register.gender_female'.tr(),
            },
            onChanged: (v) => setState(() => _genero = v),
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'register.objective'.tr(),
            value: _objetivo,
            opciones: const ['Recomposicion', 'Volumen', 'Definicion'],
            traducciones: {
              'Recomposicion': 'register.objective_recomposition'.tr(),
              'Volumen': 'register.objective_volume'.tr(),
              'Definicion': 'register.objective_definition'.tr(),
            },
            onChanged: (v) => setState(() => _objetivo = v),
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'register.activity_level'.tr(),
            value: _nivelActividad,
            opciones: const ['Sedentario', 'Ligero', 'Moderado', 'Intenso', 'Muy_intenso'],
            traducciones: {
              'Sedentario': 'register.activity_sedentary'.tr(),
              'Ligero': 'register.activity_light'.tr(),
              'Moderado': 'register.activity_moderate'.tr(),
              'Intenso': 'register.activity_intense'.tr(),
              'Muy_intenso': 'register.activity_very_intense'.tr(),
            },
            onChanged: (v) => setState(() => _nivelActividad = v),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'perfil.save'.tr(),
            isLoading: state is PerfilLoading,
            onPressed: _guardarPerfil,
          ),
        ]),
      ),
    );
  }

  
  
  Widget _buildContrasena() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(children: [
          const SizedBox(height: 16),
          CustomTextField(
            controller: currentCtrl,
            label: 'perfil.current_password'.tr(),
            obscureText: true,
            validator: (v) => v == null || v.isEmpty
                ? 'common.required_field'.tr() : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: newCtrl,
            label: 'perfil.new_password'.tr(),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'common.required_field'.tr();
              if (v.length < 6) return 'common.password_short'.tr();
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: confirmCtrl,
            label: 'perfil.confirm_password'.tr(),
            obscureText: true,
            validator: (v) => v != newCtrl.text
                ? 'perfil.passwords_no_match'.tr() : null,
          ),
          const SizedBox(height: 32),
          BlocBuilder<PerfilBloc, PerfilState>(
            builder: (context, state) => PrimaryButton(
              label: 'perfil.change_password'.tr(),
              isLoading: state is PerfilLoading,
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthSuccess) return;
                context.read<PerfilBloc>().add(PerfilCambiarPasswordEvent(
                  userId: authState.usuario.id,
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                ));
              },
            ),
          ),
        ]),
      ),
    );
  }
}



class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> opciones;
  final Map<String, String>? traducciones;
  final void Function(String) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.opciones,
    this.traducciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
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
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(traducciones?[o] ?? o),
              ))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}