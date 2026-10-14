import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'barra_lateral.dart';

/// Menú lateral de celular (Figma "Menú Lateral"): 320 px, esquinas derechas de 24.
class MenuLateral extends ConsumerWidget {
  const MenuLateral({super.key, this.rutaActiva = '/inicio'});

  final String rutaActiva;

  static const _opciones = [
    (TablerIcons.home, 'Inicio', '/inicio'),
    (TablerIcons.map, 'Mapa', '/mapa'),
    (TablerIcons.urgent, 'Reportar hurto', '/reporte'),
    (TablerIcons.file_text, 'Mis reportes', '/mis-reportes'),
    (TablerIcons.bell, 'Alertas', '/alertas'),
    (TablerIcons.heart, 'Zonas favoritas', '/perfil/zonas'),
    (TablerIcons.settings, 'Ajustes', '/perfil/ajustes'),
    (TablerIcons.help_circle, 'Centro de ayuda', '/perfil/ayuda'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final usuario = ref.watch(authControllerProvider).usuario;
    void ir(String ruta) {
      Navigator.of(context).pop();
      context.go(ruta);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            if (usuario != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    AvatarUsuario(usuario: usuario, tamano: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.primerNombre, overflow: TextOverflow.ellipsis, style: Txt.r(22, color: p.texto)),
                          const SizedBox(height: 4),
                          Material(
                            color: AppColors.amarillo,
                            shape: const StadiumBorder(),
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: () => ir('/perfil'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                                child: Text('Ver perfil', style: Txt.nb(12, color: Colors.black)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final (icono, texto, ruta) in _opciones)
                    _OpcionMenu(icono: icono, texto: texto, activa: ruta == rutaActiva, onTap: () => ir(ruta)),
                  const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 4), child: Divider()),
                  _OpcionMenu(
                    icono: TablerIcons.logout,
                    texto: 'Cerrar sesión',
                    color: AppColors.rojo,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(authControllerProvider.notifier).cerrarSesion();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Text('Alerta Vial ${AppConstants.version}', style: Txt.n(12, color: p.textoSecundario)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  const _OpcionMenu({required this.icono, required this.texto, required this.onTap, this.activa = false, this.color});

  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final bool activa;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final c = color ?? p.texto;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: activa ? p.suaveAmarillo : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(icono, size: 22, color: activa ? (context.esOscuro ? AppColors.amarillo : const Color(0xFFB88600)) : c),
                const SizedBox(width: 14),
                Text(texto, style: activa || color != null ? Txt.nb(15, color: c) : Txt.n(15, color: c)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
