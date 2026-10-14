import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Clima {
  const Clima({required this.ciudad, required this.temperatura, required this.descripcion, required this.icono, required this.consejo});

  final String ciudad;
  final int temperatura;
  final String descripcion;
  final IconData icono;
  final String consejo;
}

/// Contrato del clima. Luego puede conectarse a un servicio meteorológico real.
abstract interface class ClimaRepository {
  Future<Clima> climaActual();
}

final climaRepositoryProvider = Provider<ClimaRepository>((ref) => MockClimaRepository());
final climaProvider = FutureProvider<Clima>((ref) => ref.watch(climaRepositoryProvider).climaActual());

class MockClimaRepository implements ClimaRepository {
  @override
  Future<Clima> climaActual() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const Clima(
      ciudad: 'Bogotá',
      temperatura: 16,
      descripcion: 'Llovizna',
      icono: Icons.grain_rounded,
      consejo: 'Vía húmeda: reduce la velocidad y aumenta la distancia.',
    );
  }
}
