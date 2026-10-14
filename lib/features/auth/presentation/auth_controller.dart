import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/usuario.dart';

class AuthState {
  const AuthState({this.inicializado = false, this.usuario});

  /// false mientras se restaura la sesión (se muestra el Splash).
  final bool inicializado;
  final Usuario? usuario;
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
      Future<void>.delayed(const Duration(milliseconds: 1400)), // tiempo mínimo de Splash
    ]);
    state = AuthState(inicializado: true, usuario: resultados.first as Usuario?);
  }

  Future<void> iniciarSesion({required String correo, required String clave, required Rol rol}) async {
    final usuario = await _repo.iniciarSesion(correo: correo, clave: clave, rol: rol);
    state = AuthState(inicializado: true, usuario: usuario);
  }

  Future<void> cerrarSesion() async {
    await _repo.cerrarSesion();
    state = const AuthState(inicializado: true);
  }
}
