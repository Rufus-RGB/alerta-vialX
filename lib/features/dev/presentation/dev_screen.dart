import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/pantalla_proximamente.dart';

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context) => const PantallaProximamente(
        titulo: 'Panel DEV',
        icono: Icons.code_rounded,
        color: AppColors.moradoDev,
        descripcion: 'Herramientas de desarrollo y monitoreo de datos.',
      );
}
