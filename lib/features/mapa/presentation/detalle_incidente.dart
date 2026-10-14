import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/tarjeta.dart';
import '../domain/modelos_mapa.dart';

/// Contenido del "Detalle de reporte (Mapa)": encabezado, datos y acciones.
class DetalleIncidente extends StatelessWidget {
  const DetalleIncidente({super.key, required this.incidente});

  final IncidenteHurto incidente;

  Future<void> _tengoInformacion(BuildContext context) async {
    final texto = TextEditingController();
    final enviado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tengo información', style: Txt.r(20, color: ctx.paleta.texto)),
        content: TextField(
          controller: texto,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '¿Qué viste? Dirección, hora, descripción…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    texto.dispose();
    if (enviado == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias. Enviamos tu información a la autoridad.'), backgroundColor: AppColors.verdeExito),
      );
    }
  }

  void _compartir(BuildContext context) {
    final i = incidente;
    Clipboard.setData(ClipboardData(text: '${i.titulo} · ${i.placa} — ${i.direccion}, ${i.barrio} (${haceTiempo(i.fecha)}). Alerta Vial'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte copiado para compartir.')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final i = incidente;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconoCirculo(
              icono: i.vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car,
              fondo: AppColors.rojo,
              tamano: 56,
              tamanoIcono: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.titulo, style: Txt.r(20, color: p.texto)),
                    const SizedBox(height: 2),
                    Text('${i.barrio} · ${haceTiempo(i.fecha, mayuscula: true)}', style: Txt.n(13, color: p.textoSecundario)),
                  ],
                ),
              ),
            ),
            EtiquetaRiesgo(i.nivel, corta: true),
          ],
        ),
        const SizedBox(height: 16),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              FilaLista(
                titulo: i.descripcionVehiculo,
                subtitulo: 'Vehículo',
                subtituloArriba: true,
                leading: Icon(i.vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car, size: 22, color: p.texto),
              ),
              FilaLista(titulo: i.placa, subtitulo: 'Placa', subtituloArriba: true, leading: Icon(TablerIcons.id, size: 22, color: p.texto)),
              FilaLista(
                titulo: i.direccion,
                subtitulo: 'Ubicación',
                subtituloArriba: true,
                divisor: false,
                leading: Icon(TablerIcons.map_pin, size: 22, color: p.texto),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 236,
              child: BotonPrincipal(
                texto: 'Tengo información',
                icono: TablerIcons.info_circle,
                color: AppColors.amarillo,
                tamanoTexto: 17,
                onPressed: () => _tengoInformacion(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 144, child: BotonContorno(texto: 'Compartir', icono: TablerIcons.share, onPressed: () => _compartir(context))),
          ],
        ),
      ],
    );
  }
}

/// Muestra el detalle: hoja inferior en celular, diálogo en tablet/PC.
Future<void> mostrarDetalleIncidente(BuildContext context, IncidenteHurto incidente, {required bool hoja}) {
  if (hoja) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: DetalleIncidente(incidente: incidente),
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(padding: const EdgeInsets.all(24), child: DetalleIncidente(incidente: incidente)),
      ),
    ),
  );
}
