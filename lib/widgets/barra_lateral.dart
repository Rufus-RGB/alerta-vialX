import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/auth/domain/usuario.dart';
import 'logo_alerta.dart';
import 'navegacion.dart';

/// Barra lateral para pantallas anchas (>= 840 px), con destinos según el rol.
class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.usuario,
    required this.destinos,
    required this.indiceActivo,
    required this.onDestino,
    required this.onSos,
  });

  final Usuario usuario;
  final List<DestinoNav> destinos;
  final int indiceActivo;
  final ValueChanged<DestinoNav> onDestino;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const LogoAlerta(tamano: 40),
                  const SizedBox(width: 12),
                  Text('Alerta Vial', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(usuario.rol.icono, size: 16, color: Colors.white),
                  label: Text(usuario.rol.etiqueta),
                  backgroundColor: usuario.rol.color,
                  labelStyle: const TextStyle(color: Colors.white),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < destinos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: Icon(destinos[i].icono),
                    title: Text(destinos[i].etiqueta, style: theme.textTheme.titleSmall?.copyWith(color: i == indiceActivo ? AppColors.rojo : null)),
                    selected: i == indiceActivo,
                    selectedColor: AppColors.rojo,
                    selectedTileColor: AppColors.rojo.withValues(alpha: 0.10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () => onDestino(destinos[i]),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSos,
                icon: const Icon(Icons.sos_rounded),
                label: const Text('SOS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
