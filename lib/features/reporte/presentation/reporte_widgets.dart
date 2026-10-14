import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../auth/presentation/verificacion_autoridad_screen.dart' show BordePunteado;
import '../../mapa/domain/modelos_mapa.dart';
import '../../mapa/presentation/mapa_base.dart';

/// Indicador de 3 pasos (círculos de 42 px unidos por una línea amarilla/gris).
class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({super.key, required this.actual, this.etiquetas = const ['Información', 'Ubicación', 'Confirmar'], this.onPaso});

  final int actual;
  final List<String> etiquetas;
  final ValueChanged<int>? onPaso;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final gris = context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFD9D9D9);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < etiquetas.length; i++) ...[
              if (i > 0) Expanded(child: Container(height: 4, color: i <= actual ? AppColors.amarillo : gris)),
              GestureDetector(
                onTap: onPaso == null || i > actual ? null : () => onPaso!(i),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i <= actual ? AppColors.amarillo : gris, shape: BoxShape.circle),
                  child: i < actual
                      ? const Icon(TablerIcons.check, size: 22, color: Colors.black)
                      : Text('${i + 1}', style: Txt.r(17, color: i == actual ? Colors.black : const Color(0xFF363636))),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < etiquetas.length; i++)
              Expanded(
                child: Text(
                  etiquetas[i],
                  textAlign: i == 0 ? TextAlign.left : (i == etiquetas.length - 1 ? TextAlign.right : TextAlign.center),
                  style: Txt.r(16, color: i <= actual ? p.texto : p.textoSecundario),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tarjetas "Motocicleta" / "Automóvil" (seleccionada en amarillo con check negro).
class SelectorTipoVehiculo extends StatelessWidget {
  const SelectorTipoVehiculo({super.key, required this.valor, required this.onChanged, this.alto = 120, this.ancho});

  final TipoVehiculo valor;
  final ValueChanged<TipoVehiculo> onChanged;
  final double alto;
  final double? ancho;

  @override
  Widget build(BuildContext context) {
    Widget tarjeta(TipoVehiculo t) {
      final p = context.paleta;
      final activo = t == valor;
      return Semantics(
        selected: activo,
        button: true,
        child: Material(
          color: activo ? AppColors.amarillo : p.tarjeta,
          elevation: activo || context.esOscuro ? 0 : 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: activo ? BorderSide.none : BorderSide(color: p.borde),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(t),
            child: SizedBox(
              height: alto,
              width: ancho,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car, size: alto * 0.43, color: activo ? Colors.black : p.texto),
                        SizedBox(height: alto * 0.08),
                        Text(t == TipoVehiculo.moto ? 'Motocicleta' : 'Automóvil', style: Txt.r(alto < 100 ? 13 : 16, color: activo ? Colors.black : p.texto)),
                      ],
                    ),
                  ),
                  if (activo)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: const Icon(TablerIcons.check, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (ancho == null) Expanded(child: tarjeta(TipoVehiculo.moto)) else tarjeta(TipoVehiculo.moto),
        SizedBox(width: ancho == null ? 29 : 12),
        if (ancho == null) Expanded(child: tarjeta(TipoVehiculo.auto)) else tarjeta(TipoVehiculo.auto),
      ],
    );
  }
}

/// Etiqueta de campo del formulario de reporte (16 px redondeada).
class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo(this.texto, {super.key, this.tamano = 16});

  final String texto;
  final double tamano;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(left: 10, bottom: 4), child: Text(texto, style: Txt.r(tamano, color: context.paleta.texto)));
}

/// Selector desplegable de 40 px con borde gris y "Selecciona".
class SelectorCampo extends StatelessWidget {
  const SelectorCampo({super.key, required this.valor, required this.opciones, required this.onChanged, this.hint = 'Selecciona', this.alto = 40});

  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;
  final String hint;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SizedBox(
      height: alto,
      child: DropdownButtonFormField<String>(
        initialValue: opciones.contains(valor) ? valor : null,
        key: ValueKey('$hint-${opciones.join()}-$valor'),
        isExpanded: true,
        icon: Icon(TablerIcons.chevron_down, size: 20, color: p.texto),
        hint: Text(hint, style: Txt.r(12, color: p.placeholder)),
        style: Txt.n(13, color: p.texto),
        dropdownColor: p.tarjeta,
        borderRadius: BorderRadius.circular(14),
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
        items: [for (final o in opciones) DropdownMenuItem(value: o, child: Text(o))],
        onChanged: opciones.isEmpty ? null : onChanged,
      ),
    );
  }
}

/// Campo que abre los selectores de fecha y hora.
class CampoFechaHora extends StatelessWidget {
  const CampoFechaHora({super.key, required this.fecha, required this.onChanged, this.alto = 40});

  final DateTime fecha;
  final ValueChanged<DateTime> onChanged;
  final double alto;

  Future<void> _elegir(BuildContext context) async {
    final ahora = DateTime.now();
    final dia = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: ahora.subtract(const Duration(days: 30)),
      lastDate: ahora,
      helpText: 'Fecha del hurto',
    );
    if (dia == null || !context.mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(fecha), helpText: 'Hora del hurto');
    if (hora == null) return;
    var nueva = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
    if (nueva.isAfter(ahora)) nueva = ahora;
    onChanged(nueva);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Material(
      color: p.inputFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.inputBorde)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _elegir(context),
        child: SizedBox(
          height: alto,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(child: Text(fechaCorta(fecha), style: Txt.r(12, color: p.texto))),
              Icon(TablerIcons.calendar, size: 20, color: p.texto),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Hoy · 6:15 p. m." / "13 oct. · 6:15 p. m."
String fechaCorta(DateTime f, {bool conAnio = false}) {
  const meses = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sept.', 'oct.', 'nov.', 'dic.'];
  final ahora = DateTime.now();
  final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final hora = '$h:${f.minute.toString().padLeft(2, '0')} ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
  final hoy = f.year == ahora.year && f.month == ahora.month && f.day == ahora.day;
  final dia = hoy && !conAnio ? 'Hoy' : '${f.day} ${meses[f.month - 1]}${conAnio ? ' ${f.year}' : ''}';
  return '$dia · $hora';
}

/// Mapa pequeño para elegir la ubicación del incidente (tocar mueve el pin).
class MapaSelector extends StatelessWidget {
  const MapaSelector({super.key, required this.punto, required this.etiqueta, required this.onPunto, this.controller, this.onMiUbicacion, this.alto = 230});

  final LatLng punto;
  final String etiqueta;
  final ValueChanged<LatLng> onPunto;
  final MapController? controller;
  final VoidCallback? onMiUbicacion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.borde)),
        child: SizedBox(
          height: alto,
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: controller,
                  options: MapOptions(
                    initialCenter: punto,
                    initialZoom: 15,
                    onTap: (_, latlng) => onPunto(latlng),
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    MapaBase.capaTiles(context),
                    MarkerLayer(
                      markers: [
                        Marker(point: punto, width: 120, height: 92, alignment: const Alignment(0, -0.25), child: PinConEtiqueta(etiqueta: etiqueta)),
                      ],
                    ),
                  ],
                ),
              ),
              if (onMiUbicacion != null)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Material(
                    color: p.tarjeta,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(tooltip: 'Mi ubicación', onPressed: onMiUbicacion, icon: Icon(TablerIcons.current_location, color: p.texto)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pin rojo grande (48×62) con una etiqueta blanca debajo ("Chapinero").
class PinConEtiqueta extends StatelessWidget {
  const PinConEtiqueta({super.key, required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PinHurto(ancho: 46),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: p.tarjeta,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Text(etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.nb(13, color: p.texto)),
        ),
      ],
    );
  }
}

/// Fotos opcionales: botón "+" punteado y hasta 3 miniaturas.
class SelectorFotos extends StatelessWidget {
  const SelectorFotos({super.key, required this.fotos, required this.onChanged, this.tamano = 72});

  final List<String> fotos;
  final ValueChanged<List<String>> onChanged;
  final double tamano;

  Future<void> _agregar(BuildContext context) async {
    if (fotos.length >= 3) return;
    final archivo = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (archivo != null) onChanged([...fotos, archivo.name]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final gris = context.esOscuro ? p.chip : const Color(0xFFD9D9D9);
    return Row(
      children: [
        CustomPaint(
          painter: BordePunteado(color: p.inputBorde),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: fotos.length >= 3 ? null : () => _agregar(context),
            child: SizedBox.square(dimension: tamano, child: Icon(TablerIcons.plus, size: 26, color: p.textoSecundario)),
          ),
        ),
        for (var i = 0; i < 2 || i < fotos.length; i++) ...[
          const SizedBox(width: 12),
          Container(
            width: tamano,
            height: tamano,
            decoration: BoxDecoration(
              color: i < fotos.length ? p.suaveVerde : gris,
              borderRadius: BorderRadius.circular(14),
            ),
            child: i < fotos.length
                ? Stack(
                    children: [
                      const Center(child: Icon(TablerIcons.photo_check, size: 26, color: AppColors.verdeExito)),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          tooltip: 'Quitar foto',
                          iconSize: 16,
                          onPressed: () => onChanged([...fotos]..removeAt(i)),
                          icon: Icon(TablerIcons.x, color: p.texto),
                        ),
                      ),
                    ],
                  )
                : Icon(TablerIcons.photo, size: 24, color: p.textoSecundario),
          ),
        ],
      ],
    );
  }
}
