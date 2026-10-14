import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/indicadores.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../../mapa/presentation/mapa_base.dart';
import '../data/dev_repository.dart';
import 'dev_comun.dart';

// ---------------- Zonas de riesgo (administración) ----------------

class ZonaAdmin {
  const ZonaAdmin(this.nombre, this.centro, this.radioKm, this.nivel, this.reportes, {this.automatica = false});
  final String nombre;
  final LatLng centro;
  final double radioKm;
  final NivelRiesgo nivel;
  final int reportes;
  final bool automatica;

  ZonaAdmin copyWith({double? radioKm, NivelRiesgo? nivel, bool? automatica}) =>
      ZonaAdmin(nombre, centro, radioKm ?? this.radioKm, nivel ?? this.nivel, reportes, automatica: automatica ?? this.automatica);
}

final zonasAdminProvider = NotifierProvider<_ZonasAdmin, List<ZonaAdmin>>(_ZonasAdmin.new);

class _ZonasAdmin extends Notifier<List<ZonaAdmin>> {
  @override
  List<ZonaAdmin> build() => const [
        ZonaAdmin('Kennedy', LatLng(4.6286, -74.1569), 2.5, NivelRiesgo.alto, 64, automatica: true),
        ZonaAdmin('Bosa', LatLng(4.6186, -74.1906), 2, NivelRiesgo.alto, 48, automatica: true),
        ZonaAdmin('Ciudad Bolívar', LatLng(4.5097, -74.1522), 2, NivelRiesgo.alto, 28),
        ZonaAdmin('Engativá', LatLng(4.7069, -74.1150), 1.8, NivelRiesgo.medio, 31, automatica: true),
        ZonaAdmin('Chapinero', LatLng(4.6483, -74.0630), 1.5, NivelRiesgo.medio, 22),
        ZonaAdmin('Usaquén', LatLng(4.7030, -74.0300), 1.5, NivelRiesgo.bajo, 6),
      ];

  void guardar(ZonaAdmin z) => state = [for (final e in state) e.nombre == z.nombre ? z : e];
  void agregar(ZonaAdmin z) => state = [...state, z];
}

class ZonasAdminScreen extends ConsumerStatefulWidget {
  const ZonasAdminScreen({super.key});

  @override
  ConsumerState<ZonasAdminScreen> createState() => _ZonasAdminScreenState();
}

class _ZonasAdminScreenState extends ConsumerState<ZonasAdminScreen> {
  final _mapa = MapController();
  String _sel = 'Kennedy';
  ZonaAdmin? _edicion;

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  void _seleccionar(ZonaAdmin z) {
    setState(() {
      _sel = z.nombre;
      _edicion = z;
    });
    _mapa.move(z.centro, 13);
  }

  Future<void> _nueva() async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? valor;
        return AlertDialog(
          title: const Text('Nueva zona'),
          content: DropdownButtonFormField<String>(
            hint: const Text('Localidad'),
            items: [for (final l in localidadesBogota.keys) DropdownMenuItem(value: l, child: Text(l))],
            onChanged: (v) => valor = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, valor), child: const Text('Crear')),
          ],
        );
      },
    );
    if (nombre == null) return;
    final existentes = ref.read(zonasAdminProvider);
    if (existentes.any((z) => z.nombre == nombre)) {
      _seleccionar(existentes.firstWhere((z) => z.nombre == nombre));
      return;
    }
    final z = ZonaAdmin(nombre, localidadesBogota[nombre]!, 1, NivelRiesgo.bajo, 0);
    ref.read(zonasAdminProvider.notifier).agregar(z);
    _seleccionar(z);
  }

  Color _color(NivelRiesgo n) => switch (n) {
        NivelRiesgo.alto => AppColors.rojo,
        NivelRiesgo.medio => AppColors.amarillo,
        _ => AppColors.verdeExito,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final zonas = ref.watch(zonasAdminProvider);
    final z = _edicion ?? zonas.firstWhere((e) => e.nombre == _sel, orElse: () => zonas.first);
    final ancho = !context.esCelular;

    final mapa = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: ancho ? 640 : 300,
        child: FlutterMap(
          mapController: _mapa,
          options: const MapOptions(initialCenter: LatLng(4.63, -74.11), initialZoom: 11.4),
          children: [
            MapaBase.capaTiles(context),
            CircleLayer(circles: [
              for (final e in zonas)
                CircleMarker(
                  point: e.centro,
                  radius: (e.nombre == z.nombre ? z.radioKm : e.radioKm) * 1000,
                  useRadiusInMeter: true,
                  color: _color(e.nombre == z.nombre ? z.nivel : e.nivel).withValues(alpha: 0.22),
                  borderColor: _color(e.nombre == z.nombre ? z.nivel : e.nivel),
                  borderStrokeWidth: e.nombre == z.nombre ? 2.5 : 1.2,
                ),
            ]),
            MarkerLayer(markers: [
              for (final e in zonas)
                Marker(
                  point: e.centro,
                  width: 130,
                  height: 30,
                  child: GestureDetector(
                    onTap: () => _seleccionar(e),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: p.tarjeta, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 6)]),
                        child: Text(e.nombre, style: Txt.nb(12, color: p.texto)),
                      ),
                    ),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );

    final lista = Column(
      children: [
        for (final e in zonas)
          Material(
            color: e.nombre == z.nombre ? p.suaveMorado : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _seleccionar(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.nombre, style: Txt.nb(14, color: p.texto)),
                          Text('${e.reportes} reportes${e.nombre == 'Kennedy' ? ' · 30 días' : ''}', style: Txt.n(12, color: p.textoSecundario)),
                        ],
                      ),
                    ),
                    EtiquetaRiesgo(e.nivel, corta: true),
                    if (e.automatica) ...[const SizedBox(width: 4), Pildora('Auto', fondo: p.suaveMorado, color: moradoTema(context))],
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Editar · ${z.nombre}', style: Txt.nb(15, color: p.texto)),
        const SizedBox(height: 12),
        Text('Nivel de riesgo', style: Txt.n(12, color: p.textoSecundario)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              for (final n in [NivelRiesgo.bajo, NivelRiesgo.medio, NivelRiesgo.alto])
                Expanded(
                  child: Material(
                    color: z.nivel == n ? _color(n) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _edicion = z.copyWith(nivel: n, automatica: false)),
                      child: SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(n.corta, style: z.nivel == n ? Txt.nb(13, color: n == NivelRiesgo.medio ? Colors.black : Colors.white) : Txt.n(13, color: p.textoSecundario)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: Text('Radio', style: Txt.n(12, color: p.textoSecundario))),
            Text('${z.radioKm.toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',')} km', style: Txt.nb(13, color: p.texto)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.moradoDev, thumbColor: AppColors.moradoDev, trackHeight: 5),
          child: Slider(value: z.radioKm, min: 0.5, max: 4, divisions: 7, onChanged: (v) => setState(() => _edicion = z.copyWith(radioKm: v))),
        ),
        Row(
          children: [
            Expanded(child: Text('Calcular nivel automáticamente', style: Txt.nb(13, color: p.texto))),
            Switch(value: z.automatica, onChanged: (v) => setState(() => _edicion = z.copyWith(automatica: v))),
          ],
        ),
        const SizedBox(height: 10),
        BotonPrincipal(
          texto: 'Guardar zona',
          color: AppColors.amarillo,
          alto: 44,
          tamanoTexto: 15,
          onPressed: () {
            ref.read(zonasAdminProvider.notifier).guardar(z);
            setState(() => _edicion = null);
            avisar(context, 'Zona ${z.nombre} guardada.');
          },
        ),
      ],
    );

    final panel = Tarjeta(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Zonas', style: Txt.nb(16, color: p.texto))),
              BotonAcento(texto: 'Nueva zona', icono: TablerIcons.plus, alto: 38, onPressed: _nueva),
            ],
          ),
          const SizedBox(height: 10),
          lista,
          Divider(color: p.borde, height: 28),
          editor,
        ],
      ),
    );

    return PantallaSecundaria(
      titulo: 'Zonas de riesgo',
      subtitulo: '${zonas.length} zonas activas · ${zonas.where((e) => e.automatica).length} automáticas',
      anchoMaximo: 1300,
      children: [
        if (ancho)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 7, child: mapa), const SizedBox(width: 20), Expanded(flex: 4, child: panel)])
        else ...[
          mapa,
          const SizedBox(height: 16),
          panel,
        ],
      ],
    );
  }
}

// ---------------- Notificaciones masivas ----------------

class NotificacionesMasivasScreen extends ConsumerStatefulWidget {
  const NotificacionesMasivasScreen({super.key});

  @override
  ConsumerState<NotificacionesMasivasScreen> createState() => _NotificacionesMasivasScreenState();
}

class _NotificacionesMasivasScreenState extends ConsumerState<NotificacionesMasivasScreen> {
  String _tipo = 'Alerta de hurto';
  final _titulo = TextEditingController(text: 'Hurtos de motos en Kennedy esta noche');
  final _mensaje = TextEditingController(text: 'Se reportaron 6 hurtos de motos cerca de la Av. Boyacá entre 6 y 9 p. m. Evita la zona y usa candado.');
  final _audiencia = <String>{'Kennedy', 'Bosa'};
  bool _push = true;
  bool _sms = false;
  bool _correo = true;
  String _envio = 'Enviar ahora';

  static const _poblacion = {'Kennedy': 9800, 'Bosa': 8600, 'Ciudad Bolívar': 7400, 'Toda Bogotá': 120000};

  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  int get _alcance => _audiencia.contains('Toda Bogotá') ? 120000 : _audiencia.fold(0, (a, z) => a + (_poblacion[z] ?? 0));

  String _miles(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  void _enviar() {
    if (_titulo.text.trim().isEmpty || _audiencia.isEmpty || !(_push || _sms || _correo)) {
      avisar(context, 'Completa el título, la audiencia y al menos un canal.', exito: false);
      return;
    }
    ref.read(enviosMasivosProvider.notifier).agregar(EnvioMasivo(_titulo.text.trim(), 'Ahora · ${_miles(_alcance)} personas', 0));
    avisar(context, _envio == 'Programar' ? 'Notificación programada.' : 'Notificación enviada a ${_miles(_alcance)} personas.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final ancho = !context.esCelular;
    Widget etiqueta(String t) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(t, style: Txt.nb(13, color: p.textoSecundario)));
    Widget canal(IconData i, String t, bool v, ValueChanged<bool> on) => Expanded(
          child: Row(
            children: [
              Icon(i, size: 20, color: p.texto),
              const SizedBox(width: 6),
              Expanded(child: Text(t, style: Txt.nb(13, color: p.texto))),
              Switch(value: v, onChanged: on),
            ],
          ),
        );

    final formulario = Tarjeta(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nueva notificación', style: Txt.nb(16, color: p.texto)),
          etiqueta('Tipo'),
          GrupoChips<String>(opciones: const ['Alerta de hurto', 'Zona de riesgo', 'Aviso general'], seleccionado: _tipo, etiqueta: (s) => s, alto: 32, onChanged: (s) => setState(() => _tipo = s)),
          etiqueta('Título'),
          TextField(controller: _titulo, onChanged: (_) => setState(() {}), style: Txt.n(14, color: p.texto)),
          etiqueta('Mensaje'),
          TextField(controller: _mensaje, onChanged: (_) => setState(() {}), maxLines: 3, style: Txt.n(14, color: p.texto)),
          etiqueta('Audiencia'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final z in _poblacion.keys)
                FilterChip(
                  label: Text(z),
                  selected: _audiencia.contains(z),
                  showCheckmark: false,
                  selectedColor: AppColors.amarillo,
                  backgroundColor: p.tarjeta,
                  labelStyle: Txt.r(12, color: _audiencia.contains(z) ? Colors.black : p.texto),
                  side: BorderSide(color: _audiencia.contains(z) ? AppColors.amarillo : p.borde),
                  onSelected: (v) => setState(() => v ? _audiencia.add(z) : _audiencia.remove(z)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Alcance estimado: ${_miles(_alcance)} personas', style: Txt.nb(13, color: moradoTema(context))),
          etiqueta('Canales'),
          Row(children: [
            canal(TablerIcons.bell, 'Push', _push, (v) => setState(() => _push = v)),
            const SizedBox(width: 12),
            canal(TablerIcons.message, 'SMS', _sms, (v) => setState(() => _sms = v)),
            const SizedBox(width: 12),
            canal(TablerIcons.mail, 'Correo', _correo, (v) => setState(() => _correo = v)),
          ]),
          etiqueta('Envío'),
          GrupoChips<String>(opciones: const ['Enviar ahora', 'Programar'], seleccionado: _envio, etiqueta: (s) => s, alto: 32, onChanged: (s) => setState(() => _envio = s)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: BotonAcento(texto: 'Enviar notificación', icono: TablerIcons.send, alto: 46, onPressed: _enviar)),
              if (!ancho) const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );

    final vistaPrevia = Tarjeta(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vista previa en el celular', style: Txt.nb(15, color: p.texto)),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 240,
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 40),
              decoration: const BoxDecoration(color: AppColors.fondoOscuro, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: AppColors.rojo, borderRadius: BorderRadius.circular(7)),
                      child: const Icon(TablerIcons.urgent, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ALERTA VIAL · ahora', style: Txt.nb(8, color: AppColors.grisTexto)),
                          Text(_titulo.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: Txt.nb(11, color: Colors.black)),
                          Text(_mensaje.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.n(9, color: AppColors.grisTexto)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final envios = ref.watch(enviosMasivosProvider);
    final ultimos = Tarjeta(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Últimos envíos', style: Txt.nb(15, color: p.texto)),
          for (final (i, e) in envios.indexed)
            FilaLista(
              titulo: e.titulo,
              subtitulo: e.detalle,
              estiloTitulo: Txt.nb(14, color: p.texto),
              divisor: i < envios.length - 1,
              padding: const EdgeInsets.symmetric(vertical: 12),
              trailing: e.apertura == 0
                  ? Pildora('Enviando', fondo: p.suaveAmarillo, color: p.textoMedio)
                  : Pildora('${e.apertura} % abiertas', fondo: p.suaveVerde, color: AppColors.verdeExito),
            ),
        ],
      ),
    );

    return PantallaSecundaria(
      titulo: 'Notificaciones masivas',
      subtitulo: 'Envía alertas a ciudadanos por zona',
      anchoMaximo: 1200,
      children: [
        if (ancho)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 13, child: formulario),
              const SizedBox(width: 20),
              Expanded(flex: 10, child: Column(children: [vistaPrevia, const SizedBox(height: 20), ultimos])),
            ],
          )
        else ...[
          formulario,
          const SizedBox(height: 16),
          vistaPrevia,
          const SizedBox(height: 16),
          ultimos,
        ],
      ],
    );
  }
}

// ---------------- CAI y puntos ----------------

class CaiAdminScreen extends StatefulWidget {
  const CaiAdminScreen({super.key});

  @override
  State<CaiAdminScreen> createState() => _CaiAdminScreenState();
}

class _CaiAdminScreenState extends State<CaiAdminScreen> {
  String _filtro = 'Todos';
  String? _sel = 'CAI Patio Bonito';
  final _mapa = MapController();

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  bool _incluye(CaiAdmin c) => switch (_filtro) {
        'CAI' => c.tipo == 'CAI',
        'Puntos seguros' => c.tipo == 'Punto seguro',
        'Estaciones' => c.tipo == 'Estación',
        _ => true,
      };

  Widget _estado(BuildContext context, EstadoCai e) {
    final p = context.paleta;
    return switch (e) {
      EstadoCai.activo => Pildora(e.etiqueta, fondo: p.suaveVerde, color: AppColors.verdeExito),
      EstadoCai.refuerzo => Pildora(e.etiqueta, fondo: p.suaveAmarillo, color: p.textoMedio),
      EstadoCai.inactivo => Pildora(e.etiqueta, fondo: p.chip, color: p.textoSecundario),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final lista = caisAdmin.where(_incluye).toList();
    final sel = caisAdmin.where((c) => c.nombre == _sel).firstOrNull;
    final ancho = !context.esCelular;
    void seleccionar(CaiAdmin c) {
      setState(() => _sel = c.nombre);
      _mapa.move(c.punto, 13);
    }

    final tabla = Tarjeta(
      padding: EdgeInsets.fromLTRB(ancho ? 14 : 0, 4, ancho ? 14 : 0, 4),
      child: ancho
          ? TablaSimple(
              columnas: const ['Nombre', 'Localidad', 'Teléfono', 'Patrullas', 'Estado'],
              flex: const [5, 4, 4, 2, 3],
              seleccionada: lista.indexWhere((c) => c.nombre == _sel),
              onFila: (i) => seleccionar(lista[i]),
              filas: [
                for (final c in lista)
                  [
                    Text(c.nombre, style: Txt.nb(13, color: p.texto)),
                    Text(c.localidad, style: Txt.n(13, color: p.texto)),
                    Text(c.telefono, style: Txt.n(12, color: p.textoSecundario)),
                    Text(c.patrullas?.toString() ?? '—', style: Txt.n(13, color: p.texto)),
                    Align(alignment: Alignment.centerLeft, child: _estado(context, c.estado)),
                  ],
              ],
            )
          : Column(
              children: [
                for (final (i, c) in lista.indexed)
                  FilaLista(
                    titulo: c.nombre,
                    subtitulo: '${c.localidad} · ${c.telefono}',
                    divisor: i < lista.length - 1,
                    onTap: () => seleccionar(c),
                    leading: const IconoCirculo(icono: TablerIcons.shield, fondo: AppColors.azulAutoridad, tamano: 40, tamanoIcono: 20),
                    trailing: _estado(context, c.estado),
                  ),
              ],
            ),
    );

    final mapa = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: ancho ? 600 : 280,
        child: FlutterMap(
          mapController: _mapa,
          options: const MapOptions(initialCenter: LatLng(4.65, -74.11), initialZoom: 11.2),
          children: [
            MapaBase.capaTiles(context),
            MarkerLayer(markers: [
              for (final c in lista)
                Marker(
                  point: c.punto,
                  width: 34,
                  height: 34,
                  child: GestureDetector(
                    onTap: () => seleccionar(c),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.azulAutoridad,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6)],
                      ),
                      child: const Icon(TablerIcons.shield, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              if (sel != null)
                Marker(
                  point: sel.punto,
                  width: 190,
                  height: 90,
                  alignment: const Alignment(0, 1.6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: p.tarjeta, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(sel.nombre, style: Txt.nb(13, color: p.texto)),
                        Text('${sel.localidad} · ${sel.patrullas ?? 0} patrullas', style: Txt.n(11, color: p.textoSecundario)),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(TablerIcons.phone, size: 14, color: AppColors.verdeExito), const SizedBox(width: 4), Text(sel.telefono, style: Txt.nb(12, color: p.texto))]),
                      ],
                    ),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );

    return PantallaSecundaria(
      titulo: 'CAI y puntos de atención',
      subtitulo: '148 CAI · 23 puntos seguros',
      anchoMaximo: 1300,
      children: [
        Row(
          children: [
            Expanded(
              child: GrupoChips<String>(
                opciones: const ['Todos', 'CAI', 'Puntos seguros', 'Estaciones'],
                seleccionado: _filtro,
                etiqueta: (s) => s,
                alto: 34,
                onChanged: (s) => setState(() => _filtro = s),
              ),
            ),
            if (ancho) BotonAcento(texto: 'Agregar CAI', icono: TablerIcons.plus, onPressed: () => avisar(context, 'El registro de CAI se conectará con la API.', exito: false)),
          ],
        ),
        const SizedBox(height: 16),
        if (ancho)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 13, child: tabla), const SizedBox(width: 20), Expanded(flex: 10, child: mapa)])
        else ...[
          mapa,
          const SizedBox(height: 16),
          tabla,
        ],
      ],
    );
  }
}
