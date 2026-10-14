import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/tarjeta.dart';
import '../data/notificaciones_repository.dart';

/// Notificaciones agrupadas por "Hoy" y "Esta semana".
class NotificacionesScreen extends ConsumerWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notis = ref.watch(notificacionesProvider);
    final inferior = MediaQuery.paddingOf(context).bottom;
    final lista = notis.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (todas) {
        final grupos = <String, List<Notificacion>>{};
        for (final n in todas) {
          grupos.putIfAbsent(n.grupo, () => []).add(n);
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(context.esCelular ? 19 : 0, 0, context.esCelular ? 19 : 0, inferior + 24),
          children: [
            for (final g in grupos.entries) ...[
              TituloSeccion(g.key, padding: const EdgeInsets.fromLTRB(10, 12, 4, 8)),
              Tarjeta(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [for (final n in g.value) _FilaNotificacion(n: n, ultima: n == g.value.last)],
                ),
              ),
            ],
          ],
        );
      },
    );
    if (!context.esCelular) {
      return Padding(
        padding: paddingEscritorio,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EncabezadoEscritorio(titulo: 'Notificaciones', subtitulo: 'Lo último cerca de ti'),
            Expanded(child: Align(alignment: Alignment.topLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: lista))),
          ],
        ),
      );
    }
    return Scaffold(appBar: const EncabezadoPantalla(titulo: 'Notificaciones'), body: lista);
  }
}

class _FilaNotificacion extends StatelessWidget {
  const _FilaNotificacion({required this.n, required this.ultima});

  final Notificacion n;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return FilaLista(
      titulo: n.titulo,
      subtitulo: n.detalle,
      estiloTitulo: Txt.nb(14, color: p.texto),
      divisor: !ultima,
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      onTap: n.ruta == null ? null : () => context.go(n.ruta!),
      leading: IconoCirculo(
        icono: n.icono,
        fondo: n.color,
        color: n.color == AppColors.amarillo ? Colors.black : Colors.white,
        tamanoIcono: 22,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(n.cuando, style: Txt.n(12, color: p.textoSecundario)),
          const SizedBox(height: 14),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: n.leida ? Colors.transparent : AppColors.amarillo, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
