import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'barra_lateral.dart';
import 'hud_inferior.dart';
import 'navegacion.dart';

/// Contenedor adaptable: HUD inferior (< 840 px) o barra lateral (>= 840 px).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    if (usuario == null) return child;
    final ubicacion = GoRouterState.of(context).matchedLocation;
    void ir(DestinoNav d) => context.go(d.ruta);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.breakpointEscritorio) {
          final destinos = destinosLaterales(usuario.rol);
          return Scaffold(
            body: Row(
              children: [
                BarraLateral(
                  usuario: usuario,
                  destinos: destinos,
                  indiceActivo: indiceActivo(destinos, ubicacion),
                  onDestino: ir,
                  onSos: () => mostrarDialogoSos(context),
                ),
                Expanded(child: child),
              ],
            ),
          );
        }
        final destinos = destinosHud(usuario.rol);
        return Scaffold(
          extendBody: true,
          body: child,
          bottomNavigationBar: HudInferior(
            destinos: destinos,
            indiceActivo: indiceActivo(destinos, ubicacion),
            onDestino: ir,
            onSos: () => mostrarDialogoSos(context),
          ),
        );
      },
    );
  }
}

/// Confirmación de SOS (simulada en el Sprint 1).
Future<void> mostrarDialogoSos(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.sos_rounded, color: AppColors.rojo, size: 40),
      title: const Text('¿Enviar alerta SOS?'),
      content: const Text('Se compartirá tu ubicación con tus contactos de emergencia y la autoridad más cercana.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar SOS')),
      ],
    ),
  );
  if (confirmado == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta SOS enviada (simulación).'), backgroundColor: AppColors.verdeExito),
    );
  }
}
