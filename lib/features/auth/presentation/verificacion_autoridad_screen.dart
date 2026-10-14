import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/campos.dart';
import '../data/auth_repository.dart';
import 'pantalla_acceso.dart';

const unidadesAutoridad = ['SIJIN · Bogotá', 'Policía Metropolitana · Bogotá', 'DIJIN', 'Tránsito · Bogotá'];

/// Verificación de cuenta de autoridad (Policía / SIJIN). Un administrador la aprueba.
class VerificacionAutoridadScreen extends ConsumerStatefulWidget {
  const VerificacionAutoridadScreen({super.key});

  @override
  ConsumerState<VerificacionAutoridadScreen> createState() => _VerificacionAutoridadScreenState();
}

class _VerificacionAutoridadScreenState extends ConsumerState<VerificacionAutoridadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _placa = TextEditingController();
  String _unidad = unidadesAutoridad.first;
  String? _carne;
  bool _cargando = false;

  @override
  void dispose() {
    _correo.dispose();
    _placa.dispose();
    super.dispose();
  }

  Future<void> _subirCarne() async {
    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (archivo != null) setState(() => _carne = archivo.name);
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_carne == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sube una foto de tu carné institucional.')));
      return;
    }
    setState(() => _cargando = true);
    await ref.read(authRepositoryProvider).solicitarCuentaAutoridad(correo: _correo.text, placa: _placa.text, unidad: _unidad);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud enviada. Te avisaremos por correo cuando sea aprobada.'), backgroundColor: AppColors.verdeExito),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PantallaAcceso(
      titulo: 'Cuenta de autoridad',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(color: AppColors.azulAutoridad, shape: BoxShape.circle),
                child: const Icon(TablerIcons.shield_check, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text('Verifica tu cuenta', textAlign: TextAlign.center, style: Txt.r(22, color: p.texto)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                'Confirmamos que eres autoridad con tu correo institucional.',
                textAlign: TextAlign.center,
                style: Txt.n(14, color: p.textoSecundario),
              ),
            ),
            const SizedBox(height: 12),
            CampoEtiquetado(
              etiqueta: 'Correo institucional',
              hint: 'nombre@policia.gov.co',
              icono: TablerIcons.mail,
              controller: _correo,
              teclado: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.trim().endsWith('.gov.co')) ? 'Usa tu correo institucional (.gov.co)' : null,
            ),
            const SizedBox(height: 6),
            CampoEtiquetado(
              etiqueta: 'Número de placa',
              hint: 'Ej: 012345',
              icono: TablerIcons.id,
              controller: _placa,
              teclado: TextInputType.number,
              validator: (v) => (v == null || v.trim().length < 4) ? 'Escribe tu número de placa' : null,
            ),
            const SizedBox(height: 6),
            Padding(padding: const EdgeInsets.only(left: 6, bottom: 4), child: Text('Unidad', style: Txt.r(15, color: p.texto))),
            DropdownButtonFormField<String>(
              initialValue: _unidad,
              icon: const Icon(TablerIcons.chevron_down, size: 20),
              style: Txt.n(14, color: p.texto),
              dropdownColor: p.tarjeta,
              decoration: const InputDecoration(prefixIcon: Icon(TablerIcons.shield_check, size: 20)),
              items: [for (final u in unidadesAutoridad) DropdownMenuItem(value: u, child: Text(u))],
              onChanged: (v) => setState(() => _unidad = v ?? _unidad),
            ),
            const SizedBox(height: 12),
            _CajaPunteada(
              onTap: _subirCarne,
              child: Row(
                children: [
                  Icon(_carne == null ? TablerIcons.upload : TablerIcons.circle_check, size: 24, color: _carne == null ? p.texto : AppColors.verdeExito),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_carne ?? 'Sube tu carné institucional', overflow: TextOverflow.ellipsis, style: Txt.nb(14, color: p.texto)),
                        Text('Foto o PDF · máx. 5 MB', style: Txt.n(12, color: p.textoSecundario)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: p.suaveAzul, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(TablerIcons.clock, size: 22, color: AppColors.azulAutoridad),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Un administrador aprobará tu cuenta', style: Txt.nb(14, color: p.texto)),
                        Text('Tiempo estimado: 24 a 48 horas', style: Txt.n(12, color: p.textoSecundario)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            BotonPrincipal(texto: 'Enviar solicitud', onPressed: _enviar, cargando: _cargando, color: AppColors.azulAutoridad),
          ],
        ),
      ),
    );
  }
}

/// Caja con borde punteado (subir archivo).
class _CajaPunteada extends StatelessWidget {
  const _CajaPunteada({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BordePunteado(color: context.paleta.inputBorde),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 13), child: child),
        ),
      ),
    );
  }
}

/// Borde punteado redondeado (1.5 px, radio 14) reutilizable.
class BordePunteado extends CustomPainter {
  BordePunteado({required this.color, this.radio = 14});

  final Color color;
  final double radio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radio)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(BordePunteado old) => old.color != color;
}
