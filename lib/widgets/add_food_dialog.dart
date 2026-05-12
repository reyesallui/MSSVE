import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/alimento.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';




// Dialogo para anadir alimento a comida con cantidad en gramos
class AddFoodDialog extends StatefulWidget {
  final Alimento alimento;

  const AddFoodDialog({super.key, required this.alimento});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _controller = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();
  double _kcalPreview = 0;

  @override
  void initState() {
    super.initState();
    
    _calcularPreview('100');
    _controller.addListener(() => _calcularPreview(_controller.text));
  }

  void _calcularPreview(String texto) {
    final gramos = double.tryParse(texto) ?? 0;
    setState(() {
      _kcalPreview = (widget.alimento.kcalPor100g * gramos) / 100;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.alimento.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.alimento.kcalPor100g.toStringAsFixed(0)} kcal/100g',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _controller,
                label: 'nutricion.grams'.tr(),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final gramos = double.tryParse(value ?? '');
                  if (gramos == null || gramos <= 0) {
                    return 'nutricion.invalid_grams'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_kcalPreview.toStringAsFixed(0)} kcal',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'common.cancel'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'common.add'.tr(),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(
                            context,
                            double.parse(_controller.text),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}