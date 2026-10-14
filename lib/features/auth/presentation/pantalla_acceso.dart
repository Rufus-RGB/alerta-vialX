import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/tarjeta.dart';

/// Marco común de las pantallas de acceso secundarias (crear cuenta, recuperar, permisos…).
/// En celular ocupa toda la pantalla; en tablet/PC se centra en una tarjeta de 480 px.
class PantallaAcceso extends StatelessWidget {
  const PantallaAcceso({super.key, required this.child, this.titulo, this.atras = true});

  final Widget child;
  final String? titulo;
  final bool atras;

  @override
  Widget build(BuildContext context) {
    final celular = context.esCelular;
    final cuerpo = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(19, celular ? 6 : 8, 19, 32),
      child: child,
    );
    final encabezado = atras || titulo != null
        ? EncabezadoPantalla(titulo: titulo, onAtras: atras ? null : () {})
        : null;
    if (celular) {
      return Scaffold(appBar: encabezado, body: SafeArea(top: false, child: cuerpo));
    }
    return Scaffold(
      backgroundColor: context.paleta.fondoPanel,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 880),
            child: Tarjeta(
              padding: EdgeInsets.zero,
              radio: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?encabezado,
                  Flexible(child: cuerpo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
