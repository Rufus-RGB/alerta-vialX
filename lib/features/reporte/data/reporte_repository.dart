import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reporte.dart';

/// Contrato de reportes. La API real (FastAPI) recibirá el POST /reportes.
abstract interface class ReporteRepository {
  Future<Reporte> enviar(BorradorReporte borrador);
  Future<Reporte?> porId(String id);
  Future<List<Reporte>> misReportes();
  Future<List<BorradorReporte>> pendientes();
  Future<void> guardarPendiente(BorradorReporte borrador);
  Future<void> limpiarPendientes();
}

class SinConexionException implements Exception {
  const SinConexionException();
  @override
  String toString() => 'Sin conexión a internet';
}

final reporteRepositoryProvider = Provider<ReporteRepository>((ref) => MockReporteRepository());

final reportePorIdProvider = FutureProvider.family<Reporte?, String>((ref, id) => ref.watch(reporteRepositoryProvider).porId(id));
final misReportesProvider = FutureProvider<List<Reporte>>((ref) => ref.watch(reporteRepositoryProvider).misReportes());

/// Mock: comprueba la conexión con una petición ligera (dio); si no hay red, el reporte queda pendiente.
class MockReporteRepository implements ReporteRepository {
  MockReporteRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));

  final Dio _dio;
  static const _clavePendientes = 'reportes_pendientes';
  int _consecutivo = 2048;
  final _enviados = <String, Reporte>{};

  Future<bool> _hayConexion() async {
    try {
      await _dio.head<void>('https://tile.openstreetmap.org/0/0/0.png');
      return true;
    } on DioException catch (e) {
      // Un error HTTP significa que sí hubo respuesta del servidor.
      return e.type == DioExceptionType.badResponse;
    }
  }

  Reporte _crear(String id, BorradorReporte b) {
    String hora(Duration d) {
      final t = b.fecha.add(d);
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'a. m.' : 'p. m.'}';
    }

    return Reporte(
      id: id,
      borrador: b,
      estado: EstadoReporte.enAtencion,
      seguimiento: [
        PasoSeguimiento(titulo: 'Reporte enviado', detalle: 'Hoy · ${hora(Duration.zero)}', estado: 'hecho'),
        PasoSeguimiento(titulo: 'Recibido por la Policía', detalle: 'CAI Chapinero · ${hora(const Duration(minutes: 3))}', estado: 'hecho'),
        PasoSeguimiento(titulo: 'En atención', detalle: 'Patrulla en camino · ${hora(const Duration(minutes: 7))}', estado: 'actual'),
        const PasoSeguimiento(titulo: 'Caso cerrado', detalle: 'Pendiente', estado: 'pendiente'),
      ],
    );
  }

  @override
  Future<Reporte> enviar(BorradorReporte borrador) async {
    if (!await _hayConexion()) {
      await guardarPendiente(borrador);
      throw const SinConexionException();
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final id = 'AV-${_consecutivo++}';
    return _enviados[id] = _crear(id, borrador);
  }

  @override
  Future<Reporte?> porId(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _enviados[id] ?? (await misReportes()).where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<List<Reporte>> misReportes() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ejemplo = _crear(
      'AV-2048',
      BorradorReporte(
        marca: 'Bajaj',
        modelo: 'Pulsar NS200',
        placa: 'ABC12D',
        color: 'Negra',
        fecha: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    );
    return [..._enviados.values.toList().reversed, if (!_enviados.containsKey('AV-2048')) ejemplo];
  }

  @override
  Future<List<BorradorReporte>> pendientes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_clavePendientes) ?? const [])
        .map((s) => BorradorReporte.fromJson((jsonDecode(s) as Map).cast<String, Object?>()))
        .toList();
  }

  @override
  Future<void> guardarPendiente(BorradorReporte borrador) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList(_clavePendientes) ?? <String>[];
    await prefs.setStringList(_clavePendientes, [...lista, jsonEncode(borrador.toJson())]);
  }

  @override
  Future<void> limpiarPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clavePendientes);
  }
}
