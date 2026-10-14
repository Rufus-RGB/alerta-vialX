import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/data/mapa_repository.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../data/clima_repository.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usuario = ref.watch(authControllerProvider).usuario;
    final clima = ref.watch(climaProvider);
    final zonas = ref.watch(zonasRiesgoProvider);
    final inferior = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, inferior + 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_saludo(), style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          Text('Hola, ${usuario?.nombre ?? ''}', style: theme.textTheme.headlineMedium),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Alertas',
                      onPressed: () => context.go('/alertas'),
                      icon: const Icon(Icons.notifications_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                clima.when(
                  data: (c) => _TarjetaClima(clima: c),
                  loading: () => const Tarjeta(child: SizedBox(height: 72, child: Center(child: CircularProgressIndicator()))),
                  error: (e, _) => Tarjeta(child: Text('No se pudo cargar el clima: $e')),
                ),
                const TituloSeccion('Acciones rápidas'),
                LayoutBuilder(
                  builder: (context, c) {
                    final columnas = c.maxWidth >= 560 ? 3 : 1;
                    final acciones = [
                      _AccionRapida(
                        icono: Icons.add_location_alt_rounded,
                        titulo: 'Reportar incidente',
                        subtitulo: 'Hurto, accidente o vía en mal estado',
                        color: AppColors.rojo,
                        onTap: () => context.go('/reporte'),
                      ),
                      _AccionRapida(
                        icono: Icons.map_rounded,
                        titulo: 'Ver mapa',
                        subtitulo: 'Hurtos y zonas de calor',
                        color: AppColors.amarillo,
                        onTap: () => context.go('/mapa'),
                      ),
                      _AccionRapida(
                        icono: Icons.local_police_rounded,
                        titulo: 'CAI cercanos',
                        subtitulo: 'Puntos de atención policial',
                        color: AppColors.azulAutoridad,
                        onTap: () => _mostrarCais(context, ref),
                      ),
                    ];
                    if (columnas == 1) {
                      return Column(
                        children: [
                          for (final a in acciones) Padding(padding: const EdgeInsets.only(bottom: 10), child: a),
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < acciones.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: acciones[i]),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                TituloSeccion(
                  'Zonas de riesgo',
                  accion: TextButton(onPressed: () => context.go('/mapa'), child: const Text('Ver en mapa')),
                ),
                zonas.when(
                  data: (lista) => Column(
                    children: [
                      for (final z in lista)
                        Padding(padding: const EdgeInsets.only(bottom: 10), child: _TarjetaZona(zona: z)),
                    ],
                  ),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                  error: (e, _) => Text('No se pudieron cargar las zonas: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarCais(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final cais = ref.watch(caisProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: cais.when(
                loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error: $e'),
                data: (lista) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('CAI cercanos', style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    const SizedBox(height: 8),
                    for (final c in lista)
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.azulAutoridad,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.local_police_rounded),
                        ),
                        title: Text(c.nombre),
                        subtitle: Text(c.direccion),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(ctx);
                          context.go('/mapa?lat=${c.punto.latitude}&lng=${c.punto.longitude}');
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaClima extends StatelessWidget {
  const _TarjetaClima({required this.clima});

  final Clima clima;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tarjeta(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.amarillo.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(clima.icono, color: AppColors.amarillo, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${clima.temperatura}° · ${clima.descripcion}', style: theme.textTheme.titleLarge),
                Text(clima.ciudad, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(clima.consejo, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccionRapida extends StatelessWidget {
  const _AccionRapida({required this.icono, required this.titulo, required this.subtitulo, required this.color, required this.onTap});

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tarjeta(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Icon(icono, color: color == AppColors.amarillo ? AppColors.fondoOscuro : Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitulo, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TarjetaZona extends StatelessWidget {
  const _TarjetaZona({required this.zona});

  final ZonaRiesgo zona;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tarjeta(
      onTap: () => context.go('/mapa?lat=${zona.centro.latitude}&lng=${zona.centro.longitude}'),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, color: zona.nivel.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zona.nombre, style: theme.textTheme.titleSmall),
                Text(
                  '${zona.reportesSemana} reportes esta semana',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          EtiquetaRiesgo(zona.nivel),
        ],
      ),
    );
  }
}
