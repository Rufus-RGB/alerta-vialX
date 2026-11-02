import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/supabase/supabase_config.dart';
import '../domain/usuario.dart';

/// Contrato de autenticación. Hay una versión de ejemplo (mock) y otra con Supabase Auth.
abstract interface class AuthRepository {
  Future<Usuario> iniciarSesion({required String correo, required String clave, required Rol rol});

  /// Inicia sesión con Google o Apple. Con Supabase en web redirige y la sesión llega por [cambios].
  Future<Usuario?> iniciarConProveedor(String proveedor);

  /// Crea la cuenta de ciudadano. Lanza [ConfirmacionPendiente] si hay que confirmar el correo.
  Future<Usuario> registrar({required String nombre, required String correo, required String celular, required String clave});

  Future<void> enviarCodigoRecuperacion(String correo);
  Future<void> verificarCodigoRecuperacion({required String correo, required String codigo});
  Future<void> cambiarClave(String nueva);

  /// Crea una cuenta de autoridad pendiente de aprobación con su carné (clave de [ArchivosLocales]).
  Future<void> solicitarCuentaAutoridad({
    required String nombre,
    required String correo,
    required String clave,
    required String placa,
    required String unidad,
    required String carne,
  });

  Future<Usuario?> sesionGuardada();
  Future<Usuario> actualizarPerfil(Usuario usuario, {String? localidad});
  Future<void> cerrarSesion();

  /// Cambios de sesión (login por redirección, cierre de sesión en otra pestaña…). Vacío en el mock.
  Stream<Usuario?> cambios();

  /// Cantidad de dígitos del código de recuperación (Supabase envía 6).
  int get digitosCodigo;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseConfig.habilitado ? SupabaseAuthRepository() : MockAuthRepository(),
);

class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// La cuenta se creó pero hay que confirmar el correo antes de entrar.
class ConfirmacionPendiente implements Exception {
  const ConfirmacionPendiente(this.correo);
  final String correo;
  @override
  String toString() => 'Te enviamos un correo a $correo para confirmar tu cuenta. Ábrelo y luego inicia sesión.';
}

// ---------------------------------------------------------------------------
// Mock: acepta cualquier correo con clave no vacía.
// ---------------------------------------------------------------------------
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _prefijo = 'sesion_';
  static const _latencia = Duration(milliseconds: 600);

  @override
  int get digitosCodigo => 4;

  @override
  Stream<Usuario?> cambios() => const Stream.empty();

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
  Future<void> verificarCodigoRecuperacion({required String correo, required String codigo}) => Future<void>.delayed(_latencia);

  @override
  Future<void> cambiarClave(String nueva) => Future<void>.delayed(_latencia);

  @override
  Future<void> solicitarCuentaAutoridad({
    required String nombre,
    required String correo,
    required String clave,
    required String placa,
    required String unidad,
    required String carne,
  }) =>
      Future<void>.delayed(_latencia);

  @override
  Future<Usuario> actualizarPerfil(Usuario usuario, {String? localidad}) => _guardar(usuario);

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

// ---------------------------------------------------------------------------
// Supabase Auth + tabla `perfiles`.
// ---------------------------------------------------------------------------
class SupabaseAuthRepository implements AuthRepository {
  sb.GoTrueClient get _auth => supa.auth;

  @override
  int get digitosCodigo => 6;

  /// Destino de las redirecciones de OAuth y correos (web: la misma página; Android: deep link).
  static String get _redireccion => kIsWeb ? Uri.base.origin + Uri.base.path : 'co.alertavial.alerta_vial://login-callback';

  Future<Usuario> _perfil(String id) async {
    final fila = await supa.from('perfiles').select().eq('id', id).maybeSingle();
    if (fila == null) throw const AuthException('No encontramos tu perfil. Intenta de nuevo en unos segundos.');
    final rol = Rol.values.byName(fila['rol'] as String);
    final estado = fila['estado'] as String;
    if (estado == 'bloqueado') {
      await _auth.signOut();
      throw const AuthException('Tu cuenta está bloqueada. Escríbenos desde el Centro de ayuda.');
    }
    if (estado == 'pendiente') {
      await _auth.signOut();
      throw const AuthException('Tu cuenta de autoridad está en revisión. Te avisaremos por correo cuando sea aprobada.');
    }
    return Usuario(id: id, nombre: fila['nombre'] as String? ?? '', correo: fila['correo'] as String? ?? '', rol: rol, celular: fila['celular'] as String? ?? '');
  }

  String _mensaje(Object e) {
    if (e is sb.AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Correo o contraseña incorrectos.';
      if (m.contains('email not confirmed')) return 'Confirma tu correo antes de iniciar sesión (revisa tu bandeja de entrada).';
      if (m.contains('already registered') || m.contains('already been registered')) return 'Ese correo ya tiene una cuenta. Inicia sesión.';
      if (m.contains('password')) return 'La contraseña no cumple los requisitos (mínimo 8 caracteres).';
      if (m.contains('token') || m.contains('otp')) return 'El código no es válido o ya venció.';
      return e.message;
    }
    if (e is AuthException) return e.mensaje;
    return 'No pudimos conectar con el servidor. Revisa tu internet.';
  }

  Future<T> _intentar<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on AuthException {
      rethrow;
    } on ConfirmacionPendiente {
      rethrow;
    } catch (e) {
      throw AuthException(_mensaje(e));
    }
  }

  @override
  Future<Usuario> iniciarSesion({required String correo, required String clave, required Rol rol}) => _intentar(() async {
        final r = await _auth.signInWithPassword(email: correo.trim(), password: clave);
        final usuario = await _perfil(r.user!.id);
        if (usuario.rol != rol) {
          await _auth.signOut();
          throw AuthException('Esta cuenta es de tipo ${usuario.rol.etiqueta}. Elige "${usuario.rol.etiqueta}" para entrar.');
        }
        return usuario;
      });

  @override
  Future<Usuario?> iniciarConProveedor(String proveedor) => _intentar(() async {
        await _auth.signInWithOAuth(
          proveedor == 'apple' ? sb.OAuthProvider.apple : sb.OAuthProvider.google,
          redirectTo: _redireccion,
        );
        // La sesión llega por [cambios] al volver de la redirección.
        return null;
      });

  @override
  Future<Usuario> registrar({required String nombre, required String correo, required String celular, required String clave}) =>
      _intentar(() async {
        final r = await _auth.signUp(
          email: correo.trim(),
          password: clave,
          emailRedirectTo: _redireccion,
          data: {'nombre': nombre.trim(), 'celular': celular.trim(), 'rol': 'ciudadano'},
        );
        if (r.session == null) throw ConfirmacionPendiente(correo.trim());
        return _perfil(r.user!.id);
      });

  @override
  Future<void> enviarCodigoRecuperacion(String correo) => _intentar(() => _auth.resetPasswordForEmail(correo.trim(), redirectTo: _redireccion));

  @override
  Future<void> verificarCodigoRecuperacion({required String correo, required String codigo}) =>
      _intentar(() => _auth.verifyOTP(email: correo.trim(), token: codigo, type: sb.OtpType.recovery));

  @override
  Future<void> cambiarClave(String nueva) => _intentar(() => _auth.updateUser(sb.UserAttributes(password: nueva)));

  @override
  Future<void> solicitarCuentaAutoridad({
    required String nombre,
    required String correo,
    required String clave,
    required String placa,
    required String unidad,
    required String carne,
  }) =>
      _intentar(() async {
        final r = await _auth.signUp(
          email: correo.trim(),
          password: clave,
          emailRedirectTo: _redireccion,
          data: {'nombre': nombre.trim(), 'rol': 'autoridad'},
        );
        final uid = r.user!.id;
        // Con sesión (confirmación de correo desactivada) el carné va a la carpeta del usuario;
        // sin sesión, a `pendientes/<uid>/`, permitido solo para cuentas de autoridad pendientes.
        String? ruta;
        final archivo = ArchivosLocales.obtener(carne);
        if (archivo != null) {
          ruta = r.session != null ? '$uid/$carne' : 'pendientes/$uid/$carne';
          await supa.storage.from('carnes').uploadBinary(ruta, await archivo.readAsBytes(), fileOptions: const sb.FileOptions(upsert: true));
        }
        await supa.rpc<void>('crear_solicitud_autoridad', params: {
          'p_usuario': uid,
          'p_nombre': nombre.trim(),
          'p_correo': correo.trim(),
          'p_unidad': unidad,
          'p_placa': placa.trim(),
          'p_carne': ruta,
        });
        await _auth.signOut();
      });

  @override
  Future<Usuario?> sesionGuardada() async {
    final usuario = _auth.currentUser;
    if (usuario == null) return null;
    try {
      return await _perfil(usuario.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Usuario> actualizarPerfil(Usuario usuario, {String? localidad}) => _intentar(() async {
        await supa.from('perfiles').update({
          'nombre': usuario.nombre,
          'celular': usuario.celular,
          'localidad': ?localidad,
        }).eq('id', usuario.id);
        if (usuario.correo != _auth.currentUser?.email) {
          await _auth.updateUser(sb.UserAttributes(email: usuario.correo));
        }
        return usuario;
      });

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  @override
  Stream<Usuario?> cambios() => _auth.onAuthStateChange.asyncMap((e) async {
        final sesion = e.session;
        if (sesion == null) return null;
        try {
          return await _perfil(sesion.user.id);
        } catch (_) {
          return null;
        }
      });
}
