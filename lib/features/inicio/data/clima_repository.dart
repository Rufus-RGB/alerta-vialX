import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class Clima {
  const Clima({required this.ciudad, required this.temperatura, required this.descripcion, required this.icono, required this.maxima, required this.minima});

  final String ciudad;
  final int temperatura;
  final String descripcion;
  final IconData icono;
  final int maxima;
  final int minima;
}

/// Indicadores del inicio en tablet/PC.
class ResumenInicio {
  const ResumenInicio({
    required this.reportesHoy,
    required this.variacion,
    required this.zonaActual,
    required this.riesgoZona,
    required this.alertasCerca,
    required this.caiDistancia,
    required this.caiNombre,
  });

  final int reportesHoy;
  final int variacion;
  final String zonaActual;
  final String riesgoZona;
  final int alertasCerca;
  final String caiDistancia;
  final String caiNombre;
}

/// Contrato del clima/resumen. Luego puede conectarse a un servicio real.
abstract interface class InicioRepository {
  Future<Clima> climaActual();
  Future<ResumenInicio> resumen();
}

final inicioRepositoryProvider = Provider<InicioRepository>((ref) => MockInicioRepository());
final climaProvider = FutureProvider<Clima>((ref) => ref.watch(inicioRepositoryProvider).climaActual());
final resumenInicioProvider = FutureProvider<ResumenInicio>((ref) => ref.watch(inicioRepositoryProvider).resumen());

class MockInicioRepository implements InicioRepository {
  @override
  Future<Clima> climaActual() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const Clima(ciudad: 'Bogotá', temperatura: 13, descripcion: 'Nubes dispersas', icono: TablerIcons.cloud, maxima: 18, minima: 8);
  }

  @override
  Future<ResumenInicio> resumen() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const ResumenInicio(
      reportesHoy: 18,
      variacion: 3,
      zonaActual: 'Chapinero',
      riesgoZona: 'Riesgo medio',
      alertasCerca: 3,
      caiDistancia: '1,2 km',
      caiNombre: 'CAI Chapinero',
    );
  }
}
