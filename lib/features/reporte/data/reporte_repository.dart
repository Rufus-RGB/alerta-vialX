import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mapa/domain/modelos_mapa.dart';
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

  Reporte _crear(String id, BorradorReporte b, {EstadoReporte estado = EstadoReporte.enAtencion}) {
    String hora(Duration d) {
      final t = b.fecha.add(d);
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'a. m.' : 'p. m.'}';
    }

    final cerrado = estado == EstadoReporte.cerrado || estado == EstadoReporte.recuperado;
    return Reporte(
      id: id,
      borrador: b,
      estado: estado,
      seguimiento: [
        PasoSeguimiento(titulo: 'Reporte enviado', detalle: 'Hoy · ${hora(Duration.zero)}', estado: 'hecho'),
        PasoSeguimiento(titulo: 'Recibido por la Policía', detalle: 'CAI Chapinero · ${hora(const Duration(minutes: 3))}', estado: 'hecho'),
        PasoSeguimiento(titulo: 'En atención', detalle: 'Patrulla en camino · ${hora(const Duration(minutes: 7))}', estado: cerrado ? 'hecho' : 'actual'),
        PasoSeguimiento(
          titulo: estado == EstadoReporte.recuperado ? 'Vehículo recuperado' : 'Caso cerrado',
          detalle: cerrado ? 'Cerrado por la autoridad' : 'Pendiente',
          estado: cerrado ? 'hecho' : 'pendiente',
        ),
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
    final ahora = DateTime.now();
    BorradorReporte b(TipoVehiculo t, String marca, String modelo, String placa, String barrio, int dias) => BorradorReporte(
          vehiculo: t,
          marca: marca,
          modelo: modelo,
          placa: placa,
          color: 'Negra',
          barrio: barrio,
          direccion: barrio,
          fecha: ahora.subtract(Duration(days: dias, minutes: dias == 0 ? 12 : 0)),
        );
    final ejemplos = [
      _crear('AV-2048', b(TipoVehiculo.moto, 'Bajaj', 'Pulsar NS200', 'ABC12D', 'Chapinero', 0)),
      _crear('AV-1990', b(TipoVehiculo.auto, 'Chevrolet', 'Onix', 'HGT567', 'Suba', 12), estado: EstadoReporte.recuperado),
      _crear('AV-1874', b(TipoVehiculo.moto, 'Bajaj', 'Pulsar NS200', 'ABC12D', 'Teusaquillo', 26), estado: EstadoReporte.cerrado),
      _crear('AV-1702', b(TipoVehiculo.auto, 'Chevrolet', 'Spark', 'JKL432', 'Kennedy', 45), estado: EstadoReporte.cerrado),
      _crear('AV-1655', b(TipoVehiculo.moto, 'Yamaha', 'FZ 2.0', 'XYZ98E', 'Bosa', 63), estado: EstadoReporte.cerrado),
    ];
    return [..._enviados.values.toList().reversed, ...ejemplos.where((e) => !_enviados.containsKey(e.id))];
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
