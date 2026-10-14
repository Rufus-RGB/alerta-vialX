import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

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
import '../../auth/domain/usuario.dart';
import '../data/dev_repository.dart';
import 'dev_comun.dart';

Widget _icono(BuildContext context, IconData i) =>
    IconoCirculo(icono: i, fondo: context.paleta.suaveMorado, color: moradoTema(context), tamano: 36, tamanoIcono: 20);

// ---------------- Configuración del sistema ----------------

class SistemaScreen extends ConsumerStatefulWidget {
  const SistemaScreen({super.key});

  @override
  ConsumerState<SistemaScreen> createState() => _SistemaScreenState();
}

class _SistemaScreenState extends ConsumerState<SistemaScreen> {
  late ConfigSistema _c;

  @override
  void initState() {
    super.initState();
    _c = ref.read(configSistemaProvider);
  }

  Widget _interruptor(IconData i, String t, bool v, ValueChanged<bool> on, {String? sub, bool divisor = true}) => FilaLista(
        titulo: t,
        subtitulo: sub,
        divisor: divisor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        leading: _icono(context, i),
        trailing: Switch(value: v, onChanged: on),
        onTap: () => on(!v),
      );

  Widget _valor(IconData i, String t, String v, {VoidCallback? onTap, bool divisor = true}) => FilaLista(
        titulo: t,
        divisor: divisor,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        leading: _icono(context, i),
        onTap: onTap,
        trailing: Text(v, style: Txt.nb(14, color: context.paleta.textoSecundario)),
      );

  Future<void> _elegirCierre() async {
    final h = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cierre automático de casos'),
        children: [for (final h in [24, 48, 72, 168]) SimpleDialogOption(onPressed: () => Navigator.pop(ctx, h), child: Text('$h h'))],
      ),
    );
    if (h != null) setState(() => _c = _c.copyWith(cierreHoras: h));
  }

  @override
  Widget build(BuildContext context) {
    return PantallaSecundaria(
      titulo: 'Configuración del sistema',
      subtitulo: 'Parámetros globales de Alerta Vial',
      children: [
        const TituloSeccion('Mapa', padding: EdgeInsets.fromLTRB(10, 4, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _interruptor(TablerIcons.flame, 'Mapa de calor', _c.mapaCalor, (v) => setState(() => _c = _c.copyWith(mapaCalor: v))),
            _interruptor(TablerIcons.map, 'Zonas de riesgo automáticas', _c.zonasAutomaticas, (v) => setState(() => _c = _c.copyWith(zonasAutomaticas: v)), divisor: false),
          ]),
        ),
        const TituloSeccion('Reportes', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _interruptor(TablerIcons.photo, 'Exigir foto al reportar', _c.exigirFoto, (v) => setState(() => _c = _c.copyWith(exigirFoto: v))),
            _interruptor(TablerIcons.robot, 'Moderación automática', _c.moderacionAutomatica, (v) => setState(() => _c = _c.copyWith(moderacionAutomatica: v)), sub: 'Marca posibles reportes falsos'),
            _valor(TablerIcons.clock, 'Cierre automático de casos', '${_c.cierreHoras} h', onTap: _elegirCierre, divisor: false),
          ]),
        ),
        const TituloSeccion('Mantenimiento', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(children: [
            _interruptor(TablerIcons.tool, 'Modo mantenimiento', _c.mantenimiento, (v) => setState(() => _c = _c.copyWith(mantenimiento: v))),
            _valor(TablerIcons.info_circle, 'Versión de la app', '1.0.3', divisor: false),
          ]),
        ),
        const SizedBox(height: 22),
        BotonPrincipal(
          texto: 'Guardar configuración',
          color: AppColors.amarillo,
          onPressed: () {
            ref.read(configSistemaProvider.notifier).cambiar(_c);
            avisar(context, 'Configuración guardada.');
          },
        ),
      ],
    );
  }
}

// ---------------- Analítica ----------------

class AnaliticaScreen extends StatefulWidget {
  const AnaliticaScreen({super.key});

  @override
  State<AnaliticaScreen> createState() => _AnaliticaScreenState();
}

class _AnaliticaScreenState extends State<AnaliticaScreen> {
  String _periodo = 'Semana';

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final metricas = metricasPorPeriodo[_periodo]!;
    final ancho = !context.esCelular;
    Widget metrica((String, String, String) m) {
      final (valor, delta, etiqueta) = m;
      return Tarjeta(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(valor, style: Txt.r(26, color: p.texto))),
                Text(delta, style: Txt.nb(12, color: AppColors.verdeExito)),
              ],
            ),
            const SizedBox(height: 6),
            Text(etiqueta, style: Txt.n(13, color: p.textoSecundario)),
          ],
        ),
      );
    }

    return PantallaSecundaria(
      titulo: 'Analítica',
      subtitulo: 'Métricas de reportes y respuesta',
      anchoMaximo: 1100,
      children: [
        GrupoChips<String>(opciones: const ['Hoy', 'Semana', 'Mes'], seleccionado: _periodo, etiqueta: (s) => s, alto: 36, onChanged: (s) => setState(() => _periodo = s)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final columnas = ancho ? 4 : 2;
            final w = (c.maxWidth - 12 * (columnas - 1)) / columnas;
            return Wrap(spacing: 12, runSpacing: 12, children: [for (final m in metricas) SizedBox(width: w, child: metrica(m))]);
          },
        ),
        const SizedBox(height: 16),
        Tarjeta(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reportes por localidad', style: Txt.nb(16, color: p.texto)),
              const SizedBox(height: 22),
              BarrasPorCategoria(datos: reportesPorLocalidad, anchoEtiqueta: ancho ? 140 : 112),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(color: p.suaveMorado, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(TablerIcons.trending_up, color: moradoTema(context)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hora pico de hurtos: 6 a 8 p. m.', style: Txt.nb(15, color: p.texto)),
                    Text('Viernes es el día con más reportes', style: Txt.n(13, color: p.textoSecundario)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Registros de actividad ----------------

class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key});

  @override
  State<RegistrosScreen> createState() => _RegistrosScreenState();
}

class _RegistrosScreenState extends State<RegistrosScreen> {
  String _filtro = 'Todos';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final lista = registrosActividad
        .where((r) => (_filtro == 'Todos' || r.categoria == _filtro) && (_q.isEmpty || r.texto.toLowerCase().contains(_q.toLowerCase())))
        .toList();
    return PantallaSecundaria(
      titulo: 'Registros de actividad',
      subtitulo: 'Eventos del sistema de hoy',
      anchoMaximo: 900,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: Txt.n(14, color: p.texto),
            decoration: const InputDecoration(hintText: 'Buscar en los registros', prefixIcon: Icon(TablerIcons.search, size: 20)),
          ),
        ),
        const SizedBox(height: 14),
        GrupoChips<String>(
          opciones: const ['Todos', 'Errores', 'Usuarios', 'Reportes', 'Sistema'],
          seleccionado: _filtro,
          etiqueta: (s) => s,
          alto: 36,
          onChanged: (s) => setState(() => _filtro = s),
        ),
        const SizedBox(height: 14),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (lista.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Text('Sin registros.', style: Txt.n(14, color: p.textoSecundario))),
              for (final (i, r) in lista.indexed)
                FilaLista(
                  titulo: r.texto,
                  subtitulo: '${r.hora} · ${r.categoria}',
                  estiloTitulo: Txt.nb(15, color: p.texto),
                  divisor: i < lista.length - 1,
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                  leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Estado del servicio ----------------

const _servicios = [
  Servicio('API principal', 'Latencia 82 ms', EstadoServicio.operativo, '99,98 %', TablerIcons.server),
  Servicio('Base de datos', 'Latencia 12 ms', EstadoServicio.operativo, '99,98 %', TablerIcons.database),
  Servicio('Servicio de mapas', 'Latencia 1,2 s', EstadoServicio.degradado, '99,2 %', TablerIcons.map, fallas: {26: 1, 28: 1, 29: 1}),
  Servicio('Notificaciones push', 'Latencia 240 ms', EstadoServicio.operativo, '99,98 %', TablerIcons.bell),
  Servicio('SMS', 'Latencia 1,8 s', EstadoServicio.operativo, '99,98 %', TablerIcons.message, fallas: {12: 2}),
  Servicio('Autenticación', 'Latencia 96 ms', EstadoServicio.operativo, '99,98 %', TablerIcons.lock),
];

class EstadoServicioScreen extends StatelessWidget {
  const EstadoServicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final ancho = !context.esCelular;
    Widget tarjeta(Servicio s) => Tarjeta(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _icono(context, s.icono),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(s.nombre, style: Txt.nb(15, color: p.texto)), Text(s.latencia, style: Txt.n(12, color: p.textoSecundario))],
                    ),
                  ),
                  s.estado == EstadoServicio.operativo
                      ? Pildora('Operativo', fondo: p.suaveVerde, color: AppColors.verdeExito)
                      : Pildora('Degradado', fondo: p.suaveAmarillo, color: p.textoMedio),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 22,
                child: Row(
                  children: [
                    for (var d = 0; d < 30; d++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: switch (s.fallas[d]) {
                              1 => AppColors.amarillo,
                              2 => AppColors.rojo,
                              _ => AppColors.verdeExito,
                            },
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text('Últimos 30 días', style: Txt.n(11, color: p.textoSecundario))),
                  Text(s.disponibilidad, style: Txt.nb(11, color: p.texto)),
                ],
              ),
            ],
          ),
        );
    Widget recurso(String t, double v, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [Expanded(child: Text(t, style: Txt.n(13, color: p.textoSecundario))), Text('${(v * 100).round()} %', style: Txt.nb(13, color: p.texto))]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: v, minHeight: 8, color: c, backgroundColor: context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFEEF0F2)),
              ),
            ],
          ),
        );
    final incidentes = [
      ('Lentitud en el servicio de mapas', 'En investigación · hace 25 min', AppColors.amarillo),
      ('Error 502 en mapas (12 s)', 'Resuelto · hoy 4:37 p. m.', AppColors.verdeExito),
      ('Fallo de 3 SMS por el operador', 'Resuelto · hoy 12:05 p. m.', AppColors.verdeExito),
    ];
    return PantallaSecundaria(
      titulo: 'Estado del servicio',
      subtitulo: 'Monitoreo en tiempo real',
      anchoMaximo: 1200,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: p.suaveVerde, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const IconoCirculo(icono: TablerIcons.check, fondo: AppColors.verdeExito, tamano: 40, tamanoIcono: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Todos los sistemas operativos', style: Txt.r(18, color: p.texto)),
                    Text('1 servicio con rendimiento degradado · Disponibilidad 30 días: 99,94 %', style: Txt.n(12, color: p.textoSecundario)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final columnas = c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1);
            final w = (c.maxWidth - 16 * (columnas - 1)) / columnas;
            return Wrap(spacing: 16, runSpacing: 16, children: [for (final s in _servicios) SizedBox(width: w, child: tarjeta(s))]);
          },
        ),
        const SizedBox(height: 16),
        Flex(
          direction: ancho ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: ancho ? 3 : 0,
              child: Tarjeta(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Incidentes recientes', style: Txt.nb(15, color: p.texto)),
                    const SizedBox(height: 12),
                    for (final (t, s, c) in incidentes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(padding: const EdgeInsets.only(top: 5), child: Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle))),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text(t, style: Txt.nb(13, color: p.texto)), Text(s, style: Txt.n(12, color: p.textoSecundario))],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: ancho ? 16 : 0, height: ancho ? 0 : 16),
            Flexible(
              flex: ancho ? 2 : 0,
              child: Tarjeta(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Recursos del servidor', style: Txt.nb(15, color: p.texto)),
                    const SizedBox(height: 16),
                    recurso('CPU', 0.42, AppColors.moradoDev),
                    recurso('Memoria', 0.67, AppColors.amarillo),
                    recurso('Almacenamiento', 0.31, AppColors.verdeExito),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Roles y permisos ----------------

const _ordenRoles = [Rol.ciudadano, Rol.autoridad, Rol.dev];

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  Rol _rol = Rol.autoridad;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final permisos = ref.watch(permisosProvider);
    final usuarios = {Rol.ciudadano: '1.180 usuarios', Rol.autoridad: '62 usuarios', Rol.dev: '6 usuarios'};
    final ancho = !context.esCelular;

    Widget casilla(String permiso, Rol rol) {
      final activo = permisos[permiso]?.contains(rol) ?? false;
      final color = rol == Rol.ciudadano ? AppColors.amarillo : rol.color;
      return Center(
        child: SizedBox.square(
          dimension: 22,
          child: Checkbox(
            value: activo,
            fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? color : Colors.transparent),
            checkColor: rol == Rol.ciudadano ? Colors.black : Colors.white,
            onChanged: (_) => ref.read(permisosProvider.notifier).alternar(permiso, rol),
          ),
        ),
      );
    }

    final roles = Column(
      children: [
        for (final r in _ordenRoles)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: r == _rol ? Border.all(color: AppColors.moradoDev, width: 2) : null,
              ),
              child: Tarjeta(
                color: r == _rol ? p.suaveMorado : null,
                onTap: () => setState(() => _rol = r),
                child: Row(
                  children: [
                    IconoCirculo(icono: r.icono, fondo: r.color, color: r.sobreColor, tamano: 44, tamanoIcono: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(r.etiqueta, style: Txt.nb(16, color: p.texto)), Text(usuarios[r]!, style: Txt.n(12, color: p.textoSecundario))],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => avisar(context, 'La creación de roles personalizados llegará con la API.', exito: false),
            icon: const Icon(TablerIcons.plus, size: 18),
            label: const Text('Nuevo rol'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), textStyle: Txt.nb(14)),
          ),
        ),
      ],
    );

    final matriz = Tarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Matriz de permisos', style: Txt.nb(16, color: p.texto))),
              BotonAcento(texto: 'Guardar', icono: TablerIcons.check, alto: 38, onPressed: () => avisar(context, 'Permisos guardados.')),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: p.borde),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              for (final r in _ordenRoles) SizedBox(width: ancho ? 84 : 64, child: Text(r.etiqueta, textAlign: TextAlign.center, style: Txt.nb(11, color: p.textoSecundario))),
            ],
          ),
          for (final (i, permiso) in permisosSistema.indexed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      permiso,
                      style: Txt.n(13, color: (permisos[permiso]?.contains(_rol) ?? false) ? p.texto : p.textoSecundario),
                    ),
                  ),
                  for (final r in _ordenRoles) SizedBox(width: ancho ? 84 : 64, child: casilla(permiso, r)),
                ],
              ),
            ),
            if (i < permisosSistema.length - 1) Divider(color: p.divisor),
          ],
        ],
      ),
    );

    return PantallaSecundaria(
      titulo: 'Roles y permisos',
      subtitulo: 'Define qué puede hacer cada tipo de usuario',
      anchoMaximo: 1200,
      children: [
        if (ancho)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 300, child: roles), const SizedBox(width: 20), Expanded(child: matriz)])
        else ...[
          roles,
          const SizedBox(height: 16),
          matriz,
        ],
      ],
    );
  }
}

// ---------------- Exportar datos ----------------

class ExportarScreen extends ConsumerStatefulWidget {
  const ExportarScreen({super.key});

  @override
  ConsumerState<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends ConsumerState<ExportarScreen> {
  String _datos = 'Reportes';
  String _formato = 'Excel';
  DateTimeRange _rango = DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 13));
  final _campos = {
    'Fecha y hora': true,
    'Tipo de vehículo': true,
    'Placa': true,
    'Localidad': true,
    'Coordenadas': false,
    'Estado del caso': true,
    'Datos del denunciante': false,
    'Fotos': false,
  };
  bool _anonimizar = true;

  String _fecha(DateTime f) {
    const m = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'];
    return '${f.day} ${m[f.month - 1]} ${f.year}';
  }

  Future<void> _elegirRango() async {
    final r = await showDateRangePicker(context: context, firstDate: DateTime(2025), lastDate: DateTime.now(), initialDateRange: _rango);
    if (r != null) setState(() => _rango = r);
  }

  void _generar() {
    final ext = switch (_formato) {
      'CSV' => 'csv',
      'PDF' => 'pdf',
      _ => 'xlsx',
    };
    final nombre = '${_datos}_${_rango.end.year}${_rango.end.month.toString().padLeft(2, '0')}${_rango.end.day.toString().padLeft(2, '0')}.$ext';
    ref.read(exportacionesProvider.notifier).agregar(Exportacion(nombre, 'Ahora', 'procesando'));
    avisar(context, 'Generando $nombre…');
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      ref.read(exportacionesProvider.notifier).reemplazar((e) => e.archivo == nombre, (e) => Exportacion(e.archivo, 'Hoy · 1,1 MB', 'listo'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final ancho = !context.esCelular;
    final exportaciones = ref.watch(exportacionesProvider);
    Widget etiqueta(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(t, style: Txt.nb(13, color: p.textoSecundario)));
    final formulario = Tarjeta(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nueva exportación', style: Txt.nb(16, color: p.texto)),
          etiqueta('Datos'),
          GrupoChips<String>(opciones: const ['Reportes', 'Usuarios', 'Casos', 'Zonas', 'Notificaciones'], seleccionado: _datos, etiqueta: (s) => s, alto: 34, onChanged: (s) => setState(() => _datos = s)),
          etiqueta('Rango de fechas'),
          Row(
            children: [
              for (final (i, f) in [_rango.start, _rango.end].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), alignment: Alignment.centerLeft, textStyle: Txt.n(13), side: BorderSide(color: p.borde)),
                    onPressed: _elegirRango,
                    icon: const Icon(TablerIcons.calendar, size: 18),
                    label: Text(_fecha(f)),
                  ),
                ),
              ],
            ],
          ),
          etiqueta('Formato'),
          GrupoChips<String>(opciones: const ['CSV', 'Excel', 'PDF'], seleccionado: _formato, etiqueta: (s) => s, alto: 34, onChanged: (s) => setState(() => _formato = s)),
          etiqueta('Campos'),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              children: [
                for (final campo in _campos.keys)
                  SizedBox(
                    width: c.maxWidth / 2,
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _campos[campo],
                      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.moradoDev : Colors.transparent),
                      checkColor: Colors.white,
                      title: Text(campo, style: Txt.n(13, color: p.texto)),
                      onChanged: (v) => setState(() => _campos[campo] = v ?? false),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(color: p.suaveMorado, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(TablerIcons.lock, color: moradoTema(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text('Anonimizar datos personales', style: Txt.nb(14, color: p.texto)), Text('Recomendado · Ley 1581 de 2012', style: Txt.n(12, color: p.textoSecundario))],
                  ),
                ),
                Switch(value: _anonimizar, onChanged: (v) => setState(() => _anonimizar = v)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BotonAcento(texto: 'Generar exportación', icono: TablerIcons.download, alto: 46, onPressed: _generar),
        ],
      ),
    );
    final recientes = Tarjeta(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Exportaciones recientes', style: Txt.nb(16, color: p.texto)),
          const SizedBox(height: 6),
          for (final (i, e) in exportaciones.indexed)
            FilaLista(
              titulo: e.archivo,
              subtitulo: e.detalle,
              estiloTitulo: Txt.nb(14, color: p.texto),
              divisor: i < exportaciones.length - 1,
              padding: const EdgeInsets.symmetric(vertical: 12),
              leading: _icono(context, TablerIcons.file_text),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  switch (e.estado) {
                    'listo' => Pildora('Listo', fondo: p.suaveVerde, color: AppColors.verdeExito),
                    'procesando' => Pildora('Procesando', fondo: p.suaveAmarillo, color: p.textoMedio),
                    _ => Pildora('Vencido', fondo: p.chip, color: p.textoSecundario),
                  },
                  SizedBox(
                    width: 40,
                    child: e.estado == 'listo'
                        ? IconButton(
                            tooltip: 'Descargar',
                            onPressed: () => avisar(context, 'Descarga de ${e.archivo} disponible cuando se conecte la API.', exito: false),
                            icon: Icon(TablerIcons.download, size: 20, color: p.textoSecundario),
                          )
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    return PantallaSecundaria(
      titulo: 'Exportar datos',
      subtitulo: 'Descarga información para informes y análisis',
      anchoMaximo: 1200,
      children: [
        if (ancho)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 13, child: formulario), const SizedBox(width: 20), Expanded(flex: 10, child: recientes)])
        else ...[
          formulario,
          const SizedBox(height: 16),
          recientes,
        ],
      ],
    );
  }
}
