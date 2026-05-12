import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';




// Selector de idioma (es/en/fr) con icono de bandera y persistencia en EasyLocalization
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static const _idiomas = [
    {'locale': Locale('es'), 'label': 'Español'},
    {'locale': Locale('en'), 'label': 'English'},
    {'locale': Locale('fr'), 'label': 'Français'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Colors.white),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (locale) => context.setLocale(locale),
      itemBuilder: (_) => _idiomas.map((item) {
        final locale = item['locale'] as Locale;
        final isSelected = locale == currentLocale;

        return PopupMenuItem<Locale>(
          value: locale,
          child: Row(
            children: [
              Text(item['flag'] as String,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                item['label'] as String,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFD32F2F)
                      : Colors.white,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check, color: Color(0xFFD32F2F), size: 16),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}