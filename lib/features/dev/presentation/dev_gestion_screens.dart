import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/indicadores.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/domain/usuario.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../data/dev_repository.dart';
import 'dev_comun.dart';

// ---------------- Gestión de usuarios ----------------

enum _FiltroUsuarios {
  todos('Todos'),
  ciudadanos('Ciudadanos'),
  autoridades('Autoridades'),
  bloqueados('Bloqueados');

  const _FiltroUsuarios(this.etiqueta);
  final String etiqueta;

  bool incluye(UsuarioAdmin u) => switch (this) {
        _FiltroUsuarios.todos => true,
        _FiltroUsuarios.ciudadanos => u.rol == Rol.ciudadano,
        _FiltroUsuarios.autoridades => u.rol == Rol.autoridad,
        _FiltroUsuarios.bloqueados => u.estado == EstadoCuenta.bloqueado,
      };
}

class UsuariosAdminScreen extends ConsumerStatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  ConsumerState<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends ConsumerState<UsuariosAdminScreen> {
  _FiltroUsuarios _filtro = _FiltroUsuarios.todos;
  String _q = '';

  void _accion(UsuarioAdmin u, String accion) {
    final ctrl = ref.read(usuariosAdminProvider.notifier);
    switch (accion) {
      case 'bloquear':
        ctrl.reemplazar((x) => x.correo == u.correo, (x) => x.copyWith(estado: EstadoCuenta.bloqueado));
        avisar(context, '${u.nombre} fue bloqueado.', exito: false);
      case 'activar':
        ctrl.reemplazar((x) => x.correo == u.correo, (x) => x.copyWith(estado: EstadoCuenta.activo));
        avisar(context, '${u.nombre} está activo.');
      case 'autoridad':
        ctrl.reemplazar((x) => x.correo == u.correo, (x) => x.copyWith(rol: Rol.autoridad));
        avisar(context, '${u.nombre} ahora es autoridad.');
      case 'ciudadano':
        ctrl.reemplazar((x) => x.correo == u.correo, (x) => x.copyWith(rol: Rol.ciudadano));
        avisar(context, '${u.nombre} ahora es ciudadano.');
    }
  }

  Widget _menu(UsuarioAdmin u) => PopupMenuButton<String>(
        tooltip: 'Acciones',
        icon: Icon(TablerIcons.dots, color: context.paleta.textoSecundario),
        onSelected: (a) => _accion(u, a),
        itemBuilder: (_) => [
          if (u.estado != EstadoCuenta.bloqueado) const PopupMenuItem(value: 'bloquear', child: Text('Bloquear')),
          if (u.estado != EstadoCuenta.activo) const PopupMenuItem(value: 'activar', child: Text('Activar')),
          if (u.rol == Rol.ciudadano) const PopupMenuItem(value: 'autoridad', child: Text('Cambiar a autoridad')),
          if (u.rol == Rol.autoridad) const PopupMenuItem(value: 'ciudadano', child: Text('Cambiar a ciudadano')),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final q = _q.toLowerCase();
    final lista = ref.watch(usuariosAdminProvider).where((u) => _filtro.incluye(u) && (q.isEmpty || '${u.nombre} ${u.correo}'.toLowerCase().contains(q))).toList();
    final ancho = !context.esCelular;
    return PantallaSecundaria(
      titulo: 'Gestión de usuarios',
      subtitulo: '${ref.watch(usuariosAdminProvider).length} usuarios registrados',
      anchoMaximo: 1100,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            style: Txt.n(14, color: p.texto),
            decoration: const InputDecoration(hintText: 'Buscar por nombre o correo', prefixIcon: Icon(TablerIcons.search, size: 20)),
          ),
        ),
        const SizedBox(height: 14),
        GrupoChips<_FiltroUsuarios>(opciones: _FiltroUsuarios.values, seleccionado: _filtro, etiqueta: (f) => f.etiqueta, alto: 36, onChanged: (f) => setState(() => _filtro = f)),
        const SizedBox(height: 14),
        Tarjeta(
          padding: ancho ? const EdgeInsets.fromLTRB(20, 8, 20, 8) : EdgeInsets.zero,
          child: lista.isEmpty
              ? Padding(padding: const EdgeInsets.all(30), child: Text('Sin resultados.', textAlign: TextAlign.center, style: Txt.n(14, color: p.textoSecundario)))
              : ancho
                  ? TablaSimple(
                      columnas: const ['Usuario', 'Correo', 'Rol', 'Estado', ''],
                      flex: const [5, 6, 3, 3, 1],
                      filas: [
                        for (final u in lista)
                          [
                            Row(children: [AvatarIniciales(iniciales: u.iniciales, color: u.color, tamano: 36), const SizedBox(width: 10), Flexible(child: Text(u.nombre, style: Txt.nb(14, color: p.texto)))]),
                            Text(u.correo, overflow: TextOverflow.ellipsis, style: Txt.n(13, color: p.textoSecundario)),
                            Align(alignment: Alignment.centerLeft, child: pildoraRolAdmin(context, u.rol)),
                            Align(alignment: Alignment.centerLeft, child: pildoraCuenta(context, u.estado)),
                            _menu(u),
                          ],
                      ],
                    )
                  : Column(
                      children: [
                        for (final (i, u) in lista.indexed)
                          FilaLista(
                            titulo: u.nombre,
                            subtitulo: u.correo,
                            divisor: i < lista.length - 1,
                            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                            leading: AvatarIniciales(iniciales: u.iniciales, color: u.color),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                u.estado == EstadoCuenta.activo ? pildoraRolAdmin(context, u.rol) : pildoraCuenta(context, u.estado),
                                _menu(u),
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

// ---------------- Aprobar autoridades / Moderación ----------------

/// Chips "Pendientes (n) / Aprobados / Rechazados".
class _FiltroRevision extends StatelessWidget {
  const _FiltroRevision({required this.valor, required this.pendientes, required this.onChanged, this.femenino = false});

  final EstadoRevision valor;
  final int pendientes;
  final ValueChanged<EstadoRevision> onChanged;
  final bool femenino;

  @override
  Widget build(BuildContext context) => GrupoChips<EstadoRevision>(
        opciones: EstadoRevision.values,
        seleccionado: valor,
        alto: 36,
        etiqueta: (e) => switch (e) {
          EstadoRevision.pendiente => 'Pendientes ($pendientes)',
          EstadoRevision.aprobado => femenino ? 'Aprobadas' : 'Aprobados',
          EstadoRevision.rechazado => femenino ? 'Rechazadas' : 'Rechazados',
        },
        onChanged: onChanged,
      );
}

class AutoridadesAdminScreen extends ConsumerStatefulWidget {
  const AutoridadesAdminScreen({super.key});

  @override
  ConsumerState<AutoridadesAdminScreen> createState() => _AutoridadesAdminScreenState();
}

class _AutoridadesAdminScreenState extends ConsumerState<AutoridadesAdminScreen> {
  EstadoRevision _filtro = EstadoRevision.pendiente;

  void _decidir(SolicitudAutoridad s, EstadoRevision e) {
    ref.read(solicitudesAutoridadProvider.notifier).reemplazar((x) => x.correo == s.correo, (x) => x.copyWith(e));
    ref.read(usuariosAdminProvider.notifier).reemplazar(
          (u) => u.correo == s.correo,
          (u) => u.copyWith(estado: e == EstadoRevision.aprobado ? EstadoCuenta.activo : EstadoCuenta.bloqueado),
        );
    avisar(context, e == EstadoRevision.aprobado ? '${s.nombre}: cuenta de autoridad aprobada.' : '${s.nombre}: solicitud rechazada.', exito: e == EstadoRevision.aprobado);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final todas = ref.watch(solicitudesAutoridadProvider);
    final lista = todas.where((s) => s.estado == _filtro).toList();
    final ancho = !context.esCelular;
    Widget tarjeta(SolicitudAutoridad s) => Tarjeta(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarIniciales(iniciales: s.iniciales, color: AppColors.azulAutoridad),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.nombre, style: Txt.nb(16, color: p.texto)),
                        Text(s.correo, style: Txt.n(13, color: p.textoSecundario)),
                      ],
                    ),
                  ),
                  pildoraRevision(context, s.estado),
                ],
              ),
              const SizedBox(height: 12),
              RecuadroNota(icono: TablerIcons.file_text, texto: s.detalle),
              if (s.estado == EstadoRevision.pendiente) ...[
                const SizedBox(height: 12),
                BotonesAprobacion(onAprobar: () => _decidir(s, EstadoRevision.aprobado), onRechazar: () => _decidir(s, EstadoRevision.rechazado)),
              ],
            ],
          ),
        );
    return PantallaSecundaria(
      titulo: 'Aprobar autoridades',
      subtitulo: 'Verifica cuentas de Policía, SIJIN y Tránsito',
      anchoMaximo: 1100,
      children: [
        _FiltroRevision(
          valor: _filtro,
          femenino: true,
          pendientes: todas.where((s) => s.estado == EstadoRevision.pendiente).length,
          onChanged: (e) => setState(() => _filtro = e),
        ),
        const SizedBox(height: 14),
        if (lista.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Text('No hay solicitudes aquí.', textAlign: TextAlign.center, style: Txt.n(14, color: p.textoSecundario))),
        if (ancho)
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 20) / 2;
              return Wrap(spacing: 20, runSpacing: 16, children: [for (final s in lista) SizedBox(width: w, child: tarjeta(s))]);
            },
          )
        else
          for (final s in lista) Padding(padding: const EdgeInsets.only(bottom: 14), child: tarjeta(s)),
      ],
    );
  }
}

class ModeracionScreen extends ConsumerStatefulWidget {
  const ModeracionScreen({super.key});

  @override
  ConsumerState<ModeracionScreen> createState() => _ModeracionScreenState();
}

class _ModeracionScreenState extends ConsumerState<ModeracionScreen> {
  EstadoRevision _filtro = EstadoRevision.pendiente;

  void _decidir(ReporteModeracion r, EstadoRevision e) {
    ref.read(moderacionProvider.notifier).reemplazar((x) => x.id == r.id, (x) => x.copyWith(e));
    avisar(context, e == EstadoRevision.aprobado ? '${r.placa}: reporte aprobado y publicado en el mapa.' : '${r.placa}: reporte rechazado.', exito: e == EstadoRevision.aprobado);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final todos = ref.watch(moderacionProvider);
    final lista = todos.where((r) => r.estado == _filtro).toList();
    final ancho = !context.esCelular;
    Widget tarjeta(ReporteModeracion r) {
      final moto = r.vehiculo == TipoVehiculo.moto;
      return Tarjeta(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconoCirculo(icono: moto ? TablerIcons.motorbike : TablerIcons.car, fondo: moto ? AppColors.amarillo : AppColors.rojo, color: moto ? Colors.black : Colors.white, tamano: 48, tamanoIcono: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.titulo} · ${r.placa}', style: Txt.nb(16, color: p.texto)),
                      Text('${r.autor} · ${r.barrio} · ${r.hora}', style: Txt.n(13, color: p.textoSecundario)),
                    ],
                  ),
                ),
                r.estado == EstadoRevision.pendiente ? pildoraEvidencia(context, r.evidencia) : pildoraRevision(context, r.estado),
              ],
            ),
            const SizedBox(height: 12),
            RecuadroNota(icono: TablerIcons.photo, texto: r.nota),
            if (r.estado == EstadoRevision.pendiente) ...[
              const SizedBox(height: 12),
              BotonesAprobacion(onAprobar: () => _decidir(r, EstadoRevision.aprobado), onRechazar: () => _decidir(r, EstadoRevision.rechazado)),
            ],
          ],
        ),
      );
    }

    return PantallaSecundaria(
      titulo: 'Moderación',
      subtitulo: 'Revisa reportes antes de publicarlos',
      anchoMaximo: 1100,
      children: [
        _FiltroRevision(valor: _filtro, pendientes: todos.where((r) => r.estado == EstadoRevision.pendiente).length, onChanged: (e) => setState(() => _filtro = e)),
        const SizedBox(height: 14),
        if (lista.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Text('No hay reportes aquí.', textAlign: TextAlign.center, style: Txt.n(14, color: p.textoSecundario))),
        if (ancho)
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 20) / 2;
              return Wrap(spacing: 20, runSpacing: 16, children: [for (final r in lista) SizedBox(width: w, child: tarjeta(r))]);
            },
          )
        else
          for (final r in lista) Padding(padding: const EdgeInsets.only(bottom: 14), child: tarjeta(r)),
      ],
    );
  }
}
