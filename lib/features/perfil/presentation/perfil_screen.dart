import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/presentation/auth_controller.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usuario = ref.watch(authControllerProvider).usuario;
    final modo = ref.watch(themeModeProvider);
    final inferior = MediaQuery.paddingOf(context).bottom;
    if (usuario == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, inferior + 24),
            children: [
              Tarjeta(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: usuario.rol.color,
                      foregroundColor: Colors.white,
                      child: Text(usuario.nombre.isEmpty ? '?' : usuario.nombre[0], style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.nombre, style: theme.textTheme.titleMedium),
                          Text(usuario.correo, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Chip(
                            avatar: Icon(usuario.rol.icono, size: 16, color: Colors.white),
                            label: Text(usuario.rol.etiqueta),
                            backgroundColor: usuario.rol.color,
                            labelStyle: const TextStyle(color: Colors.white),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const TituloSeccion('Ajustes'),
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apariencia', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Sistema')),
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Claro')),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Oscuro')),
                        ],
                        selected: {modo},
                        onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).cambiar(s.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).cerrarSesion(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
