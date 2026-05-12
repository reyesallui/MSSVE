import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mssve/BLoC/auth/auth_bloc.dart';
import 'package:mssve/models/usuario.dart';
import 'package:mssve/widgets/language_selector.dart';



// Menu lateral de navegacion principal
class AppDrawer extends StatefulWidget {
  final Usuario usuario;
  const AppDrawer({super.key, required this.usuario});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return Drawer(
      backgroundColor: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
            accountName: Text(
              '${widget.usuario.nombre} ${widget.usuario.apellidos}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(widget.usuario.email,
                style: const TextStyle(color: Colors.grey)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFFD32F2F),
              child: Text(
                widget.usuario.nombre[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'drawer.home'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
          _DrawerItem(
            icon: Icons.restaurant_menu_outlined,
            label: 'drawer.nutrition'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.go('/nutricion');
            },
          ),
          _DrawerItem(
            icon: Icons.fitness_center_outlined,
            label: 'drawer.workout'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.go('/rutina');
            },
          ),
          
          _DrawerItem(
            icon: Icons.menu_book_outlined,
            label: 'drawer.training_diary'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.go('/historial');
            },
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'drawer.profile'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.go('/perfil');
            },
          ),
          const Spacer(),
          const Divider(color: Color(0xFF333333)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Text('drawer.language'.tr(),
                    style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                const LanguageSelector(),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.logout,
            label: 'drawer.logout'.tr(),
            color: const Color(0xFFD32F2F),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutEvent());
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}