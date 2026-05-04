import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mssve/models/alimento.dart';

// Diálogo para crear o editar un alimento personalizado.
// Si se pasa alimentoEditar, los campos se precargan con sus valores actuales
// y el título cambia a "Editar alimento".
class CreateFoodDialog extends StatefulWidget {
  final Alimento? alimentoEditar;

  const CreateFoodDialog({super.key, this.alimentoEditar});

  @override
  State<CreateFoodDialog> createState() => _CreateFoodDialogState();
}

class _CreateFoodDialogState extends State<CreateFoodDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _proteinasCtrl;
  late final TextEditingController _carbosCtrl;
  late final TextEditingController _grasasCtrl;

  bool get _esEdicion => widget.alimentoEditar != null;

  @override
  void initState() {
    super.initState();
    final a = widget.alimentoEditar;
    // Si estamos editando, precargamos los valores actuales del alimento
    _nombreCtrl   = TextEditingController(text: a?.nombre ?? '');
    _kcalCtrl     = TextEditingController(text: a != null ? a.kcalPor100g.toString() : '');
    _proteinasCtrl = TextEditingController(text: a != null ? a.proteinasPor100g.toString() : '');
    _carbosCtrl   = TextEditingController(text: a != null ? a.carbohidratosPor100g.toString() : '');
    _grasasCtrl   = TextEditingController(text: a != null ? a.grasasPor100g.toString() : '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _kcalCtrl.dispose(); _proteinasCtrl.dispose();
    _carbosCtrl.dispose(); _grasasCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_nombreCtrl.text.trim().isEmpty) return;
    if (double.tryParse(_kcalCtrl.text) == null) return;

    Navigator.pop(context, {
      'nombre':                _nombreCtrl.text.trim(),
      'kcal_por_100g':         double.parse(_kcalCtrl.text),
      'proteinas_por_100g':    double.tryParse(_proteinasCtrl.text) ?? 0,
      'carbohidratos_por_100g': double.tryParse(_carbosCtrl.text) ?? 0,
      'grasas_por_100g':       double.tryParse(_grasasCtrl.text) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        _esEdicion
            ? 'nutricion.edit_food'.tr()
            : 'nutricion.create_food'.tr(),
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Campo(ctrl: _nombreCtrl,   label: 'common.name'.tr()),
            const SizedBox(height: 10),
            _Campo(ctrl: _kcalCtrl,     label: 'macro.kcal'.tr(),    numeric: true),
            const SizedBox(height: 10),
            _Campo(ctrl: _proteinasCtrl, label: 'macro.proteins'.tr(), numeric: true),
            const SizedBox(height: 10),
            _Campo(ctrl: _carbosCtrl,   label: 'macro.carbs'.tr(),   numeric: true),
            const SizedBox(height: 10),
            _Campo(ctrl: _grasasCtrl,   label: 'macro.fats'.tr(),    numeric: true),
            const SizedBox(height: 6),
            Text('nutricion.values_per_100g'.tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr(),
              style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _confirmar,
          child: Text(
            _esEdicion ? 'common.save'.tr() : 'nutricion.save_food'.tr(),
            style: const TextStyle(color: Color(0xFFD32F2F)),
          ),
        ),
      ],
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool numeric;
  const _Campo({required this.ctrl, required this.label, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF333333))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD32F2F))),
      ),
    );
  }
}