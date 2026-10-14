import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/tarjeta.dart';
import 'auth_controller.dart';
import 'pantalla_acceso.dart';

/// Permisos (ubicación en primer plano y notificaciones) tras crear la cuenta.
class PermisosScreen extends ConsumerStatefulWidget {
  const PermisosScreen({super.key});

  @override
  ConsumerState<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends ConsumerState<PermisosScreen> {
  bool _ubicacion = true;
  bool _notificaciones = true;
  bool _cargando = false;

  Future<void> _continuar() async {
    setState(() => _cargando = true);
    if (_ubicacion) {
      try {
        final permiso = await Geolocator.checkPermission();
        if (permiso == LocationPermission.denied) await Geolocator.requestPermission();
      } catch (_) {
        // Sin servicio de ubicación (p. ej. navegador sin soporte): se puede activar después.
      }
    }
    if (!mounted) return;
    ref.read(authControllerProvider.notifier).permisosVistos();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PantallaAcceso(
      atras: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(color: AppColors.amarillo.withValues(alpha: 0.15), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(color: AppColors.amarillo, shape: BoxShape.circle),
                child: const Icon(TablerIcons.map_pin, size: 60, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Activa ubicación y alertas', textAlign: TextAlign.center, style: Txt.r(24, color: p.texto)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              'Así te mostramos las zonas de riesgo cerca y te avisamos de hurtos en tiempo real.',
              textAlign: TextAlign.center,
              style: Txt.n(15, color: p.textoSecundario),
            ),
          ),
          const SizedBox(height: 48),
          Tarjeta(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                FilaLista(
                  titulo: 'Ubicación',
                  subtitulo: 'Ver zonas de riesgo cerca de ti',
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  leading: IconoCirculo(icono: TablerIcons.map_pin, fondo: p.chip, color: p.texto, tamanoIcono: 22),
                  trailing: Switch(value: _ubicacion, onChanged: (v) => setState(() => _ubicacion = v)),
                ),
                FilaLista(
                  titulo: 'Notificaciones',
                  subtitulo: 'Alertas de hurtos en tu zona',
                  divisor: false,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  leading: IconoCirculo(icono: TablerIcons.bell, fondo: p.chip, color: p.texto, tamanoIcono: 22),
                  trailing: Switch(value: _notificaciones, onChanged: (v) => setState(() => _notificaciones = v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          BotonPrincipal(texto: 'Continuar', onPressed: _continuar, cargando: _cargando, color: AppColors.amarillo),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => ref.read(authControllerProvider.notifier).permisosVistos(),
              child: Text('Ahora no', style: Txt.nb(15, color: p.textoSecundario)),
            ),
          ),
        ],
      ),
    );
  }
}
