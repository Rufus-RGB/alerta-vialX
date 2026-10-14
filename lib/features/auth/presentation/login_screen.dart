import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/campos.dart';
import '../../../widgets/logo_alerta.dart';
import '../domain/usuario.dart';
import 'auth_controller.dart';

/// Login con selector de rol. Celular: diseño "Login Screen"; tablet/PC: panel dividido.
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

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() => _cargando = true);
    try {
      await accion();
      // El router redirige a la pantalla de inicio del rol.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _entrar() {
    if (!_formKey.currentState!.validate()) return;
    _ejecutar(() => ref.read(authControllerProvider.notifier).iniciarSesion(correo: _correo.text, clave: _clave.text, rol: _rol));
  }

  void _social(String proveedor) => _ejecutar(() => ref.read(authControllerProvider.notifier).iniciarConProveedor(proveedor));

  String? _validarCorreo(String? v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null;
  String? _validarClave(String? v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null;

  @override
  Widget build(BuildContext context) {
    final ancho = !context.esCelular;
    return Scaffold(
      backgroundColor: ancho ? context.paleta.fondoPanel : null,
      body: Form(
        key: _formKey,
        child: AutofillGroup(child: ancho ? _dividido(context) : _celular(context)),
      ),
    );
  }

  // ---------- Celular ----------
  Widget _celular(BuildContext context) {
    final p = context.paleta;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 40, 18, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 392),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: LogoAlerta()),
                const SizedBox(height: 12),
                Text('Tu ciudad más segura', textAlign: TextAlign.center, style: Txt.n(15, color: p.textoSecundario)),
                const SizedBox(height: 52),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _SelectorRolBotones(seleccionado: _rol, onChanged: (r) => setState(() => _rol = r)),
                ),
                const SizedBox(height: 70),
                _InputLogin(
                  controller: _correo,
                  hint: 'Usuario o Correo electronico',
                  icono: TablerIcons.mail_filled,
                  teclado: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  validator: _validarCorreo,
                ),
                const SizedBox(height: 35),
                _InputLogin(
                  controller: _clave,
                  hint: 'Contraseña',
                  icono: TablerIcons.lock,
                  contrasena: true,
                  autofill: const [AutofillHints.password],
                  validator: _validarClave,
                  onSubmitted: (_) => _entrar(),
                ),
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/recuperar'),
                    child: Text('¿Olvidaste tu contraseña?', style: Txt.nb(13, color: p.texto)),
                  ),
                ),
                const SizedBox(height: 36),
                BotonPrincipal(texto: 'Iniciar Sesión', onPressed: _entrar, cargando: _cargando, color: AppColors.rojoIntenso, alto: 56, tamanoTexto: 16),
                const SizedBox(height: 40),
                const _Separador(texto: 'O continua con'),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(child: _BotonSocial(proveedor: 'Google', alto: 88, onTap: () => _social('google'))),
                    const SizedBox(width: 18),
                    Expanded(child: _BotonSocial(proveedor: 'Apple', alto: 88, onTap: () => _social('apple'))),
                  ],
                ),
                const SizedBox(height: 22),
                EnlaceTexto(pregunta: '¿No tienes cuenta?', accion: 'Crear cuenta', onTap: () => context.push('/registro')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Tablet / PC ----------
  Widget _dividido(BuildContext context) {
    final p = context.paleta;
    final esPc = context.pantalla == TipoPantalla.escritorio;
    final formulario = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bienvenido', style: Txt.r(32, color: p.texto)),
              Text('Elige tu rol e inicia sesión', style: Txt.n(15, color: p.textoSecundario)),
              const SizedBox(height: 20),
              _SelectorRolSegmentado(seleccionado: _rol, onChanged: (r) => setState(() => _rol = r)),
              const SizedBox(height: 26),
              CampoEtiquetado(
                etiqueta: 'Correo electrónico',
                hint: 'nombre@correo.com',
                icono: TablerIcons.mail,
                controller: _correo,
                teclado: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                accionTeclado: TextInputAction.next,
                validator: _validarCorreo,
              ),
              const SizedBox(height: 14),
              CampoEtiquetado(
                etiqueta: 'Contraseña',
                hint: '••••••••',
                icono: TablerIcons.lock,
                controller: _clave,
                contrasena: true,
                autofill: const [AutofillHints.password],
                validator: _validarClave,
                onSubmitted: (_) => _entrar(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/recuperar'),
                  child: Text('¿Olvidaste tu contraseña?', style: Txt.nb(13, color: AppColors.rojo)),
                ),
              ),
              const SizedBox(height: 8),
              BotonPrincipal(texto: 'Iniciar sesión', onPressed: _entrar, cargando: _cargando, alto: 48, tamanoTexto: 16),
              const SizedBox(height: 28),
              const _Separador(texto: 'o continúa con', fino: true),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _BotonSocial(proveedor: 'Google', alto: 48, compacto: true, onTap: () => _social('google'))),
                  const SizedBox(width: 16),
                  Expanded(child: _BotonSocial(proveedor: 'Apple', alto: 48, compacto: true, onTap: () => _social('apple'))),
                ],
              ),
              const SizedBox(height: 32),
              EnlaceTexto(pregunta: '¿No tienes cuenta?', accion: 'Crear cuenta', onTap: () => context.push('/registro')),
            ],
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          flex: esPc ? 1 : 9,
          child: ColoredBox(
            color: AppColors.fondoOscuro,
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: c.maxHeight * 0.44,
                    child: ClipRect(
                      child: OverflowBox(
                        maxWidth: c.maxWidth * 1.45,
                        minWidth: c.maxWidth * 1.45,
                        alignment: const Alignment(-0.3, 1),
                        child: Image.asset('assets/images/ilustracion_bogota.png', fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(56, 56, 40, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LogoAlerta(tamano: 52, colorTexto: Colors.white),
                        const SizedBox(height: 44),
                        Text('Tu ciudad', style: Txt.display(esPc ? 60 : 48, color: Colors.white)),
                        Text('más segura', style: Txt.display(esPc ? 60 : 48, color: AppColors.rojo)),
                        const SizedBox(height: 28),
                        Text(
                          'Reporta hurtos, mira las zonas de riesgo y recibe alertas en tiempo real.',
                          style: Txt.n(17, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(flex: esPc ? 1 : 10, child: formulario),
      ],
    );
  }
}

/// Input del login de celular: 60 px, borde gris #A8A8A8 y placeholder redondeado de 12 px.
class _InputLogin extends StatefulWidget {
  const _InputLogin({
    required this.controller,
    required this.hint,
    required this.icono,
    this.contrasena = false,
    this.teclado,
    this.autofill,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icono;
  final bool contrasena;
  final TextInputType? teclado;
  final Iterable<String>? autofill;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_InputLogin> createState() => _InputLoginState();
}

class _InputLoginState extends State<_InputLogin> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final borde = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA8A8A8)));
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.contrasena && _oculto,
      keyboardType: widget.teclado,
      autofillHints: widget.autofill,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      textInputAction: widget.contrasena ? TextInputAction.done : TextInputAction.next,
      style: Txt.n(14, color: p.texto),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: Txt.r(12, color: const Color(0xFFA8A8A8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 21),
        prefixIcon: Icon(widget.icono, size: 18, color: const Color(0xFF8A8A8A)),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        suffixIcon: widget.contrasena
            ? IconButton(
                tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(_oculto ? TablerIcons.eye : TablerIcons.eye_off, size: 20),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
        border: borde,
        enabledBorder: borde,
      ),
    );
  }
}

/// Tres botones de rol de 56 px (celular). Activo con el color del rol; inactivos grises.
class _SelectorRolBotones extends StatelessWidget {
  const _SelectorRolBotones({required this.seleccionado, required this.onChanged});

  final Rol seleccionado;
  final ValueChanged<Rol> onChanged;

  @override
  Widget build(BuildContext context) {
    final inactivo = context.esOscuro ? const Color(0xFF1B2227) : const Color(0xFFD9D9D9);
    return Row(
      children: [
        for (final rol in Rol.values) ...[
          if (rol != Rol.values.first) const SizedBox(width: 18),
          Expanded(
            child: Semantics(
              selected: rol == seleccionado,
              button: true,
              child: Material(
                color: rol == seleccionado ? (rol == Rol.ciudadano ? AppColors.amarilloRol : rol.color) : inactivo,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onChanged(rol),
                  child: SizedBox(
                    height: 56,
                    child: Center(child: Text(rol.etiqueta, style: Txt.r(16, color: Colors.white))),
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

/// Selector segmentado de rol (tablet/PC): fondo gris claro y segmento activo de color.
class _SelectorRolSegmentado extends StatelessWidget {
  const _SelectorRolSegmentado({required this.seleccionado, required this.onChanged});

  final Rol seleccionado;
  final ValueChanged<Rol> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: context.esOscuro ? p.chip : const Color(0xFFECEEF0), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final rol in Rol.values)
            Expanded(
              child: Semantics(
                selected: rol == seleccionado,
                button: true,
                child: Material(
                  color: rol == seleccionado ? rol.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(rol),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          rol.etiqueta,
                          style: rol == seleccionado ? Txt.nb(14, color: rol.sobreColor) : Txt.n(14, color: p.textoSecundario),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador({required this.texto, this.fino = false});

  final String texto;
  final bool fino;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final linea = Expanded(child: Divider(color: fino ? p.borde : const Color(0xFF8A8A8A)));
    return Row(
      children: [
        linea,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(texto, style: fino ? Txt.n(13, color: p.textoSecundario) : Txt.nb(13, color: p.texto)),
        ),
        linea,
      ],
    );
  }
}

class _BotonSocial extends StatelessWidget {
  const _BotonSocial({required this.proveedor, required this.alto, required this.onTap, this.compacto = false});

  final String proveedor;
  final double alto;
  final bool compacto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final logo = proveedor == 'Google'
        ? SvgPicture.asset('assets/icons/logo_google.svg', width: 38, height: 38)
        : SvgPicture.asset(
            'assets/icons/logo_apple.svg',
            width: 30,
            height: 38,
            colorFilter: ColorFilter.mode(p.texto, BlendMode.srcIn),
          );
    return Material(
      color: p.tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: compacto ? p.inputBorde : (context.esOscuro ? p.borde : const Color(0xFFE6E6E6)), width: compacto ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: alto,
          child: compacto
              ? Center(child: Text(proveedor, style: Txt.r(16, color: p.texto)))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [logo, const SizedBox(height: 6), Text(proveedor, style: Txt.r(13, color: p.texto))],
                ),
        ),
      ),
    );
  }
}
