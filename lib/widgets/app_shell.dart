import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/paleta.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'barra_lateral.dart';
import 'hud_inferior.dart';
import 'navegacion.dart';

/// Contenedor adaptable:
/// - < 840 px: HUD inferior con SOS (celular/Android).
/// - 840–1279 px: riel lateral de íconos (tablet).
/// - >= 1280 px: barra lateral completa según el rol (PC/Web).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    if (usuario == null) return child;
    final ubicacion = GoRouterState.of(context).matchedLocation;
    void ir(DestinoNav d) => context.go(d.ruta);
    void sos() => context.go('/sos');
    void perfil() => context.go('/perfil');

    return LayoutBuilder(
      builder: (context, constraints) {
        final tipo = tipoPantalla(constraints.maxWidth);
        if (tipo != TipoPantalla.celular) {
          final destinos = destinosLaterales(usuario.rol);
          final activo = indiceActivo(destinos, ubicacion);
          return Scaffold(
            backgroundColor: context.paleta.fondoPanel,
            body: Row(
              children: [
                if (tipo == TipoPantalla.escritorio)
                  BarraLateral(usuario: usuario, destinos: destinos, indiceActivo: activo, onDestino: ir, onSos: sos, onPerfil: perfil)
                else
                  RielLateral(usuario: usuario, destinos: destinos, indiceActivo: activo, onDestino: ir, onSos: sos, onPerfil: perfil),
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
            onSos: sos,
          ),
        );
      },
    );
  }
}

/// Relleno estándar del contenido de tablet/PC (Figma: 32 px a los lados).
const paddingEscritorio = EdgeInsets.fromLTRB(32, 26, 32, 28);
