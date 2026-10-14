import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reporte.dart';

class EstadoFormulario {
  const EstadoFormulario({required this.borrador, this.paso = 0});

  final BorradorReporte borrador;

  /// 0 Información, 1 Ubicación, 2 Confirmar.
  final int paso;

  EstadoFormulario copyWith({BorradorReporte? borrador, int? paso}) =>
      EstadoFormulario(borrador: borrador ?? this.borrador, paso: paso ?? this.paso);
}

/// Estado del asistente "Reportar hurto" (se conserva al cambiar de pestaña).
final reporteControllerProvider = NotifierProvider<ReporteController, EstadoFormulario>(ReporteController.new);

class ReporteController extends Notifier<EstadoFormulario> {
  @override
  EstadoFormulario build() => EstadoFormulario(borrador: BorradorReporte(fecha: DateTime.now()));

  void actualizar(BorradorReporte Function(BorradorReporte b) cambio) => state = state.copyWith(borrador: cambio(state.borrador));

  void irAPaso(int paso) => state = state.copyWith(paso: paso.clamp(0, 2));

  void reiniciar() => state = EstadoFormulario(borrador: BorradorReporte(fecha: DateTime.now()));
}
