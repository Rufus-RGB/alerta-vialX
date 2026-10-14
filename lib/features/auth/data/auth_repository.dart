import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/usuario.dart';

/// Contrato de autenticación. La implementación real hablará con la API (FastAPI) vía dio.
abstract interface class AuthRepository {
  Future<Usuario> iniciarSesion({required String correo, required String clave, required Rol rol});
  Future<Usuario> iniciarConProveedor(String proveedor);
  Future<Usuario> registrar({required String nombre, required String correo, required String celular, required String clave});
  Future<void> enviarCodigoRecuperacion(String correo);
  Future<void> solicitarCuentaAutoridad({required String correo, required String placa, required String unidad});
  Future<Usuario?> sesionGuardada();
  Future<void> cerrarSesion();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());

/// Repositorio falso: acepta cualquier correo con clave no vacía.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _prefijo = 'sesion_';
  static const _latencia = Duration(milliseconds: 600);

  String _nombreDesdeCorreo(String correo) {
    final base = correo.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (base.isEmpty) return 'User';
    return base.split(' ').map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }

  @override
  Future<Usuario> iniciarSesion({required String correo, required String clave, required Rol rol}) async {
    await Future<void>.delayed(_latencia);
    if (correo.trim().isEmpty || clave.isEmpty) {
      throw const AuthException('Ingresa tu correo y contraseña.');
    }
    return _guardar(Usuario(id: 'mock-${rol.name}', nombre: _nombreDesdeCorreo(correo), correo: correo.trim(), rol: rol));
  }

  @override
  Future<Usuario> iniciarConProveedor(String proveedor) async {
    await Future<void>.delayed(_latencia);
    return _guardar(Usuario(id: 'mock-$proveedor', nombre: 'User', correo: 'user@$proveedor.com', rol: Rol.ciudadano));
  }

  @override
  Future<Usuario> registrar({required String nombre, required String correo, required String celular, required String clave}) async {
    await Future<void>.delayed(_latencia);
    if (clave.length < 8) throw const AuthException('La contraseña debe tener mínimo 8 caracteres.');
    return _guardar(Usuario(id: 'mock-nuevo', nombre: nombre.trim(), correo: correo.trim(), rol: Rol.ciudadano, celular: celular));
  }

  @override
  Future<void> enviarCodigoRecuperacion(String correo) => Future<void>.delayed(_latencia);

  @override
  Future<void> solicitarCuentaAutoridad({required String correo, required String placa, required String unidad}) =>
      Future<void>.delayed(_latencia);

  Future<Usuario> _guardar(Usuario usuario) async {
    try {
      for (final e in usuario.toMap().entries) {
        await _storage.write(key: '$_prefijo${e.key}', value: e.value);
      }
    } catch (_) {
      // El almacenamiento seguro puede fallar en web sin contexto seguro; la sesión sigue en memoria.
    }
    return usuario;
  }

  @override
  Future<Usuario?> sesionGuardada() async {
    try {
      final todo = await _storage.readAll();
      final mapa = {
        for (final e in todo.entries)
          if (e.key.startsWith(_prefijo)) e.key.substring(_prefijo.length): e.value,
      };
      return Usuario.fromMap(mapa);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      for (final k in ['id', 'nombre', 'correo', 'rol', 'celular']) {
        await _storage.delete(key: '$_prefijo$k');
      }
    } catch (_) {}
  }
}

class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}
