import 'package:alerta_vial/core/router/app_router.dart';
import 'package:alerta_vial/features/auth/domain/usuario.dart';
import 'package:alerta_vial/features/auth/presentation/auth_controller.dart';
import 'package:alerta_vial/features/mapa/domain/modelos_mapa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Usuario u(Rol rol) => Usuario(id: '1', nombre: 'Ana', correo: 'ana@x.co', rol: rol);

  group('redireccionPorRol', () {
    test('muestra splash mientras no se inicializa', () {
      expect(redireccionPorRol(const AuthState(), '/inicio'), '/splash');
      expect(redireccionPorRol(const AuthState(), '/splash'), isNull);
    });

    test('sin sesión va a login', () {
      expect(redireccionPorRol(const AuthState(inicializado: true), '/mapa'), '/login');
    });

    test('cada rol aterriza en su inicio', () {
      for (final rol in Rol.values) {
        expect(redireccionPorRol(AuthState(inicializado: true, usuario: u(rol)), '/login'), rol.rutaInicio);
      }
    });

    test('bloquea rutas de otro rol', () {
      final ciudadano = AuthState(inicializado: true, usuario: u(Rol.ciudadano));
      expect(redireccionPorRol(ciudadano, '/dev'), '/inicio');
      expect(redireccionPorRol(ciudadano, '/mapa'), isNull);
      final dev = AuthState(inicializado: true, usuario: u(Rol.dev));
      expect(redireccionPorRol(dev, '/inicio'), '/dev');
    });
  });

  test('filtro de vehículos', () {
    expect(FiltroVehiculo.motos.incluye(TipoVehiculo.auto), isFalse);
    expect(FiltroVehiculo.todas.incluye(TipoVehiculo.auto), isTrue);
  });
}
