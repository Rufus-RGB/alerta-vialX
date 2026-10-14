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
  @override
  AuthState build() {
    _restaurar();
    return const AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

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
    state = AuthState(inicializado: true, usuario: usuario);
  }

  Future<void> registrar({required String nombre, required String correo, required String celular, required String clave}) async {
    final usuario = await _repo.registrar(nombre: nombre, correo: correo, celular: celular, clave: clave);
    state = AuthState(inicializado: true, usuario: usuario, mostrarPermisos: true);
  }

  void permisosVistos() => state = AuthState(inicializado: true, usuario: state.usuario);

  void actualizarUsuario(Usuario usuario) => state = AuthState(inicializado: true, usuario: usuario);

  Future<void> cerrarSesion() async {
    await _repo.cerrarSesion();
    state = const AuthState(inicializado: true);
  }
}
