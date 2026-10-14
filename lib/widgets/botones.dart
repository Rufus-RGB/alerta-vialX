import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Botón principal (relleno) con ícono opcional y estado de carga.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.cargando = false,
    this.color,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool cargando;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final estilo = color == null ? null : FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white);
    final hijo = cargando
        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Text(texto);
    return SizedBox(
      width: double.infinity,
      child: icono == null || cargando
          ? FilledButton(style: estilo, onPressed: cargando ? null : onPressed, child: hijo)
          : FilledButton.icon(style: estilo, onPressed: onPressed, icon: Icon(icono), label: hijo),
    );
  }
}

/// Botón SOS rojo circular (flotante en el HUD).
class BotonSos extends StatelessWidget {
  const BotonSos({super.key, required this.onPressed, this.tamano = 64});

  final VoidCallback onPressed;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Enviar alerta SOS',
      child: Material(
        color: AppColors.rojo,
        shape: CircleBorder(side: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4)),
        elevation: 6,
        shadowColor: AppColors.rojo.withValues(alpha: 0.6),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: tamano,
            child: Center(
              child: Text(
                'SOS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, letterSpacing: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
