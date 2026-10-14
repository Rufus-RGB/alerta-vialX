import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/pantalla_proximamente.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context) => const PantallaProximamente(
        titulo: 'Alertas',
        icono: Icons.notifications_rounded,
        color: AppColors.amarillo,
        descripcion: 'Aquí verás las alertas cercanas a tu ubicación.',
      );
}
