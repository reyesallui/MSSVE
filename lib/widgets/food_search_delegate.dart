import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mssve/nutricion/nutricion_bloc.dart';
import 'package:mssve/models/alimento.dart';

// showSearch() abre una nueva ruta y pierde el contexto del padre.
// Por eso pasamos el NutricionBloc directamente al delegate en vez de
// leerlo con context.read() desde dentro del buscador.
class FoodSearchDelegate extends SearchDelegate<Alimento?> {
  final int idUsuario;
  final NutricionBloc nutricionBloc;

  FoodSearchDelegate({required this.idUsuario, required this.nutricionBloc});

  @override
  String get searchFieldLabel => 'nutricion.search_food'.tr();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () { query = ''; showSuggestions(context); },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResultados();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isNotEmpty) {
      nutricionBloc.add(NutricionBuscarAlimentosEvent(
        search: query,
        idUsuario: idUsuario,
      ));
    }
    return _buildResultados();
  }

  Widget _buildResultados() {
    return BlocBuilder<NutricionBloc, NutricionState>(
      bloc: nutricionBloc, // usamos el bloc pasado, no el del contexto
      builder: (context, state) {
        if (state is! NutricionLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        if (query.isEmpty) {
          return Center(child: Text('nutricion.write_to_search'.tr(),
              style: const TextStyle(color: Colors.grey)));
        }
        final resultados = state.resultadosBusqueda;
        if (resultados.isEmpty) {
          return Center(child: Text('nutricion.no_results'.tr(),
              style: const TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          itemCount: resultados.length,
          itemBuilder: (context, index) {
            final alimento = resultados[index];
            return ListTile(
              title: Text(alimento.nombre),
              subtitle: Text(
                '${alimento.kcalPor100g.toStringAsFixed(0)} kcal/100g · '
                'P:${alimento.proteinasPor100g.toStringAsFixed(1)}g '
                'C:${alimento.carbohidratosPor100g.toStringAsFixed(1)}g '
                'G:${alimento.grasasPor100g.toStringAsFixed(1)}g',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: alimento.esPersonalizado
                  ? const Icon(Icons.person_outline,
                      color: Color(0xFFD32F2F), size: 16)
                  : null,
              onTap: () => close(context, alimento),
            );
          },
        );
      },
    );
  }
}