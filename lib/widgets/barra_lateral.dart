import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import '../features/auth/domain/usuario.dart';
import 'botones.dart';
import 'logo_alerta.dart';
import 'navegacion.dart';

/// Fondo e ícono del ítem activo según el rol (ciudadano amarillo, DEV morado, autoridad azul).
(Color fondo, Color icono) coloresActivoRol(Rol rol, Paleta p, bool oscuro) => switch (rol) {
      Rol.ciudadano => (p.suaveAmarillo, oscuro ? AppColors.amarillo : const Color(0xFFB88600)),
      Rol.dev => (p.suaveMorado, oscuro ? const Color(0xFF9F98F0) : AppColors.moradoDev),
      Rol.autoridad => (p.suaveAzul, oscuro ? const Color(0xFF6FA8E0) : AppColors.azulAutoridad),
    };

/// Barra lateral completa de PC/Web (248 px).
class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.usuario,
    required this.destinos,
    required this.indiceActivo,
    required this.onDestino,
    required this.onSos,
    required this.onPerfil,
  });

  final Usuario usuario;
  final List<DestinoNav> destinos;
  final int indiceActivo;
  final ValueChanged<DestinoNav> onDestino;
  final VoidCallback onSos;
  final VoidCallback onPerfil;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondoActivo, iconoActivo) = coloresActivoRol(usuario.rol, p, context.esOscuro);
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: context.esOscuro ? const Color(0xFF0E161B) : p.tarjeta,
        border: Border(right: BorderSide(color: p.borde)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(children: [const Isotipo(), const SizedBox(width: 10), Text('Alerta Vial', style: Txt.r(20, color: p.texto))]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < destinos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ItemLateral(
                          destino: destinos[i],
                          activo: i == indiceActivo,
                          fondoActivo: fondoActivo,
                          iconoActivo: iconoActivo,
                          onTap: () => onDestino(destinos[i]),
                        ),
                      ),
                  ],
                ),
              ),
              if (usuario.rol == Rol.ciudadano) ...[
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onSos,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.rojo,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: Txt.r(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/icons/siren.svg', width: 22, height: 22),
                        const SizedBox(width: 8),
                        const Text('SOS Emergencia'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              _PieUsuario(usuario: usuario, onTap: onPerfil),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemLateral extends StatelessWidget {
  const _ItemLateral({required this.destino, required this.activo, required this.fondoActivo, required this.iconoActivo, required this.onTap});

  final DestinoNav destino;
  final bool activo;
  final Color fondoActivo;
  final Color iconoActivo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      selected: activo,
      button: true,
      child: Material(
        color: activo ? fondoActivo : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(destino.icono, size: 20, color: activo ? iconoActivo : p.textoSecundario),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destino.etiqueta,
                    overflow: TextOverflow.ellipsis,
                    style: activo ? Txt.nb(14, color: p.texto) : Txt.n(14, color: p.textoSecundario),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PieUsuario extends StatelessWidget {
  const _PieUsuario({required this.usuario, required this.onTap});

  final Usuario usuario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            AvatarUsuario(usuario: usuario, tamano: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombre, overflow: TextOverflow.ellipsis, style: Txt.nb(14, color: p.texto)),
                  Text(usuario.rol.etiqueta, style: Txt.n(12, color: p.textoSecundario)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circular con la inicial, del color del rol.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({super.key, required this.usuario, this.tamano = 40});

  final Usuario usuario;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: usuario.rol.color, shape: BoxShape.circle),
      child: Text(usuario.inicial, style: Txt.r(tamano * 0.42, color: usuario.rol.sobreColor)),
    );
  }
}

/// Riel lateral de íconos para tablet (88 px).
class RielLateral extends StatelessWidget {
  const RielLateral({
    super.key,
    required this.usuario,
    required this.destinos,
    required this.indiceActivo,
    required this.onDestino,
    required this.onSos,
    required this.onPerfil,
  });

  final Usuario usuario;
  final List<DestinoNav> destinos;
  final int indiceActivo;
  final ValueChanged<DestinoNav> onDestino;
  final VoidCallback onSos;
  final VoidCallback onPerfil;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondoActivo, iconoActivo) = coloresActivoRol(usuario.rol, p, context.esOscuro);
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: context.esOscuro ? const Color(0xFF0E161B) : p.tarjeta,
        border: Border(right: BorderSide(color: p.borde)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 22),
            const Isotipo(),
            const SizedBox(height: 26),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (var i = 0; i < destinos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        selected: i == indiceActivo,
                        button: true,
                        label: destinos[i].etiqueta,
                        child: Material(
                          color: i == indiceActivo ? fondoActivo : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onDestino(destinos[i]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: [
                                  Icon(destinos[i].icono, size: 24, color: i == indiceActivo ? iconoActivo : p.textoSecundario),
                                  const SizedBox(height: 4),
                                  Text(
                                    destinos[i].etiquetaCorta ?? destinos[i].etiqueta,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: i == indiceActivo ? Txt.nb(11, color: p.texto) : Txt.n(11, color: p.textoSecundario),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (usuario.rol == Rol.ciudadano) ...[BotonSos(onPressed: onSos, tamano: 56), const SizedBox(height: 26)],
            InkWell(customBorder: const CircleBorder(), onTap: onPerfil, child: AvatarUsuario(usuario: usuario)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
