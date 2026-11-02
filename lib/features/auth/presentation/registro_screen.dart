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

/// Crear cuenta (ciudadano). Al terminar se muestran los Permisos.
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _celular = TextEditingController();
  final _clave = TextEditingController();
  bool _acepta = true;
  bool _cargando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _correo, _celular, _clave]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acepta) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes aceptar los Términos y la Política de privacidad.')));
      return;
    }
    setState(() => _cargando = true);
    try {
      await ref.read(authControllerProvider.notifier).registrar(
            nombre: _nombre.text,
            correo: _correo.text,
            celular: _celular.text,
            clave: _clave.text,
          );
    } on ConfirmacionPendiente catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), duration: const Duration(seconds: 6)));
      context.go('/login');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PantallaAcceso(
      titulo: 'Crear cuenta',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text('Únete y ayuda a que Bogotá sea más segura.', style: Txt.n(15, color: p.textoSecundario)),
            ),
            const SizedBox(height: 18),
            CampoEtiquetado(
              etiqueta: 'Nombre completo',
              hint: 'Ej: Laura Gómez',
              icono: TablerIcons.user,
              controller: _nombre,
              autofill: const [AutofillHints.name],
              accionTeclado: TextInputAction.next,
              validator: (v) => (v == null || v.trim().length < 3) ? 'Escribe tu nombre' : null,
            ),
            const SizedBox(height: 6),
            CampoEtiquetado(
              etiqueta: 'Correo electrónico',
              hint: 'nombre@correo.com',
              icono: TablerIcons.mail,
              controller: _correo,
              teclado: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              accionTeclado: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
            ),
            const SizedBox(height: 6),
            CampoEtiquetado(
              etiqueta: 'Celular',
              hint: '300 000 0000',
              icono: TablerIcons.phone,
              controller: _celular,
              teclado: TextInputType.phone,
              autofill: const [AutofillHints.telephoneNumber],
              formatos: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
              accionTeclado: TextInputAction.next,
              validator: (v) => (v == null || v.replaceAll(' ', '').length < 10) ? 'Celular de 10 dígitos' : null,
            ),
            const SizedBox(height: 6),
            CampoEtiquetado(
              etiqueta: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              icono: TablerIcons.lock,
              controller: _clave,
              contrasena: true,
              autofill: const [AutofillHints.newPassword],
              validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
              onSubmitted: (_) => _crear(),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _acepta = !_acepta),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: Checkbox(value: _acepta, onChanged: (v) => setState(() => _acepta = v ?? false)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Acepto los Términos y la Política de privacidad', style: Txt.n(13, color: p.textoSecundario))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            BotonPrincipal(texto: 'Crear cuenta', onPressed: _crear, cargando: _cargando),
            const SizedBox(height: 10),
            EnlaceTexto(pregunta: '¿Ya tienes cuenta?', accion: 'Inicia sesión', onTap: () => context.go('/login')),
            const SizedBox(height: 22),
            Material(
              color: p.suaveAzul,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/verificacion-autoridad'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.shield_check, size: 26, color: AppColors.azulAutoridad),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¿Eres Policía o SIJIN?', style: Txt.nb(15, color: p.texto)),
                            const SizedBox(height: 2),
                            Text('Regístrate con tu correo institucional', style: Txt.n(13, color: p.textoSecundario)),
                          ],
                        ),
                      ),
                      const Icon(TablerIcons.chevron_right, size: 20, color: AppColors.azulAutoridad),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
