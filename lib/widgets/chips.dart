import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Grupo de chips de selección única (p. ej. filtros Todas/Motos/Autos).
class GrupoChips<T> extends StatelessWidget {
  const GrupoChips({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.etiqueta,
    required this.onChanged,
    this.icono,
  });

  final List<T> opciones;
  final T seleccionado;
  final String Function(T) etiqueta;
  final IconData? Function(T)? icono;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in opciones)
          ChoiceChip(
            label: Text(etiqueta(o)),
            avatar: icono?.call(o) == null ? null : Icon(icono!(o), size: 18),
            selected: o == seleccionado,
            showCheckmark: false,
            onSelected: (_) => onChanged(o),
            selectedColor: AppColors.rojo,
            backgroundColor: scheme.surface,
            side: BorderSide(color: o == seleccionado ? AppColors.rojo : scheme.outline),
            labelStyle: TextStyle(color: o == seleccionado ? Colors.white : scheme.onSurface),
            iconTheme: IconThemeData(color: o == seleccionado ? Colors.white : scheme.onSurface),
          ),
      ],
    );
  }
}
