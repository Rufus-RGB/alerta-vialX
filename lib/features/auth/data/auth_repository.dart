import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/usuario.dart';

/// Contrato de autenticación. La implementación real hablará con la API (dio).
abstract interface class AuthRepository {
  Future<Usuario> iniciarSesion({required String correo, required String clave, required Rol rol});
  Future<Usuario?> sesionGuardada();
  Future<void> cerrarSesion();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());

/// Repositorio falso: acepta cualquier correo con clave no vacía.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _prefijo = 'sesion_';

  @override
  Future<Usuario> iniciarSesion({required String correo, required String clave, required Rol rol}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (correo.trim().isEmpty || clave.isEmpty) {
      throw const AuthException('Ingresa tu correo y contraseña.');
    }
    final nombre = correo.split('@').first;
    final usuario = Usuario(
      id: 'mock-${rol.name}',
      nombre: nombre.isEmpty ? 'Usuario' : '${nombre[0].toUpperCase()}${nombre.substring(1)}',
      correo: correo.trim(),
      rol: rol,
    );
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
      for (final k in ['id', 'nombre', 'correo', 'rol']) {
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
