import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/pantalla_proximamente.dart';

class AutoridadScreen extends StatelessWidget {
  const AutoridadScreen({super.key});

  @override
  Widget build(BuildContext context) => const PantallaProximamente(
        titulo: 'Panel de Autoridad',
        icono: Icons.local_police_rounded,
        color: AppColors.azulAutoridad,
        descripcion: 'Gestión de reportes y despliegue de patrullas.',
      );
}
