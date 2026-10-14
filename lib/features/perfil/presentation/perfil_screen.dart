import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/menu_lateral.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../alertas/data/alertas_repository.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../../reporte/data/reporte_repository.dart';
import '../../reporte/domain/reporte.dart';
import '../data/perfil_repository.dart';

/// Mi perfil. Celular: tarjeta de usuario, estadísticas y menú. Tablet/PC: columna de usuario + accesos + vehículos.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).usuario;
    if (usuario == null) return const SizedBox.shrink();
    return context.esCelular ? _PerfilCelular(usuario: usuario) : _PerfilAncho(usuario: usuario);
  }
}

/// Opciones del perfil: (ícono, título, subtítulo PC, ruta). Las de vehículos/zonas/reportes son solo de ciudadano.
List<(IconData, String, String, String)> _opciones(WidgetRef ref, Rol rol) {
  final reportes = ref.watch(misReportesProvider).value ?? const <Reporte>[];
  final atencion = reportes.where((r) => r.estado == EstadoReporte.enAtencion).length;
  final vehiculos = ref.watch(vehiculosProvider);
  final zonas = ref.watch(zonasFavoritasProvider);
  final radio = ref.watch(configAlertasProvider).radioKm.round();
  final anonimo = ref.watch(privacidadProvider).anonimo;
  final ciudadano = rol == Rol.ciudadano;
  return [
    if (ciudadano) (TablerIcons.file_text, 'Mis reportes', '${reportes.length} reportes · $atencion en atención', '/mis-reportes'),
    if (ciudadano) (TablerIcons.car, 'Vehículos registrados', '${vehiculos.length} vehículos', '/perfil/vehiculos'),
    if (ciudadano) (TablerIcons.heart, 'Zonas favoritas', zonas.map((z) => z.nombre).join(', '), '/perfil/zonas'),
    (TablerIcons.bell, 'Configuración de alertas', 'Radio de $radio km', '/alertas/configurar'),
    (TablerIcons.lock, 'Privacidad y datos', anonimo ? 'Reporte anónimo activo' : 'Reporte con nombre', '/perfil/privacidad'),
    (TablerIcons.help_circle, 'Centro de ayuda', 'Línea 123 y chat', '/perfil/ayuda'),
  ];
}

class _Estadisticas extends ConsumerWidget {
  const _Estadisticas({this.ancho = false});

  final bool ancho;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final e = ref.watch(estadisticasPerfilProvider);
    Widget celda(String valor, String etiqueta) {
      final contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor, style: Txt.r(ancho ? 22 : 26, color: p.texto)),
          const SizedBox(height: 4),
          Text(etiqueta, style: Txt.n(12, color: p.textoSecundario)),
        ],
      );
      return Expanded(
        child: ancho
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
                child: contenido,
              )
            : Tarjeta(padding: const EdgeInsets.symmetric(vertical: 16), child: Center(child: contenido)),
      );
    }

    return Row(
      children: [
        celda('${e.reportes}', 'Reportes'),
        SizedBox(width: ancho ? 8 : 14),
        celda('${e.alertasUtiles}', ancho ? 'Alertas útiles' : 'Alertas Útiles'),
        SizedBox(width: ancho ? 8 : 14),
        celda('${e.mesesActivo}', 'Meses activo'),
      ],
    );
  }
}

class _AvatarPerfil extends StatelessWidget {
  const _AvatarPerfil({required this.usuario, this.tamano = 52});

  final Usuario usuario;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: usuario.rol.color, shape: BoxShape.circle),
      child: Icon(TablerIcons.user, size: tamano * 0.5, color: usuario.rol.sobreColor),
    );
  }
}

Widget _pildoraRol(BuildContext context, Rol rol) {
  final p = context.paleta;
  final (fondo, texto) = switch (rol) {
    Rol.ciudadano => (p.suaveAmarillo, p.textoMedio),
    Rol.dev => (p.suaveMorado, context.esOscuro ? const Color(0xFF9F98F0) : AppColors.moradoDev),
    Rol.autoridad => (p.suaveAzul, context.esOscuro ? const Color(0xFF6FA8E0) : AppColors.azulAutoridad),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(10)),
    child: Text(rol.etiqueta, style: Txt.nb(11, color: texto)),
  );
}

String _descripcionRol(Rol rol) => switch (rol) {
      Rol.ciudadano => 'Ciudadano · Conductor',
      Rol.dev => 'DEV · Administrador',
      Rol.autoridad => 'Autoridad · Policía',
    };

class _PerfilCelular extends ConsumerWidget {
  const _PerfilCelular({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final opciones = _opciones(ref, usuario.rol);
    final inferior = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      drawer: usuario.rol == Rol.ciudadano ? const MenuLateral(rutaActiva: '/perfil') : null,
      appBar: AppBar(
        toolbarHeight: 72,
        leading: usuario.rol == Rol.ciudadano
            ? Builder(
                builder: (context) => IconButton(tooltip: 'Menú', onPressed: () => Scaffold.of(context).openDrawer(), icon: Icon(TablerIcons.menu_2, size: 28, color: p.texto)),
              )
            : null,
        title: Text('Mi Perfil', style: Txt.r(24, color: p.texto)),
        actions: [
          IconButton(tooltip: 'Ajustes', onPressed: () => context.push('/perfil/ajustes'), icon: Icon(TablerIcons.settings, size: 30, color: p.texto)),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(19, 4, 19, inferior + 24),
        children: [
          Tarjeta(
            onTap: () => context.push('/perfil/editar'),
            child: Row(
              children: [
                _AvatarPerfil(usuario: usuario),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.primerNombre, style: Txt.nb(18, color: p.texto)),
                      Text(_descripcionRol(usuario.rol), style: Txt.n(14, color: p.textoSecundario)),
                    ],
                  ),
                ),
                Align(alignment: Alignment.topRight, child: _pildoraRol(context, usuario.rol)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Estadisticas(),
          const SizedBox(height: 14),
          Tarjeta(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, (icono, titulo, _, ruta)) in opciones.indexed)
                  FilaOpcion(
                    icono: icono,
                    texto: titulo,
                    fondoIcono: p.suaveAmarillo,
                    divisor: i < opciones.length - 1,
                    onTap: () => context.push(ruta),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfilAncho extends ConsumerWidget {
  const _PerfilAncho({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final opciones = _opciones(ref, usuario.rol);
    final vehiculos = ref.watch(vehiculosProvider);
    final esPc = context.pantalla == TipoPantalla.escritorio;
    final columnaUsuario = Tarjeta(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          _AvatarPerfil(usuario: usuario, tamano: 96),
          const SizedBox(height: 14),
          Text(usuario.primerNombre, style: Txt.r(22, color: p.texto)),
          Text(_descripcionRol(usuario.rol), style: Txt.n(14, color: p.textoSecundario)),
          const SizedBox(height: 6),
          _pildoraRol(context, usuario.rol),
          const SizedBox(height: 18),
          const _Estadisticas(ancho: true),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: BotonContorno(texto: 'Editar perfil', icono: TablerIcons.pencil, alto: 48, tamanoTexto: 16, onPressed: () => context.push('/perfil/editar'))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: BotonContorno(texto: 'Ajustes', icono: TablerIcons.settings, alto: 48, tamanoTexto: 16, onPressed: () => context.push('/perfil/ajustes'))),
        ],
      ),
    );

    Widget acceso((IconData, String, String, String) o) {
      final (icono, titulo, sub, ruta) = o;
      return Tarjeta(
        onTap: () => context.push(ruta),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          children: [
            IconoCirculo(icono: icono, fondo: p.suaveAmarillo, color: context.esOscuro ? AppColors.amarillo : const Color(0xFFB88600), tamano: 46, tamanoIcono: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Txt.nb(15, color: p.texto)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.n(12, color: p.textoSecundario)),
                ],
              ),
            ),
            Icon(TablerIcons.chevron_right, color: p.textoSecundario),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: paddingEscritorio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoEscritorio(titulo: 'Mi perfil', subtitulo: 'Tu cuenta, vehículos y preferencias'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: esPc ? 340 : 290, child: columnaUsuario),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, c) {
                        final columnas = c.maxWidth > 640 ? 2 : 1;
                        final w = (c.maxWidth - 16 * (columnas - 1)) / columnas;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          children: [for (final o in opciones) SizedBox(width: w, child: acceso(o))],
                        );
                      },
                    ),
                    if (usuario.rol == Rol.ciudadano) ...[
                      const SizedBox(height: 28),
                      Tarjeta(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('Mis vehículos', style: Txt.nb(17, color: p.texto))),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), textStyle: Txt.nb(13)),
                                  onPressed: () => context.push('/perfil/vehiculos/agregar'),
                                  icon: const Icon(TablerIcons.plus, size: 18),
                                  label: const Text('Agregar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            for (final v in vehiculos)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    IconoCirculo(
                                      icono: v.tipo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car,
                                      fondo: v.tipo == TipoVehiculo.moto ? AppColors.amarillo : AppColors.rojo,
                                      color: v.tipo == TipoVehiculo.moto ? Colors.black : Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${v.nombreTipo} · ${v.marca == 'Chevrolet' ? 'Chevrolet ' : ''}${v.modelo}', style: Txt.nb(14, color: p.texto)),
                                          Text('Placa ${v.placa} · ${v.color}', style: Txt.n(12, color: p.textoSecundario)),
                                        ],
                                      ),
                                    ),
                                    pildoraVehiculo(context, v.estado),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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

/// Píldora del estado de un vehículo (Protegida verde, Recuperado crema, Reportado rosado).
Widget pildoraVehiculo(BuildContext context, EstadoVehiculo e) {
  final p = context.paleta;
  final (fondo, color) = switch (e) {
    EstadoVehiculo.protegida => (p.suaveVerde, AppColors.verdeExito),
    EstadoVehiculo.recuperado => (p.suaveAmarillo, p.textoMedio),
    EstadoVehiculo.reportado => (p.suaveRojo, p.textoAlto),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
    child: Text(e.etiqueta, style: Txt.nb(11, color: color)),
  );
}
