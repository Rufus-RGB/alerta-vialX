import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../auth/domain/usuario.dart';
import '../data/dev_repository.dart';

/// Color morado de DEV ajustado al tema.
Color moradoTema(BuildContext context) => context.esOscuro ? const Color(0xFF9F98F0) : AppColors.moradoDev;

/// Píldora del rol (Ciudadano gris, Autoridad azul, DEV morado).
Widget pildoraRolAdmin(BuildContext context, Rol rol) {
  final p = context.paleta;
  return switch (rol) {
    Rol.ciudadano => Pildora('Ciudadano', fondo: p.chip, color: p.textoSecundario),
    Rol.autoridad => Pildora('Autoridad', fondo: p.suaveAzul, color: context.esOscuro ? const Color(0xFF6FA8E0) : AppColors.azulAutoridad),
    Rol.dev => Pildora('DEV', fondo: p.suaveMorado, color: moradoTema(context)),
  };
}

/// Píldora del estado de una cuenta (Activo, Pendiente, Bloqueado).
Widget pildoraCuenta(BuildContext context, EstadoCuenta e) {
  final p = context.paleta;
  return switch (e) {
    EstadoCuenta.activo => Pildora('Activo', fondo: p.suaveVerde, color: AppColors.verdeExito),
    EstadoCuenta.pendiente => Pildora('Pendiente', fondo: p.suaveAmarillo, color: p.textoMedio),
    EstadoCuenta.bloqueado => Pildora('Bloqueado', fondo: p.suaveRojo, color: p.textoAlto),
  };
}

/// Píldora de evidencia de un reporte en moderación.
Widget pildoraEvidencia(BuildContext context, Evidencia e) {
  final p = context.paleta;
  return switch (e) {
    Evidencia.conFotos => Pildora(e.etiqueta, fondo: p.suaveVerde, color: AppColors.verdeExito),
    Evidencia.posibleFalso => Pildora(e.etiqueta, fondo: p.suaveRojo, color: p.textoAlto),
    Evidencia.sinFotos => Pildora(e.etiqueta, fondo: p.suaveAmarillo, color: p.textoMedio),
  };
}

/// Píldora de estado de revisión (Pendiente, Aprobado, Rechazado).
Widget pildoraRevision(BuildContext context, EstadoRevision e) {
  final p = context.paleta;
  return switch (e) {
    EstadoRevision.pendiente => Pildora('Pendiente', fondo: p.suaveAmarillo, color: p.textoMedio),
    EstadoRevision.aprobado => Pildora('Aprobado', fondo: p.suaveVerde, color: AppColors.verdeExito),
    EstadoRevision.rechazado => Pildora('Rechazado', fondo: p.suaveRojo, color: p.textoAlto),
  };
}

/// Recuadro gris con ícono y texto (detalle de una solicitud o evidencia).
class RecuadroNota extends StatelessWidget {
  const RecuadroNota({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icono, size: 20, color: p.textoSecundario),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: Txt.n(13, color: p.textoSecundario))),
        ],
      ),
    );
  }
}

void avisar(BuildContext context, String texto, {bool exito = true}) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: exito ? AppColors.verdeExito : null),
    );
