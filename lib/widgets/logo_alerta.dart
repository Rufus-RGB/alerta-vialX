import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';

/// Isotipo: cuadro rojo redondeado con la sirena blanca (asset del Figma).
class Isotipo extends StatelessWidget {
  const Isotipo({super.key, this.tamano = 44});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: AppColors.rojo, borderRadius: BorderRadius.circular(tamano * 12 / 44)),
      alignment: Alignment.center,
      child: SvgPicture.asset('assets/icons/siren.svg', width: tamano * 28 / 44, height: tamano * 28 / 44),
    );
  }
}

/// Logo completo: isotipo + "Alerta Vial".
class LogoAlerta extends StatelessWidget {
  const LogoAlerta({super.key, this.tamano = 44, this.colorTexto});

  final double tamano;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Isotipo(tamano: tamano),
        SizedBox(width: tamano * 10 / 44),
        Text('Alerta Vial', style: Txt.r(tamano * 26 / 44, color: colorTexto ?? context.paleta.texto)),
      ],
    );
  }
}
