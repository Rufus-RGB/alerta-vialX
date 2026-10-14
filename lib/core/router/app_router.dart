import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../features/alertas/presentation/alertas_screen.dart';
import '../../features/alertas/presentation/configurar_alertas_screen.dart';
import '../../features/auth/domain/usuario.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/permisos_screen.dart';
import '../../features/auth/presentation/recuperar_screen.dart';
import '../../features/auth/presentation/registro_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verificacion_autoridad_screen.dart';
import '../../features/autoridad/presentation/autoridad_screen.dart';
import '../../features/dev/presentation/dev_screen.dart';
import '../../features/inicio/presentation/inicio_screen.dart';
import '../../features/inicio/presentation/notificaciones_screen.dart';
import '../../features/inicio/presentation/sos_screen.dart';
import '../../features/mapa/presentation/mapa_screen.dart';
import '../../features/perfil/presentation/cuenta_screens.dart';
import '../../features/perfil/presentation/mis_reportes_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/perfil/presentation/vehiculos_screens.dart';
import '../../features/perfil/presentation/zonas_screens.dart';
import '../../features/reporte/presentation/reporte_estado_screens.dart';
import '../../features/reporte/presentation/reporte_screen.dart';
import '../../widgets/app_shell.dart';

/// Rutas sin sesión.
const _rutasPublicas = {'/login', '/registro', '/recuperar', '/verificacion-autoridad'};

/// Prefijos de ruta exclusivos de cada rol. Las demás rutas del shell son comunes.
const _rutasPorRol = <String, Rol>{
  '/inicio': Rol.ciudadano,
  '/reporte': Rol.ciudadano,
  '/mis-reportes': Rol.ciudadano,
  '/sos': Rol.ciudadano,
  '/perfil/vehiculos': Rol.ciudadano,
  '/perfil/zonas': Rol.ciudadano,
  '/dev': Rol.dev,
  '/autoridad': Rol.autoridad,
};

/// Calcula la redirección según el estado de sesión y el rol.
/// [destino] es la ruta pedida originalmente (se conserva al pasar por el Splash al recargar).
String? redireccionPorRol(AuthState auth, String ubicacion, {String? destino}) {
  if (!auth.inicializado) {
    if (ubicacion == '/splash') return null;
    return ubicacion == '/' ? '/splash' : '/splash?desde=${Uri.encodeQueryComponent(destino ?? ubicacion)}';
  }
  final usuario = auth.usuario;
  if (usuario == null) return _rutasPublicas.contains(ubicacion) ? null : '/login';
  if (auth.mostrarPermisos) return ubicacion == '/permisos' ? null : '/permisos';
  if (ubicacion == '/splash' && destino != null && destino.startsWith('/') && !destino.startsWith('/splash')) {
    return redireccionPorRol(auth, Uri.parse(destino).path) ?? destino;
  }
  if (ubicacion == '/splash' || ubicacion == '/' || ubicacion == '/permisos' || _rutasPublicas.contains(ubicacion)) {
    return usuario.rol.rutaInicio;
  }
  for (final e in _rutasPorRol.entries) {
    if ((ubicacion == e.key || ubicacion.startsWith('${e.key}/')) && e.value != usuario.rol) return usuario.rol.rutaInicio;
  }
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
    redirect: (context, state) => redireccionPorRol(
      ref.read(authControllerProvider),
      state.matchedLocation,
      destino: state.matchedLocation == '/splash' ? state.uri.queryParameters['desde'] : state.uri.toString(),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/splash'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegistroScreen()),
      GoRoute(path: '/recuperar', builder: (_, _) => const RecuperarScreen()),
      GoRoute(path: '/verificacion-autoridad', builder: (_, _) => const VerificacionAutoridadScreen()),
      GoRoute(path: '/permisos', builder: (_, _) => const PermisosScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/inicio', pageBuilder: (_, s) => pagina(s, const InicioScreen())),
          GoRoute(
            path: '/mapa',
            pageBuilder: (_, s) {
              final q = s.uri.queryParameters;
              final lat = double.tryParse(q['lat'] ?? '');
              final lng = double.tryParse(q['lng'] ?? '');
              // La página se conserva al cambiar la consulta; MapaScreen reacciona a los nuevos parámetros.
              return NoTransitionPage(
                key: const ValueKey('mapa'),
                child: MapaScreen(
                  foco: lat != null && lng != null ? LatLng(lat, lng) : null,
                  incidenteId: q['incidente'],
                  zona: q['zona'],
                  busqueda: q['q'],
                ),
              );
            },
          ),
          GoRoute(path: '/notificaciones', pageBuilder: (_, s) => pagina(s, const NotificacionesScreen())),
          GoRoute(path: '/sos', pageBuilder: (_, s) => pagina(s, const SosScreen())),
          GoRoute(
            path: '/reporte',
            pageBuilder: (_, s) => pagina(s, const ReporteScreen()),
            routes: [
              GoRoute(path: 'enviado/:id', pageBuilder: (_, s) => pagina(s, ReporteEnviadoScreen(id: s.pathParameters['id']!))),
              GoRoute(path: 'estado/:id', pageBuilder: (_, s) => pagina(s, EstadoReporteScreen(id: s.pathParameters['id']!))),
              GoRoute(path: 'sin-conexion', pageBuilder: (_, s) => pagina(s, const SinConexionScreen())),
            ],
          ),
          GoRoute(
            path: '/alertas',
            pageBuilder: (_, s) => pagina(s, const AlertasScreen()),
            routes: [
              GoRoute(path: 'configurar', pageBuilder: (_, s) => pagina(s, const ConfigurarAlertasScreen())),
              GoRoute(path: ':id', pageBuilder: (_, s) => pagina(s, DetalleAlertaScreen(id: s.pathParameters['id']!))),
            ],
          ),
          GoRoute(path: '/mis-reportes', pageBuilder: (_, s) => pagina(s, const MisReportesScreen())),
          GoRoute(
            path: '/perfil',
            pageBuilder: (_, s) => pagina(s, const PerfilScreen()),
            routes: [
              GoRoute(path: 'editar', pageBuilder: (_, s) => pagina(s, const EditarPerfilScreen())),
              GoRoute(path: 'ajustes', pageBuilder: (_, s) => pagina(s, const AjustesScreen())),
              GoRoute(path: 'privacidad', pageBuilder: (_, s) => pagina(s, const PrivacidadScreen())),
              GoRoute(path: 'ayuda', pageBuilder: (_, s) => pagina(s, const AyudaScreen())),
              GoRoute(
                path: 'vehiculos',
                pageBuilder: (_, s) => pagina(s, const VehiculosScreen()),
                routes: [GoRoute(path: 'agregar', pageBuilder: (_, s) => pagina(s, const AgregarVehiculoScreen()))],
              ),
              GoRoute(
                path: 'zonas',
                pageBuilder: (_, s) => pagina(s, const ZonasFavoritasScreen()),
                routes: [GoRoute(path: 'agregar', pageBuilder: (_, s) => pagina(s, const AgregarZonaScreen()))],
              ),
            ],
          ),
          GoRoute(path: '/dev', pageBuilder: (_, s) => pagina(s, const DevScreen())),
          GoRoute(path: '/autoridad', pageBuilder: (_, s) => pagina(s, const AutoridadScreen())),
        ],
      ),
    ],
  );
});
