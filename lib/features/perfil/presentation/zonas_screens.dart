import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/data/mapa_repository.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../../mapa/presentation/mapa_base.dart';
import '../../mapa/presentation/mapa_controller.dart';
import '../../reporte/presentation/reporte_widgets.dart';
import '../data/perfil_repository.dart';
import 'vehiculos_screens.dart' show BotonAgregarPunteado;

Widget _pildoraNivel(BuildContext context, NivelRiesgo n) {
  final p = context.paleta;
  final texto = switch (n) {
    NivelRiesgo.alto => 'Riesgo alto',
    NivelRiesgo.medio => 'Riesgo medio',
    _ => 'Riesgo bajo',
  };
  return Pildora(texto, fondo: n.fondo(p), color: n.texto(p));
}

// ---------------- Zonas favoritas ----------------

class ZonasFavoritasScreen extends ConsumerWidget {
  const ZonasFavoritasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final zonas = ref.watch(zonasFavoritasProvider);
    return PantallaSecundaria(
      titulo: 'Zonas favoritas',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 10),
          child: Text('Te avisamos cuando haya incidentes cerca de estas zonas.', style: Txt.n(14, color: p.textoSecundario)),
        ),
        for (final z in zonas)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(z.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(color: AppColors.rojo, borderRadius: BorderRadius.circular(16)),
                child: const Icon(TablerIcons.trash, color: Colors.white),
              ),
              onDismissed: (_) => ref.read(zonasFavoritasProvider.notifier).eliminar(z.id),
              child: Tarjeta(
                onTap: () => context.go('/mapa?lat=${z.punto.latitude}&lng=${z.punto.longitude}'),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconoCirculo(icono: z.tipo.icono, fondo: p.chip, color: p.texto, tamano: 48, tamanoIcono: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(z.nombre, style: Txt.nb(17, color: p.texto)),
                              Text(z.direccion, style: Txt.n(13, color: p.textoSecundario)),
                            ],
                          ),
                        ),
                        _pildoraNivel(context, z.nivel),
                      ],
                    ),
                    Divider(color: p.divisor, height: 18),
                    Row(
                      children: [
                        const SizedBox(width: 62),
                        Expanded(
                          child: Text('Avisarme', style: Txt.n(13, color: p.textoSecundario)),
                        ),
                        Switch(value: z.avisar, onChanged: (_) => ref.read(zonasFavoritasProvider.notifier).alternarAviso(z.id)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        BotonAgregarPunteado(texto: 'Agregar zona', onTap: () => context.push('/perfil/zonas/agregar')),
      ],
    );
  }
}

// ---------------- Agregar zona ----------------

class AgregarZonaScreen extends ConsumerStatefulWidget {
  const AgregarZonaScreen({super.key});

  @override
  ConsumerState<AgregarZonaScreen> createState() => _AgregarZonaScreenState();
}

class _AgregarZonaScreenState extends ConsumerState<AgregarZonaScreen> {
  final _mapa = MapController();
  final _nombre = TextEditingController(text: 'Gimnasio');
  final _direccion = TextEditingController(text: 'Cra. 15 # 93-20, Chicó');
  LatLng _punto = const LatLng(4.6770, -74.0500);
  TipoZona _tipo = TipoZona.otro;
  double _radio = 1;
  bool _avisar = true;

  @override
  void dispose() {
    _mapa.dispose();
    _nombre.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _miUbicacion() async {
    try {
      final p = await obtenerUbicacionActual();
      setState(() => _punto = p);
      _mapa.move(p, 15);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  NivelRiesgo _nivelPara(LatLng punto) {
    const d = Distance();
    final zonas = ref.read(zonasRiesgoProvider).value ?? const <ZonaRiesgo>[];
    for (final z in zonas) {
      if (d(punto, z.centro) < z.radioMetros + _radio * 1000) return z.nivel;
    }
    return NivelRiesgo.bajo;
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty || _direccion.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe el nombre y la dirección de la zona.')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(zonasFavoritasProvider.notifier)
          .agregar(
            ZonaFavorita(
              id: 'z${DateTime.now().millisecondsSinceEpoch}',
              nombre: _nombre.text.trim(),
              direccion: _direccion.text.trim(),
              tipo: _tipo,
              punto: _punto,
              radioKm: _radio,
              avisar: _avisar,
              nivel: _nivelPara(_punto),
            ),
          );
      messenger.showSnackBar(const SnackBar(content: Text('Zona guardada.'), backgroundColor: AppColors.verdeExito));
      if (mounted) context.canPop() ? context.pop() : context.go('/perfil/zonas');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return PantallaSecundaria(
      titulo: 'Agregar zona',
      anchoMaximo: 560,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 230,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(
                    initialCenter: _punto,
                    initialZoom: 14,
                    onTap: (_, ll) => setState(() => _punto = ll),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    MapaBase.capaTiles(context),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _punto,
                          radius: _radio * 1000,
                          useRadiusInMeter: true,
                          color: AppColors.amarillo.withValues(alpha: 0.18),
                          borderColor: AppColors.amarillo,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _punto,
                          width: 120,
                          height: 92,
                          alignment: const Alignment(0, -0.25),
                          child: PinConEtiqueta(etiqueta: _nombre.text.isEmpty ? 'Zona' : _nombre.text),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: BotonCircular(icono: TablerIcons.current_location, tooltip: 'Mi ubicación', sombra: true, onPressed: _miUbicacion),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const EtiquetaCampo('Nombre de la zona', tamano: 15),
        TextField(
          controller: _nombre,
          onChanged: (_) => setState(() {}),
          style: Txt.n(14, color: p.texto),
          decoration: const InputDecoration(prefixIcon: Icon(TablerIcons.tag, size: 20), hintText: 'Ej: Gimnasio'),
        ),
        const SizedBox(height: 10),
        const EtiquetaCampo('Dirección', tamano: 15),
        TextField(
          controller: _direccion,
          style: Txt.n(14, color: p.texto),
          onSubmitted: (q) {
            final loc = localidadesBogota.entries.where((e) => q.toLowerCase().contains(e.key.toLowerCase())).firstOrNull;
            if (loc != null) {
              setState(() => _punto = loc.value);
              _mapa.move(loc.value, 14);
            }
          },
          decoration: const InputDecoration(prefixIcon: Icon(TablerIcons.search, size: 20), hintText: 'Calle, carrera y barrio'),
        ),
        const SizedBox(height: 10),
        const EtiquetaCampo('Tipo', tamano: 15),
        GrupoChips<TipoZona>(
          opciones: TipoZona.values,
          seleccionado: _tipo,
          etiqueta: (t) => t.etiqueta,
          alto: 38,
          onChanged: (t) => setState(() => _tipo = t),
        ),
        const SizedBox(height: 16),
        Tarjeta(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Radio de aviso', style: Txt.nb(15, color: p.texto)),
                  ),
                  Text('${_radio.toStringAsFixed(_radio % 1 == 0 ? 0 : 1)} km', style: Txt.nb(15, color: p.texto)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.amarillo,
                  inactiveTrackColor: context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFD9D9D9),
                  thumbColor: AppColors.amarillo,
                  trackHeight: 6,
                ),
                child: Slider(value: _radio, min: 0.5, max: 3, divisions: 5, onChanged: (v) => setState(() => _radio = v)),
              ),
              Divider(color: p.divisor),
              Row(
                children: [
                  Expanded(
                    child: Text('Avisarme de incidentes', style: Txt.nb(15, color: p.texto)),
                  ),
                  Switch(value: _avisar, onChanged: (v) => setState(() => _avisar = v)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BotonPrincipal(texto: 'Guardar zona', color: AppColors.amarillo, onPressed: _guardar),
      ],
    );
  }
}
