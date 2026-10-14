import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/pantalla_proximamente.dart';

class ReporteScreen extends StatelessWidget {
  const ReporteScreen({super.key});

  @override
  Widget build(BuildContext context) => const PantallaProximamente(
        titulo: 'Reportar incidente',
        icono: Icons.add_location_alt_rounded,
        color: AppColors.rojo,
        descripcion: 'Pronto podrás reportar hurtos y accidentes con foto y ubicación.',
      );
}
