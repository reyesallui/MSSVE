import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/BLoC/nutricion/nutricion_bloc.dart';
import 'package:mssve/widgets/add_food_dialog.dart';
import 'package:mssve/widgets/app_drawer.dart';
import 'package:mssve/widgets/create_food_dialog.dart';
import 'package:mssve/widgets/food_search_delegate.dart';
import 'package:mssve/widgets/meal_card.dart';

// Pantalla principal de nutrición.
// Muestra las comidas del día divididas en pestañas (Desayuno, Almuerzo...)
// y permite navegar entre días con los botones ← →.
class NutricionScreen extends StatefulWidget {
  const NutricionScreen({super.key});

  @override
  State<NutricionScreen> createState() => _NutricionScreenState();
}

class _NutricionScreenState extends State<NutricionScreen> {
  // Valores internos que se guardan en la BD, nunca cambian aunque cambie el idioma
  static const _tiposComida = ['Desayuno', 'Almuerzo', 'Merienda', 'Cena', 'Extra'];
  // Claves de traducción para cada tipo, tienen que estar en el mismo orden que _tiposComida
  static const _clavesTrad = [
    'nutricion.breakfast',
    'nutricion.lunch',
    'nutricion.snack',
    'nutricion.dinner',
    'nutricion.extra',
  ];

  // Fecha que se está visualizando. Empieza en hoy y cambia con los botones ← →
  DateTime _fechaSeleccionada = DateTime.now();

  // Compara solo año, mes y día para saber si estamos en el día de hoy

  // Límite máximo de 7 días hacia el futuro.
  // Normalizamos las fechas eliminando la hora para comparar solo día/mes/año.
  bool get _esFuturoLejano {
    final limiteMax = DateTime.now().add(const Duration(days: 7));
    final fechaNorm = DateTime(_fechaSeleccionada.year,
        _fechaSeleccionada.month, _fechaSeleccionada.day);
    final limiteNorm = DateTime(limiteMax.year, limiteMax.month, limiteMax.day);
    return fechaNorm.isAfter(limiteNorm) || fechaNorm.isAtSameMomentAs(limiteNorm);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // /CARGA DE DATOS/
  // Manda el evento de carga al NutricionBloc con el usuario y la fecha seleccionada
  void _cargarDatos() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<NutricionBloc>().add(NutricionLoadEvent(
        idUsuario: authState.usuario.id,
        fecha: DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
      ));
    }
  }

  // /NAVEGACIÓN ENTRE DÍAS/
  // Retrocede un día y recarga los datos
  void _diaAnterior() {
    setState(() => _fechaSeleccionada =
        _fechaSeleccionada.subtract(const Duration(days: 1)));
    _cargarDatos();
  }

  // Avanza un día — bloqueado si ya estamos en el límite de +7 días
  void _diaSiguiente() {
    if (_esFuturoLejano) return;
    setState(() => _fechaSeleccionada =
        _fechaSeleccionada.add(const Duration(days: 1)));
    _cargarDatos();
  }

  // /BUSCADOR DE ALIMENTOS/
  // showSearch abre una pantalla de búsqueda completa gestionada por FoodSearchDelegate.
  // Cuando el usuario elige un alimento, se abre AddFoodDialog para introducir los gramos.
  Future<void> _abrirBuscador(BuildContext context, String tipoComida) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;
    final nutricionState = context.read<NutricionBloc>().state;
    if (nutricionState is! NutricionLoaded) return;

    final alimento = await showSearch(
      context: context,
      delegate: FoodSearchDelegate(
        idUsuario: authState.usuario.id,
        nutricionBloc: context.read<NutricionBloc>(),
      ),
    );
    if (alimento == null || !context.mounted) return;

    final gramos = await showDialog<double>(
      context: context,
      builder: (_) => AddFoodDialog(alimento: alimento),
    );
    if (gramos == null || !context.mounted) return;

    context.read<NutricionBloc>().add(NutricionAnadirAlimentoEvent(
      idComida: 0,
      idAlimento: alimento.id,
      cantidadGramos: gramos,
      idRegistroDiario: nutricionState.registroDiario.id,
      tipoComida: tipoComida,
    ));
  }

  // /CREAR ALIMENTO/
  // Abre CreateFoodDialog y manda el evento de creación al bloc
  Future<void> _abrirCrearAlimento(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    // El dialog devuelve un Map con los datos — uso Map<String, dynamic>
    // porque los valores son de distintos tipos (String, double)
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateFoodDialog(),
    );
    if (datos == null || !context.mounted) return;

    context.read<NutricionBloc>().add(NutricionCrearAlimentoEvent(
      idUsuario: authState.usuario.id,
      nombre: datos['nombre'],
      kcalPor100g: datos['kcal_por_100g'],
      proteinasPor100g: datos['proteinas_por_100g'],
      carbohidratosPor100g: datos['carbohidratos_por_100g'],
      grasasPor100g: datos['grasas_por_100g'],
    ));
  }

  // /EDITAR ALIMENTO/
  // Abre el buscador, comprueba que el alimento sea personalizado y permite editarlo.
  // Solo se pueden editar alimentos creados por el propio usuario, no los globales.
  Future<void> _abrirEditarAlimento(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    final alimento = await showSearch(
      context: context,
      delegate: FoodSearchDelegate(
        idUsuario: authState.usuario.id,
        nutricionBloc: context.read<NutricionBloc>(),
      ),
    );
    if (alimento == null || !context.mounted) return;

    if (!alimento.esPersonalizado) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('nutricion.only_custom_edit'.tr()),
        backgroundColor: const Color(0xFFCF6679),
      ));
      return;
    }

    if (!context.mounted) return;

    // Reutilizamos CreateFoodDialog pasándole el alimento para que los campos vengan rellenos
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CreateFoodDialog(alimentoEditar: alimento),
    );
    if (datos == null || !context.mounted) return;

    context.read<NutricionBloc>().add(NutricionEditarAlimentoEvent(
      id: alimento.id,
      nombre: datos['nombre'],
      kcalPor100g: datos['kcal_por_100g'],
      proteinasPor100g: datos['proteinas_por_100g'],
      carbohidratosPor100g: datos['carbohidratos_por_100g'],
      grasasPor100g: datos['grasas_por_100g'],
    ));
  }

  // /BUILD/
  @override
  Widget build(BuildContext context) {
    // Leer context.locale suscribe este widget al locale y fuerza
    // el rebuild automático cuando el usuario cambia el idioma
    final locale = context.locale;

    // DefaultTabController gestiona las 5 pestañas sin necesitar
    // un TabController manual en initState
    return DefaultTabController(
      length: _tiposComida.length,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        drawer: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) return AppDrawer(usuario: state.usuario);
            return const SizedBox();
          },
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          title: Text('drawer.nutrition'.tr(),
              style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'drawer.home'.tr(),
              onPressed: () => context.go('/home'),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'nutricion.create_food'.tr(),
              onPressed: () => _abrirCrearAlimento(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'nutricion.edit_food'.tr(),
              onPressed: () => _abrirEditarAlimento(context),
            ),
          ],
          // /NAVEGADOR DE FECHAS Y PESTAÑAS/
          // PreferredSize apila el navegador de fechas encima del TabBar
          // dentro del bottom del AppBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: _diaAnterior,
                      ),
                      Text(
                        DateFormat('EEE d MMM', locale.toString())
                            .format(_fechaSeleccionada),
                        style: TextStyle(
                          // Rojo si es pasado, blanco si es hoy o futuro
                          color: _fechaSeleccionada.isBefore(DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day))
                              ? const Color(0xFFD32F2F)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: _esFuturoLejano ? Colors.grey : Colors.white,
                        ),
                        onPressed: _esFuturoLejano ? null : _diaSiguiente,
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFFD32F2F),
                  labelColor: const Color(0xFFD32F2F),
                  unselectedLabelColor: Colors.grey,
                  onTap: (index) => context.read<NutricionBloc>().add(
                      NutricionCambiarTipoComidaEvent(_tiposComida[index])),
                  // Generamos los tabs con un for en lugar de escribirlos uno a uno
                  tabs: [
                    for (final clave in _clavesTrad) Tab(text: clave.tr()),
                  ],
                ),
              ],
            ),
          ),
        ),

        // /BODY/
        body: BlocBuilder<NutricionBloc, NutricionState>(
          builder: (context, state) {
            if (state is NutricionLoading || state is NutricionInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NutricionError) {
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
            if (state is NutricionLoaded) {
              final registro = state.registroDiario;
              // List.generate crea un widget por cada tipo de comida.
              // Usamos el índice i para acceder tanto a _tiposComida como a _clavesTrad a la vez.
              return TabBarView(
                children: List.generate(_tiposComida.length, (i) {
                  final tipo  = _tiposComida[i];
                  final clave = _clavesTrad[i];
                  // firstOrNull devuelve null si no hay comida de ese tipo en lugar de lanzar error
                  final comida = registro.comidas
                      .where((c) => c.tipoComida == tipo)
                      .firstOrNull;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ResumenKcal(
                        kcalConsumidas: registro.kcalConsumidas,
                        kcalObjetivo: context.read<AuthBloc>().state is AuthSuccess
                            ? (context.read<AuthBloc>().state as AuthSuccess)
                                .usuario.gastoEnergeticoTotal
                            : 2000,
                      ),
                      const SizedBox(height: 16),
                      // Si ya hay comida en este tipo mostramos la tarjeta,
                      // si no mostramos el botón de añadir
                      if (comida != null)
                        MealCard(
                          comida: comida,
                          onAnadirAlimento: () => _abrirBuscador(context, tipo),
                          onEliminarAlimento: (id) => context
                              .read<NutricionBloc>()
                              .add(NutricionEliminarAlimentoEvent(id)),
                        )
                      else
                        _BotonCrearComida(
                          tipo: tipo,
                          tipoTraducido: clave.tr(),
                          onTap: () => _abrirBuscador(context, tipo),
                        ),
                    ],
                  );
                }),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

// /RESUMEN DE CALORÍAS/
// Tarjeta que muestra las kcal consumidas hoy frente al objetivo del usuario
class _ResumenKcal extends StatelessWidget {
  final double kcalConsumidas;
  final double kcalObjetivo;
  const _ResumenKcal(
      {required this.kcalConsumidas, required this.kcalObjetivo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('nutricion.calories_today'.tr(),
              style: const TextStyle(color: Colors.grey)),
          Text(
            // toStringAsFixed(0) redondea sin decimales
            '${kcalConsumidas.toStringAsFixed(0)} / ${kcalObjetivo.toStringAsFixed(0)} kcal',
            style: const TextStyle(
                color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// /BOTÓN CREAR COMIDA/
// Se muestra cuando no hay ningún alimento registrado en ese tipo de comida.
// tipo = valor interno en español para la BD
// tipoTraducido = texto ya traducido al idioma activo para mostrarlo en pantalla
class _BotonCrearComida extends StatelessWidget {
  final String tipo;
  final String tipoTraducido;
  final VoidCallback onTap;

  const _BotonCrearComida({
    required this.tipo,
    required this.tipoTraducido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // InkWell añade el efecto ripple de Material al pulsar
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFD32F2F).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Color(0xFFD32F2F)),
            const SizedBox(width: 8),
            Text(
              'nutricion.add_to'.tr(args: [tipoTraducido]),
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          ],
        ),
      ),
    );
  }
}