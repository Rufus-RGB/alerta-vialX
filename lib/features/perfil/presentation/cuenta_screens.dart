import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/campos.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../data/perfil_repository.dart';

// ---------------- Editar perfil ----------------

class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _form = GlobalKey<FormState>();
  late final Usuario _u;
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  late final TextEditingController _celular;
  late String _localidad;
  String? _foto;

  @override
  void initState() {
    super.initState();
    _u = ref.read(authControllerProvider).usuario!;
    _nombre = TextEditingController(text: _u.nombre);
    _correo = TextEditingController(text: _u.correo);
    _celular = TextEditingController(text: _u.celular.isEmpty ? '300 123 4567' : _u.celular);
    _localidad = ref.read(localidadPerfilProvider);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _celular.dispose();
    super.dispose();
  }

  Future<void> _cambiarFoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (f != null) setState(() => _foto = f.name);
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).actualizarUsuario(
          Usuario(id: _u.id, nombre: _nombre.text.trim(), correo: _correo.text.trim(), rol: _u.rol, celular: _celular.text.trim()),
        );
    ref.read(localidadPerfilProvider.notifier).cambiar(_localidad);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado.'), backgroundColor: AppColors.verdeExito));
    context.canPop() ? context.pop() : context.go('/perfil');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PantallaSecundaria(
      titulo: 'Editar perfil',
      anchoMaximo: 520,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _cambiarFoto,
                  child: SizedBox.square(
                    dimension: 100,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(color: _foto == null ? (context.esOscuro ? p.chip : const Color(0xFFD9D9D9)) : p.suaveVerde, shape: BoxShape.circle),
                          child: Icon(_foto == null ? TablerIcons.user : TablerIcons.photo_check, size: 46, color: _foto == null ? Colors.white : AppColors.verdeExito),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: AppColors.amarillo, shape: BoxShape.circle, border: Border.all(color: p.fondo, width: 3)),
                            child: const Icon(TablerIcons.camera, size: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Center(child: TextButton(onPressed: _cambiarFoto, child: Text('Cambiar foto', style: Txt.nb(14, color: AppColors.azulEnlace)))),
              const SizedBox(height: 4),
              CampoEtiquetado(
                etiqueta: 'Nombre',
                hint: 'Tu nombre',
                icono: TablerIcons.user,
                controller: _nombre,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 6),
              CampoEtiquetado(
                etiqueta: 'Correo electrónico',
                hint: 'nombre@correo.com',
                icono: TablerIcons.mail,
                controller: _correo,
                teclado: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 6),
              CampoEtiquetado(
                etiqueta: 'Celular',
                hint: '300 000 0000',
                icono: TablerIcons.phone,
                controller: _celular,
                teclado: TextInputType.phone,
                formatos: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
              ),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(left: 6, bottom: 4), child: Text('Localidad', style: Txt.r(15, color: p.texto))),
              DropdownButtonFormField<String>(
                initialValue: _localidad,
                icon: const Icon(TablerIcons.chevron_down, size: 20),
                style: Txt.n(14, color: p.texto),
                dropdownColor: p.tarjeta,
                decoration: const InputDecoration(prefixIcon: Icon(TablerIcons.map_pin, size: 20)),
                items: [for (final l in localidadesBogota.keys) DropdownMenuItem(value: l, child: Text(l))],
                onChanged: (v) => setState(() => _localidad = v ?? _localidad),
              ),
              const SizedBox(height: 34),
              BotonPrincipal(texto: 'Guardar cambios', color: AppColors.amarillo, onPressed: _guardar),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Ajustes ----------------

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  Future<void> _cambiarClave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar contraseña', style: Txt.r(20, color: ctx.paleta.texto)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, decoration: InputDecoration(hintText: 'Contraseña actual')),
            SizedBox(height: 12),
            TextField(obscureText: true, decoration: InputDecoration(hintText: 'Nueva contraseña (mín. 8)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada (simulación).')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final modo = ref.watch(themeModeProvider);
    final usuario = ref.watch(authControllerProvider).usuario;

    Widget segmento(ThemeMode m, IconData icono, String texto) {
      final activo = m == modo;
      return Expanded(
        child: Material(
          color: activo ? AppColors.amarillo : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => ref.read(themeModeProvider.notifier).cambiar(m),
            child: SizedBox(
              height: 42,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 18, color: activo ? Colors.black : p.textoSecundario),
                  const SizedBox(width: 6),
                  Text(texto, style: activo ? Txt.nb(14, color: Colors.black) : Txt.n(14, color: p.textoSecundario)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PantallaSecundaria(
      titulo: 'Ajustes',
      children: [
        const TituloSeccion('Apariencia', padding: EdgeInsets.fromLTRB(10, 4, 4, 8)),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: context.esOscuro ? p.chip : const Color(0xFFECEEF0), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              segmento(ThemeMode.light, TablerIcons.sun, 'Claro'),
              segmento(ThemeMode.dark, TablerIcons.moon, 'Oscuro'),
              segmento(ThemeMode.system, TablerIcons.device_desktop, 'Sistema'),
            ],
          ),
        ),
        const TituloSeccion('Cuenta', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              FilaOpcion(icono: TablerIcons.user, texto: 'Editar perfil', onTap: () => context.push('/perfil/editar')),
              FilaOpcion(icono: TablerIcons.lock, texto: 'Cambiar contraseña', onTap: () => _cambiarClave(context)),
              FilaOpcion(icono: TablerIcons.id, texto: 'Tipo de usuario', valor: usuario?.rol.etiqueta ?? '', divisor: false),
            ],
          ),
        ),
        const TituloSeccion('General', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const FilaOpcion(icono: TablerIcons.world, texto: 'Idioma', valor: 'Español'),
              FilaOpcion(icono: TablerIcons.bell, texto: 'Configurar alertas', onTap: () => context.push('/alertas/configurar')),
              FilaOpcion(
                icono: TablerIcons.help_circle,
                texto: 'Acerca de Alerta Vial',
                valor: AppConstants.version,
                divisor: false,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.version,
                  applicationLegalese: 'Reportes y alertas de seguridad vial para Bogotá.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rojo,
              side: const BorderSide(color: AppColors.rojo, width: 1.5),
              textStyle: Txt.r(18),
            ),
            onPressed: () => ref.read(authControllerProvider.notifier).cerrarSesion(),
            icon: const Icon(TablerIcons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}

// ---------------- Privacidad y datos ----------------

class PrivacidadScreen extends ConsumerWidget {
  const PrivacidadScreen({super.key});

  void _info(BuildContext context, String titulo, String texto) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(titulo, style: Txt.r(20, color: ctx.paleta.texto)),
          content: Text(texto, style: Txt.n(14, color: ctx.paleta.texto)),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
        ),
      );

  Future<void> _eliminarCuenta(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(TablerIcons.trash, color: AppColors.rojo, size: 36),
        title: Text('¿Eliminar tu cuenta?', style: Txt.r(20, color: ctx.paleta.texto)),
        content: const Text('Se borrarán tus datos, vehículos y zonas favoritas. Los reportes ya enviados quedan anónimos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).cerrarSesion();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pr = ref.watch(privacidadProvider);
    void cambiar(Privacidad n) => ref.read(privacidadProvider.notifier).cambiar(n);
    Widget interruptor(IconData icono, String texto, bool valor, ValueChanged<bool> on, {bool divisor = true}) =>
        FilaOpcion(icono: icono, texto: texto, divisor: divisor, onTap: () => on(!valor), trailing: Switch(value: valor, onChanged: on));

    return PantallaSecundaria(
      titulo: 'Privacidad y datos',
      children: [
        const TituloSeccion('Visibilidad', padding: EdgeInsets.fromLTRB(10, 4, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              interruptor(TablerIcons.eye_off, 'Reportar de forma anónima', pr.anonimo, (v) => cambiar(pr.copyWith(anonimo: v))),
              interruptor(TablerIcons.current_location, 'Compartir mi ubicación', pr.compartirUbicacion, (v) => cambiar(pr.copyWith(compartirUbicacion: v))),
              interruptor(TablerIcons.user, 'Mostrar mi nombre en reportes', pr.mostrarNombre, (v) => cambiar(pr.copyWith(mostrarNombre: v)), divisor: false),
            ],
          ),
        ),
        const TituloSeccion('Tus datos', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              FilaOpcion(
                icono: TablerIcons.download,
                texto: 'Descargar mis datos',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Te enviaremos un archivo con tus datos al correo registrado.'))),
              ),
              FilaOpcion(
                icono: TablerIcons.shield,
                texto: 'Política de privacidad',
                onTap: () => _info(
                  context,
                  'Política de privacidad',
                  'Alerta Vial usa tu ubicación solo mientras la app está abierta para mostrarte zonas de riesgo. '
                      'Tus reportes se comparten con la autoridad; puedes reportar de forma anónima. '
                      'Tratamos tus datos según la Ley 1581 de 2012 (Habeas Data).',
                ),
              ),
              FilaOpcion(
                icono: TablerIcons.file_text,
                texto: 'Términos y condiciones',
                divisor: false,
                onTap: () => _info(
                  context,
                  'Términos y condiciones',
                  'Los reportes falsos pueden tener consecuencias legales. En una emergencia llama siempre al 123.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.rojo, side: const BorderSide(color: AppColors.rojo, width: 1.5), textStyle: Txt.r(17)),
            onPressed: () => _eliminarCuenta(context, ref),
            icon: const Icon(TablerIcons.trash),
            label: const Text('Eliminar mi cuenta'),
          ),
        ),
      ],
    );
  }
}

// ---------------- Centro de ayuda ----------------

class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final preguntas = preguntasFrecuentes.where((e) => _q.isEmpty || '${e.$1} ${e.$2}'.toLowerCase().contains(_q.toLowerCase())).toList();
    Widget tarjetaContacto(IconData icono, String titulo, String sub, Color fondo, Color color, VoidCallback onTap) => Expanded(
          child: Material(
            color: fondo,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icono, color: color, size: 26),
                    const SizedBox(height: 10),
                    Text(titulo, style: Txt.nb(16, color: color)),
                    Text(sub, style: Txt.n(12, color: color)),
                  ],
                ),
              ),
            ),
          ),
        );

    return PantallaSecundaria(
      titulo: 'Centro de ayuda',
      children: [
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: Txt.n(14, color: p.texto),
            decoration: const InputDecoration(hintText: '¿En qué te ayudamos?', prefixIcon: Icon(TablerIcons.search, size: 20)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            tarjetaContacto(TablerIcons.phone, 'Línea 123', 'Emergencias', AppColors.rojo, Colors.white, () => launchUrl(Uri.parse('tel:123'))),
            const SizedBox(width: 10),
            tarjetaContacto(
              TablerIcons.message_dots,
              'Chat de soporte',
              'Responde en minutos',
              AppColors.amarillo,
              Colors.black,
              () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El chat de soporte estará disponible pronto.'))),
            ),
          ],
        ),
        const TituloSeccion('Preguntas frecuentes', padding: EdgeInsets.fromLTRB(10, 20, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: [
                if (preguntas.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text('Sin resultados.', style: Txt.n(14, color: p.textoSecundario))),
                for (final (i, (pregunta, respuesta)) in preguntas.indexed) ...[
                  ExpansionTile(
                    leading: Icon(TablerIcons.help_circle, color: p.textoSecundario),
                    title: Text(pregunta, style: Txt.nb(15, color: p.texto)),
                    iconColor: p.texto,
                    collapsedIconColor: p.textoSecundario,
                    childrenPadding: const EdgeInsets.fromLTRB(56, 0, 20, 16),
                    expandedAlignment: Alignment.centerLeft,
                    children: [Text(respuesta, style: Txt.n(14, color: p.textoSecundario))],
                  ),
                  if (i < preguntas.length - 1) Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Divider(color: p.divisor)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(child: Text('Alerta Vial ${AppConstants.version}', style: Txt.n(12, color: p.textoSecundario))),
      ],
    );
  }
}
