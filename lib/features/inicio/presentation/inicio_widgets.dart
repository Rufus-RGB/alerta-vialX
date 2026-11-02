import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/data/mapa_repository.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../data/clima_repository.dart';

/// Hoja inferior con los CAI cercanos; al tocar uno se centra el mapa en él.
void mostrarCaisCercanos(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final p = ctx.paleta;
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
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('CAI cercanos', style: Txt.r(20, color: p.texto))),
                  const SizedBox(height: 8),
                  for (final c in lista)
                    FilaLista(
                      titulo: c.nombre,
                      subtitulo: c.distanciaKm > 0 ? '${c.direccion} · ${c.distanciaKm.toStringAsFixed(1).replaceAll('.', ',')} km' : c.direccion,
                      leading: const IconoCirculo(icono: TablerIcons.shield, fondo: AppColors.azulAutoridad),
                      trailing: Icon(TablerIcons.chevron_right, color: p.textoSecundario),
                      divisor: c != lista.last,
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

/// Lista "Zonas de Riesgo Actuales" con número, nombre y nivel.
class ListaZonas extends ConsumerWidget {
  const ListaZonas({super.key, this.compacta = false, this.titulo = 'Zonas de Riesgo Actuales', this.limite = 4});

  /// Versión de tablet/PC (filas de 47 px, etiquetas cortas).
  final bool compacta;
  final String titulo;
  final int limite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final zonas = ref.watch(zonasRiesgoProvider);
    return Tarjeta(
      padding: EdgeInsets.fromLTRB(14, compacta ? 13 : 10, 14, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: Txt.nb(compacta ? 15 : 14, color: p.texto))),
              if (!compacta)
                InkWell(
                  onTap: () => context.go('/mapa'),
                  child: Text('Ver todas ›', style: Txt.nb(12, color: p.enlace)),
                ),
            ],
          ),
          SizedBox(height: compacta ? 10 : 8),
          zonas.when(
            loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (lista) => Column(
              children: [
                for (var n = 0; n < lista.length && n < limite; n++)
                  _FilaZona(numero: n + 1, zona: lista[n], compacta: compacta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaZona extends StatelessWidget {
  const _FilaZona({required this.numero, required this.zona, required this.compacta});

  final int numero;
  final ZonaRiesgo zona;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return InkWell(
      onTap: () => context.go('/mapa?zona=${Uri.encodeQueryComponent(zona.nombre)}'),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compacta ? 10 : 4),
        decoration: compacta ? null : BoxDecoration(border: Border(top: BorderSide(color: p.divisor))),
        child: Row(
          children: [
            Container(
              width: compacta ? 24 : 26,
              height: compacta ? 24 : 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.numero, shape: BoxShape.circle),
              child: Text('$numero', style: Txt.r(compacta ? 11 : 12, color: Colors.white)),
            ),
            SizedBox(width: compacta ? 10 : 12),
            Expanded(child: Text(zona.nombre, style: Txt.n(compacta ? 13 : 14, color: p.texto))),
            EtiquetaRiesgo(zona.nivel, corta: compacta, ancho: compacta ? null : 118),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de clima de celular (90 px): ciudad, temperatura, descripción y máx/mín.
class TarjetaClima extends ConsumerWidget {
  const TarjetaClima({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final clima = ref.watch(climaProvider);
    return Tarjeta(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 90,
        child: clima.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Clima no disponible', style: Txt.n(13, color: p.textoSecundario))),
          data: (c) => Row(
            children: [
              const SizedBox(width: 10),
              const Icon(TablerIcons.map_pin_filled, color: AppColors.amarillo, size: 24),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(c.ciudad, style: Txt.nb(18, color: p.texto)),
                        const SizedBox(width: 6),
                        Icon(TablerIcons.chevron_right, size: 18, color: p.texto),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${c.temperatura}°C', style: Txt.nb(24, color: p.texto)),
                        const SizedBox(width: 18),
                        Icon(c.icono, size: 22, color: const Color(0xFFB9BEC3)),
                        const SizedBox(width: 6),
                        Flexible(child: Text(c.descripcion, overflow: TextOverflow.ellipsis, style: Txt.n(12, color: p.textoSecundario))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 59, color: p.borde),
              SizedBox(
                width: 116,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hoy', style: Txt.nb(12, color: p.texto)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(TablerIcons.arrow_up, size: 18, color: AppColors.rojo),
                        Text('${c.maxima}°', style: Txt.n(16, color: p.texto)),
                        const SizedBox(width: 14),
                        const Icon(TablerIcons.arrow_down, size: 18, color: Color(0xFF3B90FF)),
                        Text('${c.minima}°', style: Txt.n(16, color: p.texto)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Píldora de clima de tablet/PC: "Bogotá 13°C · Nubes ↑18° ↓8°".
class PildoraClima extends ConsumerWidget {
  const PildoraClima({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final c = ref.watch(climaProvider).value;
    if (c == null) return const SizedBox(height: 40);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: context.esOscuro ? p.chip : AppColors.fondoClaro, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.map_pin, size: 18, color: AppColors.amarillo),
          const SizedBox(width: 6),
          Text('${c.ciudad}  ${c.temperatura}°C', style: Txt.nb(14, color: p.texto)),
          const SizedBox(width: 12),
          Icon(c.icono, size: 18, color: p.textoSecundario),
          const SizedBox(width: 6),
          Text('Nubes', style: Txt.n(12, color: p.textoSecundario)),
          const SizedBox(width: 8),
          Text('↑${c.maxima}° ↓${c.minima}°', style: Txt.nb(12, color: p.textoSecundario)),
        ],
      ),
    );
  }
}

/// Banner publicitario "Tu ruta más segura con GPS en tiempo real".
class BannerPublicidad extends StatelessWidget {
  const BannerPublicidad({super.key});

  @override
  Widget build(BuildContext context) {
    final oscuro = context.esOscuro;
    return Container(
      height: 118,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: oscuro ? const Color(0xFF181B1E) : const Color(0xFF16191C),
        borderRadius: BorderRadius.circular(16),
        border: oscuro ? Border.all(color: AppColors.bordeOscuro) : null,
      ),
      child: Stack(
        children: [
          Positioned(right: 3, top: 8, width: 176, height: 103, child: Image.asset('assets/images/banner_gps.png', fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.amarillo, borderRadius: BorderRadius.circular(6)),
                  child: Text('Publicidad', style: Txt.nb(10, color: Colors.black)),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: Txt.nb(17, color: Colors.white, height: 21 / 17),
                    children: const [
                      TextSpan(text: 'Tu ruta más segura\ncon '),
                      TextSpan(text: 'GPS en tiempo real', style: TextStyle(color: AppColors.amarillo)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: AppColors.amarillo,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pronto: navegación GPS con rutas seguras.'))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: Text('Conoce más →', style: Txt.nb(12, color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: i == 0 ? AppColors.amarillo : const Color(0xFF555B61), shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
