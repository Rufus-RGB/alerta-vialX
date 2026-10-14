import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/botones.dart';
import '../../../widgets/logo_alerta.dart';
import '../domain/usuario.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  Rol _rol = Rol.ciudadano;
  bool _cargando = false;
  bool _verClave = false;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await ref.read(authControllerProvider.notifier).iniciarSesion(
            correo: _correo.text,
            clave: _clave.text,
            rol: _rol,
          );
      // El router redirige a la pantalla de inicio del rol.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LogoAlerta(tamano: 80)),
                    const SizedBox(height: 20),
                    Text('Bienvenido a Alerta Vial', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Inicia sesión para reportar y recibir alertas.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    Text('Ingresar como', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    _SelectorRol(seleccionado: _rol, onChanged: (r) => setState(() => _rol = r)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_rounded)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clave,
                      obscureText: !_verClave,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                          icon: Icon(_verClave ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          onPressed: () => setState(() => _verClave = !_verClave),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                    ),
                    const SizedBox(height: 24),
                    BotonPrincipal(
                      texto: 'Iniciar sesión',
                      cargando: _cargando,
                      color: _rol.color,
                      onPressed: _entrar,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Modo demo: cualquier correo y contraseña funcionan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorRol extends StatelessWidget {
  const _SelectorRol({required this.seleccionado, required this.onChanged});

  final Rol seleccionado;
  final ValueChanged<Rol> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final rol in Rol.values) ...[
          if (rol != Rol.values.first) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: rol == seleccionado ? rol.color : scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: rol == seleccionado ? rol.color : scheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onChanged(rol),
                child: Semantics(
                  selected: rol == seleccionado,
                  button: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Icon(rol.icono, color: rol == seleccionado ? Colors.white : rol.color),
                        const SizedBox(height: 6),
                        Text(
                          rol.etiqueta,
                          style: GoogleFonts.mPlusRounded1c(
                            fontWeight: FontWeight.w800,
                            color: rol == seleccionado ? Colors.white : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
