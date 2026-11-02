import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/campos.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'pantalla_acceso.dart';

/// Recuperar contraseña: correo + código (4 dígitos en el mock, 6 con Supabase) con reenvío en 0:45.
class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  late final int _n = ref.read(authRepositoryProvider).digitosCodigo;
  late final _digitos = List.generate(_n, (_) => TextEditingController());
  late final _focos = List.generate(_n, (_) => FocusNode());
  final _nueva = TextEditingController();
  bool _enviado = false;
  bool _cargando = false;
  int _segundos = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _correo.dispose();
    _nueva.dispose();
    for (final c in _digitos) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  void _iniciarConteo() {
    _timer?.cancel();
    setState(() => _segundos = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundos <= 1) t.cancel();
      setState(() => _segundos--);
    });
  }

  Future<void> _enviarCodigo() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cargando = true);
    try {
      await ref.read(authRepositoryProvider).enviarCodigoRecuperacion(_correo.text);
      if (!mounted) return;
      setState(() => _enviado = true);
      _iniciarConteo();
      _focos.first.requestFocus();
      messenger.showSnackBar(SnackBar(content: Text('Enviamos un código a ${_correo.text}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _accion() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_enviado) return _enviarCodigo();
    final messenger = ScaffoldMessenger.of(context);
    final codigo = _digitos.map((c) => c.text).join();
    if (codigo.length < _n) {
      messenger.showSnackBar(SnackBar(content: Text('Escribe los $_n dígitos del código.')));
      return;
    }
    if (_nueva.text.length < 8) {
      messenger.showSnackBar(const SnackBar(content: Text('La nueva contraseña debe tener mínimo 8 caracteres.')));
      return;
    }
    setState(() => _cargando = true);
    try {
      await ref.read(authControllerProvider.notifier).recuperarClave(correo: _correo.text, codigo: codigo, nueva: _nueva.text);
      messenger.showSnackBar(const SnackBar(content: Text('Contraseña actualizada. Inicia sesión con la nueva.'), backgroundColor: AppColors.verdeExito));
      if (mounted) context.go('/login');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PantallaAcceso(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: p.suaveAmarillo, shape: BoxShape.circle),
                child: const Icon(TablerIcons.key, size: 48, color: AppColors.amarillo),
              ),
            ),
            const SizedBox(height: 26),
            Text('¿Olvidaste tu contraseña?', textAlign: TextAlign.center, style: Txt.r(24, color: p.texto)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                'Escribe tu correo y te enviaremos un código para crear una nueva.',
                textAlign: TextAlign.center,
                style: Txt.n(15, color: p.textoSecundario),
              ),
            ),
            const SizedBox(height: 34),
            CampoEtiquetado(
              etiqueta: 'Correo electrónico',
              hint: 'nombre@correo.com',
              icono: TablerIcons.mail,
              controller: _correo,
              teclado: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
            ),
            const SizedBox(height: 18),
            Padding(padding: const EdgeInsets.only(left: 6, bottom: 4), child: Text('Código de verificación', style: Txt.r(15, color: p.texto))),
            Row(
              children: [
                for (var i = 0; i < _n; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _Digito(controller: _digitos[i], foco: _focos[i], siguiente: i < _n - 1 ? _focos[i + 1] : null, habilitado: _enviado)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: _segundos > 0
                  ? Text('Reenviar código en 0:${_segundos.toString().padLeft(2, '0')}', style: Txt.n(13, color: p.textoSecundario))
                  : TextButton(
                      onPressed: _enviado ? _enviarCodigo : null,
                      child: Text(_enviado ? 'Reenviar código' : 'Te enviaremos $_n dígitos', style: Txt.n(13, color: p.textoSecundario)),
                    ),
            ),
            if (_enviado) ...[
              const SizedBox(height: 14),
              CampoEtiquetado(
                etiqueta: 'Nueva contraseña',
                hint: 'Mínimo 8 caracteres',
                icono: TablerIcons.lock,
                controller: _nueva,
                contrasena: true,
                autofill: const [AutofillHints.newPassword],
              ),
            ],
            const SizedBox(height: 32),
            BotonPrincipal(texto: _enviado ? 'Cambiar contraseña' : 'Enviar código', onPressed: _accion, cargando: _cargando),
            const SizedBox(height: 10),
            EnlaceTexto(pregunta: '¿La recordaste?', accion: 'Inicia sesión', onTap: () => context.go('/login')),
          ],
        ),
      ),
    );
  }
}

class _Digito extends StatelessWidget {
  const _Digito({required this.controller, required this.foco, required this.siguiente, required this.habilitado});

  final TextEditingController controller;
  final FocusNode foco;
  final FocusNode? siguiente;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: foco,
        enabled: habilitado,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Txt.r(24, color: p.texto),
        onChanged: (v) {
          if (v.isNotEmpty) siguiente?.requestFocus();
        },
        decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.symmetric(vertical: 12)),
      ),
    );
  }
}
