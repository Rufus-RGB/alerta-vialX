import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../../reporte/data/reporte_repository.dart';
import '../../reporte/domain/reporte.dart';

enum _FiltroReportes {
  todos('Todos'),
  atencion('En atención'),
  cerrados('Cerrados');

  const _FiltroReportes(this.etiqueta);
  final String etiqueta;

  bool incluye(EstadoReporte e) => switch (this) {
        _FiltroReportes.todos => true,
        _FiltroReportes.atencion => e != EstadoReporte.cerrado && e != EstadoReporte.recuperado,
        _FiltroReportes.cerrados => e == EstadoReporte.cerrado || e == EstadoReporte.recuperado,
      };
}

/// Mis reportes con filtros y estado vacío.
class MisReportesScreen extends ConsumerStatefulWidget {
  const MisReportesScreen({super.key});

  @override
  ConsumerState<MisReportesScreen> createState() => _MisReportesScreenState();
}

class _MisReportesScreenState extends ConsumerState<MisReportesScreen> {
  _FiltroReportes _filtro = _FiltroReportes.todos;

  static String _fecha(DateTime f) {
    const meses = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'];
    return '${f.day} ${meses[f.month - 1]} ${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final async = ref.watch(misReportesProvider);
    final todos = async.value ?? const <Reporte>[];
    final lista = todos.where((r) => _filtro.incluye(r.estado)).toList();

    if (async.hasValue && todos.isEmpty) {
      return PantallaSecundaria(
        titulo: 'Mis reportes',
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
              width: 170,
              height: 170,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.suaveAmarillo, shape: BoxShape.circle),
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(color: AppColors.amarillo, shape: BoxShape.circle),
                child: const Icon(TablerIcons.file_text, size: 48, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text('Aún no tienes reportes', textAlign: TextAlign.center, style: Txt.r(24, color: p.texto)),
          const SizedBox(height: 6),
          Text(
            'Cuando reportes un hurto, aquí verás su estado y seguimiento.',
            textAlign: TextAlign.center,
            style: Txt.n(15, color: p.textoSecundario),
          ),
          const SizedBox(height: 46),
          BotonPrincipal(texto: 'Reportar hurto', icono: TablerIcons.plus, onPressed: () => context.go('/reporte')),
        ],
      );
    }

    return PantallaSecundaria(
      titulo: 'Mis reportes',
      subtitulo: '${todos.length} reportes',
      children: [
        GrupoChips<_FiltroReportes>(
          opciones: _FiltroReportes.values,
          seleccionado: _filtro,
          etiqueta: (f) => f.etiqueta,
          alto: 36,
          onChanged: (f) => setState(() => _filtro = f),
        ),
        const SizedBox(height: 14),
        if (async.isLoading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        if (async.hasValue && lista.isEmpty)
          Padding(padding: const EdgeInsets.all(30), child: Text('No hay reportes con este filtro.', textAlign: TextAlign.center, style: Txt.n(14, color: p.textoSecundario))),
        for (final r in lista)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Tarjeta(
              onTap: () => context.push('/reporte/estado/${r.id}'),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Row(
                children: [
                  IconoCirculo(
                    icono: r.borrador.vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car,
                    fondo: r.borrador.vehiculo == TipoVehiculo.moto ? AppColors.amarillo : AppColors.rojo,
                    color: r.borrador.vehiculo == TipoVehiculo.moto ? Colors.black : Colors.white,
                    tamano: 48,
                    tamanoIcono: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_titulo(r)} · ${r.borrador.placa}', style: Txt.nb(16, color: p.texto)),
                        const SizedBox(height: 2),
                        Text('${r.borrador.barrio} · ${_fecha(r.borrador.fecha)}', style: Txt.n(13, color: p.textoSecundario)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(TablerIcons.chevron_right, size: 20, color: p.textoSecundario),
                      const SizedBox(height: 10),
                      pildoraEstado(context, r.estado),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _titulo(Reporte r) {
    if (r.id == 'AV-1874') return 'Intento de hurto';
    return r.borrador.vehiculo == TipoVehiculo.moto ? 'Hurto de moto' : 'Hurto de auto';
  }
}
