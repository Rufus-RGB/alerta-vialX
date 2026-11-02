import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/usuario.dart';

class AuthState {
  const AuthState({this.inicializado = false, this.usuario, this.mostrarPermisos = false});

  /// false mientras se restaura la sesión (se muestran Splash y Carga).
  final bool inicializado;
  final Usuario? usuario;

  /// true justo después de crear cuenta: se muestra la pantalla de Permisos.
  final bool mostrarPermisos;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  StreamSubscription<Usuario?>? _suscripcion;
  bool _ignorarCambios = false;

  @override
  AuthState build() {
    _suscripcion = _repo.cambios().listen(_alCambiar);
    ref.onDispose(() => _suscripcion?.cancel());
    _restaurar();
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Sesión que llega desde Supabase (login con Google, enlace de correo, cierre en otra pestaña…).
  void _alCambiar(Usuario? usuario) {
    if (!state.inicializado || _ignorarCambios) return;
    if (usuario?.id == state.usuario?.id && usuario?.rol == state.usuario?.rol) return;
    state = AuthState(inicializado: true, usuario: usuario, mostrarPermisos: state.mostrarPermisos && usuario != null);
  }

  Future<void> _restaurar() async {
    final resultados = await Future.wait([
      _repo.sesionGuardada(),
      Future<void>.delayed(const Duration(milliseconds: 2600)), // Splash + Carga
    ]);
    state = AuthState(inicializado: true, usuario: resultados.first as Usuario?);
  }

  Future<void> iniciarSesion({required String correo, required String clave, required Rol rol}) async {
    final usuario = await _repo.iniciarSesion(correo: correo, clave: clave, rol: rol);
    state = AuthState(inicializado: true, usuario: usuario);
  }

  Future<void> iniciarConProveedor(String proveedor) async {
    final usuario = await _repo.iniciarConProveedor(proveedor);
    if (usuario != null) state = AuthState(inicializado: true, usuario: usuario);
  }

  /// Lanza [ConfirmacionPendiente] si Supabase exige confirmar el correo.
  Future<void> registrar({required String nombre, required String correo, required String celular, required String clave}) async {
    final usuario = await _repo.registrar(nombre: nombre, correo: correo, celular: celular, clave: clave);
    state = AuthState(inicializado: true, usuario: usuario, mostrarPermisos: true);
  }

  /// Verifica el código de recuperación, cambia la contraseña y deja la sesión cerrada.
  Future<void> recuperarClave({required String correo, required String codigo, required String nueva}) async {
    _ignorarCambios = true;
    try {
      await _repo.verificarCodigoRecuperacion(correo: correo, codigo: codigo);
      await _repo.cambiarClave(nueva);
      await _repo.cerrarSesion();
    } finally {
      // Los eventos de sesión llegan con retraso: se ignoran unos segundos más.
      Future<void>.delayed(const Duration(seconds: 3), () => _ignorarCambios = false);
    }
  }

  void permisosVistos() => state = AuthState(inicializado: true, usuario: state.usuario);

  Future<void> actualizarUsuario(Usuario usuario, {String? localidad}) async {
    final guardado = await _repo.actualizarPerfil(usuario, localidad: localidad);
    state = AuthState(inicializado: true, usuario: guardado);
  }

  Future<void> cerrarSesion() async {
    await _repo.cerrarSesion();
    state = const AuthState(inicializado: true);
  }
}
