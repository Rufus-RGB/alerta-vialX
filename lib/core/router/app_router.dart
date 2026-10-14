import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../features/alertas/presentation/alertas_screen.dart';
import '../../features/auth/domain/usuario.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/autoridad/presentation/autoridad_screen.dart';
import '../../features/dev/presentation/dev_screen.dart';
import '../../features/inicio/presentation/inicio_screen.dart';
import '../../features/mapa/presentation/mapa_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/reporte/presentation/reporte_screen.dart';
import '../../widgets/app_shell.dart';

/// Rutas exclusivas de cada rol. Las demás rutas del shell son comunes.
const _rutasPorRol = <String, Rol>{
  '/inicio': Rol.ciudadano,
  '/reporte': Rol.ciudadano,
  '/dev': Rol.dev,
  '/autoridad': Rol.autoridad,
};

/// Calcula la redirección según el estado de sesión y el rol.
String? redireccionPorRol(AuthState auth, String ubicacion) {
  if (!auth.inicializado) return ubicacion == '/splash' ? null : '/splash';
  final usuario = auth.usuario;
  if (usuario == null) return ubicacion == '/login' ? null : '/login';
  if (ubicacion == '/splash' || ubicacion == '/login' || ubicacion == '/') return usuario.rol.rutaInicio;
  final rolRequerido = _rutasPorRol[ubicacion];
  if (rolRequerido != null && rolRequerido != usuario.rol) return usuario.rol.rutaInicio;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refrescar = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refrescar.value++);
  ref.onDispose(refrescar.dispose);

  NoTransitionPage<void> pagina(GoRouterState s, Widget w) => NoTransitionPage(key: s.pageKey, child: w);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refrescar,
    redirect: (context, state) => redireccionPorRol(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/inicio', pageBuilder: (_, s) => pagina(s, const InicioScreen())),
          GoRoute(
            path: '/mapa',
            pageBuilder: (_, s) {
              final lat = double.tryParse(s.uri.queryParameters['lat'] ?? '');
              final lng = double.tryParse(s.uri.queryParameters['lng'] ?? '');
              final foco = lat != null && lng != null ? LatLng(lat, lng) : null;
              // La página se conserva al cambiar la consulta; MapaScreen reacciona al nuevo foco.
              return NoTransitionPage(key: const ValueKey('mapa'), child: MapaScreen(foco: foco));
            },
          ),
          GoRoute(path: '/reporte', pageBuilder: (_, s) => pagina(s, const ReporteScreen())),
          GoRoute(path: '/alertas', pageBuilder: (_, s) => pagina(s, const AlertasScreen())),
          GoRoute(path: '/perfil', pageBuilder: (_, s) => pagina(s, const PerfilScreen())),
          GoRoute(path: '/dev', pageBuilder: (_, s) => pagina(s, const DevScreen())),
          GoRoute(path: '/autoridad', pageBuilder: (_, s) => pagina(s, const AutoridadScreen())),
        ],
      ),
    ],
  );
});
