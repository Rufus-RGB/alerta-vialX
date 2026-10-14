import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/campos.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/data/mapa_repository.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../../mapa/presentation/mapa_controller.dart';
import '../data/reporte_repository.dart';
import '../domain/reporte.dart';
import 'reporte_controller.dart';
import 'reporte_widgets.dart';

/// Reportar hurto. Celular: asistente de 3 pasos. Tablet/PC: formulario en un solo paso con 3 tarjetas.
class ReporteScreen extends ConsumerStatefulWidget {
  const ReporteScreen({super.key});

  @override
  ConsumerState<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends ConsumerState<ReporteScreen> {
  final _mapa = MapController();
  late final TextEditingController _placa;
  late final TextEditingController _direccion;
  late final TextEditingController _referencia;
  late final TextEditingController _descripcion;
  final _buscar = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final b = ref.read(reporteControllerProvider).borrador;
    _placa = TextEditingController(text: b.placa);
    _direccion = TextEditingController(text: b.direccion);
    _referencia = TextEditingController(text: b.referencia);
    _descripcion = TextEditingController(text: b.descripcion);
  }

  ReporteController get _ctrl => ref.read(reporteControllerProvider.notifier);

  @override
  void dispose() {
    for (final c in [_placa, _direccion, _referencia, _descripcion, _buscar]) {
      c.dispose();
    }
    _mapa.dispose();
    super.dispose();
  }

  void _mostrar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _moverPin(LatLng punto, {bool mover = false}) {
    final barrio = localidadCercana(punto);
    _ctrl.actualizar((b) => b.copyWith(punto: punto, barrio: barrio));
    if (mover) _mapa.move(punto, 15);
  }

  void _buscarDireccion(String q) {
    final t = q.toLowerCase().trim();
    if (t.isEmpty) return;
    final loc = localidadesBogota.entries.where((e) => e.key.toLowerCase().contains(t)).firstOrNull;
    if (loc != null) {
      _moverPin(loc.value, mover: true);
      _direccion.text = q;
      _ctrl.actualizar((b) => b.copyWith(direccion: q));
    } else {
      _mostrar('Escribe una localidad (p. ej. Chapinero) o toca el mapa para ubicar el punto.');
    }
  }

  Future<void> _miUbicacion() async {
    try {
      final p = await obtenerUbicacionActual();
      _moverPin(p, mover: true);
    } catch (e) {
      _mostrar('$e');
    }
  }

  bool _validarPaso(int paso) {
    final b = ref.read(reporteControllerProvider).borrador;
    if (paso == 0) {
      if (b.marca == null || b.modelo == null || b.color == null) {
        _mostrar('Completa marca, modelo y color.');
        return false;
      }
      if (!placaValida(b.placa)) {
        _mostrar(b.vehiculo == TipoVehiculo.moto ? 'Placa de moto inválida (ej: ABC12D).' : 'Placa inválida (ej: ABC123).');
        return false;
      }
    }
    if (paso == 1 && !b.ubicacionCompleta) {
      _mostrar('Escribe la dirección del incidente.');
      return false;
    }
    return true;
  }

  Future<void> _enviar() async {
    if (!_validarPaso(0) || !_validarPaso(1)) return;
    setState(() => _enviando = true);
    final b = ref.read(reporteControllerProvider).borrador;
    try {
      final reporte = await ref.read(reporteRepositoryProvider).enviar(b);
      if (!mounted) return;
      ref.invalidate(misReportesProvider);
      ref.invalidate(incidentesProvider);
      _ctrl.reiniciar();
      if (mounted) context.go('/reporte/enviado/${reporte.id}');
    } on SinConexionException {
      if (!mounted) return;
      _ctrl.reiniciar();
      if (mounted) context.go('/reporte/sin-conexion');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ---------- Bloques de formulario ----------

  Widget _datosVehiculo(BorradorReporte b, {required bool ancho}) {
    final marcas = marcasPorVehiculo[b.vehiculo]!;
    final modelos = b.marca == null ? const <String>[] : marcas[b.marca] ?? const <String>[];
    final placa = TextField(
      controller: _placa,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')), LengthLimitingTextInputFormatter(6), _Mayusculas()],
      onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(placa: v)),
      style: Txt.n(13, color: context.paleta.texto),
      decoration: InputDecoration(
        hintText: b.vehiculo == TipoVehiculo.moto ? 'Ej: ABC12D' : 'Ej: ABC123',
        hintStyle: Txt.r(12, color: context.paleta.placeholder),
        prefixIcon: ancho ? const Icon(TablerIcons.id, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      ),
    );
    final alto = ancho ? 48.0 : 40.0;
    Widget campo(String etiqueta, Widget c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [EtiquetaCampo(etiqueta, tamano: ancho ? 14 : 16), c],
        );
    final marca = campo('Marca', SelectorCampo(valor: b.marca, opciones: marcas.keys.toList(), alto: alto, onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(marca: v, limpiarModelo: true))));
    final modelo = campo('Modelo', SelectorCampo(valor: b.modelo, opciones: modelos, alto: alto, hint: b.marca == null ? 'Elige la marca' : 'Selecciona', onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(modelo: v))));
    final campoPlaca = campo('Placa', SizedBox(height: alto, child: placa));
    final color = campo('Color', SelectorCampo(valor: b.color, opciones: coloresVehiculo, alto: alto, onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(color: v))));
    final fecha = campo(ancho ? 'Fecha y hora del hurto' : 'Fecha y hora del hurto', CampoFechaHora(fecha: b.fecha, alto: alto, onChanged: (f) => _ctrl.actualizar((x) => x.copyWith(fecha: f))));
    final selector = SelectorTipoVehiculo(
      valor: b.vehiculo,
      alto: ancho ? 84 : 120,
      ancho: ancho ? 138 : null,
      onChanged: (t) {
        if (t != b.vehiculo) {
          _ctrl.actualizar((x) => BorradorReporte(vehiculo: t, fecha: x.fecha, punto: x.punto, barrio: x.barrio, direccion: x.direccion, referencia: x.referencia, descripcion: x.descripcion, fotos: x.fotos, placa: x.placa));
        }
      },
    );
    if (!ancho) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: selector),
          const SizedBox(height: 20),
          marca,
          const SizedBox(height: 14),
          modelo,
          const SizedBox(height: 14),
          campoPlaca,
          const SizedBox(height: 14),
          color,
          const SizedBox(height: 14),
          fecha,
        ],
      );
    }
    Widget fila(Widget a, Widget b) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: selector),
        const SizedBox(height: 16),
        fila(marca, modelo),
        const SizedBox(height: 12),
        fila(campoPlaca, color),
        const SizedBox(height: 12),
        fecha,
        const SizedBox(height: 12),
        _campoDescripcion(ancho: true),
      ],
    );
  }

  Widget _campoDescripcion({required bool ancho}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EtiquetaCampo('Descripción', tamano: ancho ? 14 : 16),
          TextField(
            controller: _descripcion,
            maxLines: ancho ? 4 : 2,
            onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(descripcion: v)),
            style: Txt.n(14, color: context.paleta.texto),
            decoration: const InputDecoration(hintText: 'Ej: Sujeto en moto, chaqueta negra, salió hacia el norte'),
          ),
        ],
      );

  Widget _ubicacion(BorradorReporte b, {required bool ancho}) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!ancho) ...[
          Buscador(hint: 'Buscar dirección o zona', controller: _buscar, onSubmitted: _buscarDireccion, alto: 46, radio: 14),
          const SizedBox(height: 12),
        ],
        MapaSelector(
          controller: _mapa,
          punto: b.punto,
          etiqueta: b.barrio,
          alto: ancho ? 266 : 230,
          onPunto: _moverPin,
          onMiUbicacion: _miUbicacion,
        ),
        const SizedBox(height: 18),
        EtiquetaCampo(ancho ? 'Dirección' : 'Dirección del incidente', tamano: ancho ? 14 : 16),
        TextField(
          controller: _direccion,
          onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(direccion: v)),
          style: Txt.n(14, color: p.texto),
          decoration: const InputDecoration(prefixIcon: Icon(TablerIcons.map_pin, size: 20), hintText: 'Calle, carrera y barrio'),
        ),
        if (!ancho) ...[
          const SizedBox(height: 14),
          const EtiquetaCampo('Referencia (opcional)'),
          TextField(
            controller: _referencia,
            onChanged: (v) => _ctrl.actualizar((x) => x.copyWith(referencia: v)),
            style: Txt.n(14, color: p.texto),
            decoration: const InputDecoration(hintText: 'Ej: Frente al parque'),
          ),
        ],
      ],
    );
  }

  Widget _confirmar(BorradorReporte b) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.only(left: 10, bottom: 4), child: Text('Resumen de tu reporte', style: Txt.r(16, color: p.texto))),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              FilaLista(
                subtituloArriba: true,
                subtitulo: 'Vehículo',
                titulo: '${b.nombreVehiculo} · ${b.modelo ?? '-'}',
                leading: Icon(b.vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car, size: 24, color: p.texto),
              ),
              FilaLista(subtituloArriba: true, subtitulo: 'Placa', titulo: b.placa.toUpperCase(), leading: Icon(TablerIcons.id, size: 24, color: p.texto)),
              FilaLista(subtituloArriba: true, subtitulo: 'Ubicación', titulo: b.direccion, leading: Icon(TablerIcons.map_pin, size: 24, color: p.texto)),
              FilaLista(
                subtituloArriba: true,
                subtitulo: 'Fecha y hora',
                titulo: fechaCorta(b.fecha, conAnio: true),
                divisor: false,
                leading: Icon(TablerIcons.calendar, size: 24, color: p.texto),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _campoDescripcion(ancho: false),
        const SizedBox(height: 16),
        const EtiquetaCampo('Fotos (opcional)'),
        SelectorFotos(fotos: b.fotos, onChanged: (f) => _ctrl.actualizar((x) => x.copyWith(fotos: f))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(reporteControllerProvider);
    return context.esCelular ? _celular(estado) : _anchoLayout(estado.borrador);
  }

  Widget _celular(EstadoFormulario estado) {
    final b = estado.borrador;
    final inferior = MediaQuery.paddingOf(context).bottom;
    final ultimo = estado.paso == 2;
    return Scaffold(
      appBar: EncabezadoPantalla(
        titulo: 'Reportar Hurto',
        onAtras: estado.paso > 0 ? () => _ctrl.irAPaso(estado.paso - 1) : null,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(19, 4, 19, inferior + 24),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: IndicadorPasos(actual: estado.paso, onPaso: _ctrl.irAPaso)),
          const SizedBox(height: 20),
          switch (estado.paso) {
            0 => _datosVehiculo(b, ancho: false),
            1 => _ubicacion(b, ancho: false),
            _ => _confirmar(b),
          },
          const SizedBox(height: 32),
          ultimo
              ? BotonPrincipal(texto: 'Enviar reporte', onPressed: _enviar, cargando: _enviando, alto: 50)
              : BotonPrincipal(
                  texto: 'Siguiente',
                  icono: TablerIcons.arrow_right,
                  iconoDerecha: true,
                  color: AppColors.amarillo,
                  alto: 50,
                  tamanoTexto: 20,
                  onPressed: () {
                    if (_validarPaso(estado.paso)) _ctrl.irAPaso(estado.paso + 1);
                  },
                ),
        ],
      ),
    );
  }

  Widget _anchoLayout(BorradorReporte b) {
    final p = context.paleta;
    final paso = b.vehiculoCompleto ? (b.ubicacionCompleta ? 2 : 1) : 0;
    Widget bloque(String titulo, Widget hijo) => Tarjeta(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Text(titulo, style: Txt.r(17, color: p.texto)), const SizedBox(height: 14), hijo],
          ),
        );
    return SingleChildScrollView(
      padding: paddingEscritorio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoEscritorio(titulo: 'Reportar hurto', subtitulo: 'Completa los datos en un solo paso'),
          Padding(
            padding: const EdgeInsets.only(right: 300),
            child: IndicadorPasos(actual: paso, etiquetas: const ['Vehículo', 'Ubicación', 'Confirmar']),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 620, child: bloque('1 · Datos del vehículo', _datosVehiculo(b, ancho: true))),
              const SizedBox(width: 20),
              Expanded(
                flex: 488,
                child: Column(
                  children: [
                    bloque('2 · Ubicación', _ubicacion(b, ancho: true)),
                    const SizedBox(height: 20),
                    bloque(
                      '3 · Fotos y envío',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SelectorFotos(fotos: b.fotos, tamano: 60, onChanged: (f) => _ctrl.actualizar((x) => x.copyWith(fotos: f))),
                          const SizedBox(height: 24),
                          BotonPrincipal(texto: 'Enviar reporte', icono: TablerIcons.send, onPressed: _enviar, cargando: _enviando, alto: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
