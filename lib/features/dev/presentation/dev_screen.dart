import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/indicadores.dart';
import '../../../widgets/navegacion.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../data/dev_repository.dart';
import 'dev_comun.dart';

/// Panel DEV (administrador). Celular: tarjeta, estadísticas y herramientas. Tablet/PC: KPIs, gráficas y tablas.
class DevScreen extends ConsumerWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => context.esCelular ? const _PanelCelular() : const _PanelAncho();
}

class _PanelCelular extends ConsumerWidget {
  const _PanelCelular();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final usuario = ref.watch(authControllerProvider).usuario;
    final pendAut = ref.watch(solicitudesAutoridadProvider).where((s) => s.estado == EstadoRevision.pendiente).length;
    final pendMod = ref.watch(moderacionProvider).where((s) => s.estado == EstadoRevision.pendiente).length;
    final herramientas = destinosLaterales(Rol.dev).skip(1).toList();
    final inferior = MediaQuery.paddingOf(context).bottom;
    final morado = moradoTema(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(tooltip: 'Herramientas', onPressed: () => context.push('/dev/sistema'), icon: Icon(TablerIcons.menu_2, size: 28, color: p.texto)),
        title: Text('Panel DEV', style: Txt.r(24, color: p.texto)),
        actions: [
          IconButton(tooltip: 'Configuración del sistema', onPressed: () => context.push('/dev/sistema'), icon: Icon(TablerIcons.settings, size: 26, color: p.texto)),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(19, 4, 19, inferior + 24),
        children: [
          Tarjeta(
            onTap: () => context.go('/perfil'),
            child: Row(
              children: [
                const IconoCirculo(icono: TablerIcons.code, fondo: AppColors.moradoDev, tamano: 56, tamanoIcono: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario?.nombre ?? 'Dev User', style: Txt.nb(18, color: p.texto)),
                      Text('Desarrollador · Acceso total', style: Txt.n(14, color: p.textoSecundario)),
                    ],
                  ),
                ),
                Pildora('DEV', fondo: p.suaveMorado, color: morado),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, (v, e)) in const [('248', 'Reportes'), ('32', 'Usuarios'), ('15.2K', 'Eventos')].indexed) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: Tarjeta(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(children: [Text(v, style: Txt.r(26, color: p.texto)), const SizedBox(height: 4), Text(e, style: Txt.n(12, color: p.textoSecundario))]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Tarjeta(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, d) in herramientas.indexed)
                  FilaLista(
                    titulo: d.etiqueta == 'Autoridades'
                        ? 'Aprobar autoridades'
                        : d.etiqueta == 'Usuarios'
                            ? 'Gestión de usuarios'
                            : d.etiqueta == 'Moderación'
                                ? 'Moderación de reportes'
                                : d.etiqueta == 'Sistema'
                                    ? 'Configuración del sistema'
                                    : d.etiqueta,
                    divisor: i < herramientas.length - 1,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    onTap: () => context.push(d.ruta),
                    leading: IconoCirculo(icono: d.icono, fondo: p.suaveMorado, color: morado, tamano: 36, tamanoIcono: 20),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((d.ruta == '/dev/autoridades' && pendAut > 0) || (d.ruta == '/dev/moderacion' && pendMod > 0))
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(color: AppColors.rojo, shape: BoxShape.circle),
                            child: Text('${d.ruta == '/dev/autoridades' ? pendAut : pendMod}', style: Txt.nb(12, color: Colors.white)),
                          ),
                        Icon(TablerIcons.chevron_right, color: p.textoSecundario),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAncho extends ConsumerWidget {
  const _PanelAncho();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final morado = moradoTema(context);
    final pendientes = ref.watch(moderacionProvider).where((r) => r.estado == EstadoRevision.pendiente).toList();
    final pendAut = ref.watch(solicitudesAutoridadProvider).where((s) => s.estado == EstadoRevision.pendiente).length;
    final usuarios = ref.watch(usuariosAdminProvider).where((u) => u.rol != Rol.dev).take(4).toList();
    final kpis = [
      TarjetaKpi(titulo: 'Reportes', valor: '248', nota: '+12 % esta semana', colorNota: AppColors.verdeExito, icono: TablerIcons.file_text, fondoIcono: p.suaveMorado, colorIcono: morado, grande: true),
      TarjetaKpi(titulo: 'Usuarios activos', valor: '1.2K', nota: '+8 %', colorNota: AppColors.verdeExito, icono: TablerIcons.users, fondoIcono: p.suaveMorado, colorIcono: morado, grande: true),
      TarjetaKpi(titulo: 'Por moderar', valor: '${pendientes.length}', nota: 'Requiere revisión', colorNota: p.textoAlto, icono: TablerIcons.flag, fondoIcono: p.suaveMorado, colorIcono: morado, grande: true),
      TarjetaKpi(titulo: 'Autoridades por aprobar', valor: '$pendAut', nota: 'Pendientes', colorNota: p.textoMedio, icono: TablerIcons.user_shield, fondoIcono: p.suaveMorado, colorIcono: morado, grande: true),
    ];
    final esPc = context.pantalla == TipoPantalla.escritorio;
    return SingleChildScrollView(
      padding: paddingEscritorio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoEscritorio(titulo: 'Panel DEV', subtitulo: 'Resumen del sistema · hoy'),
          Row(children: [for (final (i, k) in kpis.indexed) ...[if (i > 0) const SizedBox(width: 20), Expanded(child: k)]]),
          const SizedBox(height: 20),
          Flex(
            direction: esPc ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: esPc ? 620 : 0,
                child: Tarjeta(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Reportes por localidad', style: Txt.nb(16, color: p.texto))),
                          Pildora('Esta semana', fondo: p.suaveMorado, color: morado),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const BarrasPorCategoria(datos: reportesPorLocalidad),
                    ],
                  ),
                ),
              ),
              SizedBox(width: esPc ? 20 : 0, height: esPc ? 0 : 20),
              Flexible(
                flex: esPc ? 488 : 0,
                child: Tarjeta(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text('Moderación pendiente', style: Txt.nb(16, color: p.texto))),
                            Pildora('${pendientes.length}', fondo: p.suaveRojo, color: p.textoAlto),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (pendientes.isEmpty)
                        Padding(padding: const EdgeInsets.all(24), child: Text('Todo al día.', textAlign: TextAlign.center, style: Txt.n(14, color: p.textoSecundario))),
                      for (final r in pendientes.take(3)) _FilaModeracionCompacta(reporte: r),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Tarjeta(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Usuarios recientes', style: Txt.nb(17, color: p.texto))),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), textStyle: Txt.nb(14)),
                      onPressed: () => context.go('/dev/usuarios'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                TablaSimple(
                  columnas: const ['Usuario', 'Correo', 'Rol', 'Estado', ''],
                  flex: const [5, 6, 3, 3, 1],
                  filas: [
                    for (final u in usuarios)
                      [
                        Row(children: [AvatarIniciales(iniciales: u.iniciales, color: u.color, tamano: 36), const SizedBox(width: 10), Flexible(child: Text(u.nombre, style: Txt.nb(14, color: p.texto)))]),
                        Text(u.correo, overflow: TextOverflow.ellipsis, style: Txt.n(13, color: p.textoSecundario)),
                        Align(alignment: Alignment.centerLeft, child: pildoraRolAdmin(context, u.rol)),
                        Align(alignment: Alignment.centerLeft, child: pildoraCuenta(context, u.estado)),
                        Icon(TablerIcons.dots, color: p.textoSecundario),
                      ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaModeracionCompacta extends ConsumerWidget {
  const _FilaModeracionCompacta({required this.reporte});

  final ReporteModeracion reporte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final r = reporte;
    void decidir(EstadoRevision e) {
      ref.read(moderacionProvider.notifier).reemplazar((x) => x.id == r.id, (x) => x.copyWith(e));
      avisar(context, e == EstadoRevision.aprobado ? '${r.placa}: reporte aprobado y publicado.' : '${r.placa}: reporte rechazado.', exito: e == EstadoRevision.aprobado);
    }

    final moto = r.vehiculo == TipoVehiculo.moto;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoCirculo(icono: moto ? TablerIcons.motorbike : TablerIcons.car, fondo: moto ? AppColors.amarillo : AppColors.rojo, color: moto ? Colors.black : Colors.white, tamano: 36, tamanoIcono: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.titulo} · ${r.placa}', overflow: TextOverflow.ellipsis, style: Txt.nb(13, color: p.texto)),
                const SizedBox(height: 6),
                pildoraEvidencia(context, r.evidencia),
              ],
            ),
          ),
          BotonesAprobacion(compactos: true, alto: 32, onAprobar: () => decidir(EstadoRevision.aprobado), onRechazar: () => decidir(EstadoRevision.rechazado)),
        ],
      ),
    );
  }
}
