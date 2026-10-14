import 'package:flutter/material.dart';

/// Marcador para pantallas que llegan en sprints posteriores.
class PantallaProximamente extends StatelessWidget {
  const PantallaProximamente({super.key, required this.titulo, required this.icono, required this.color, this.descripcion});

  final String titulo;
  final IconData icono;
  final Color color;
  final String? descripcion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icono, size: 44, color: color),
              ),
              const SizedBox(height: 20),
              Text('Próximamente', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                descripcion ?? 'Esta sección estará disponible en el próximo sprint.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
