import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';

/// Campo con etiqueta arriba (15 px, redondeada) e input de 50 px con ícono, como en el Figma.
class CampoEtiquetado extends StatefulWidget {
  const CampoEtiquetado({
    super.key,
    required this.etiqueta,
    required this.hint,
    this.icono,
    this.controller,
    this.contrasena = false,
    this.teclado,
    this.validator,
    this.accionTeclado,
    this.onSubmitted,
    this.autofill,
    this.sufijo,
    this.lineas = 1,
    this.formatos,
    this.soloLectura = false,
    this.onTap,
    this.valorInicial,
    this.onChanged,
  });

  final String etiqueta;
  final String hint;
  final IconData? icono;
  final TextEditingController? controller;
  final bool contrasena;
  final TextInputType? teclado;
  final FormFieldValidator<String>? validator;
  final TextInputAction? accionTeclado;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofill;
  final Widget? sufijo;
  final int lineas;
  final List<TextInputFormatter>? formatos;
  final bool soloLectura;
  final VoidCallback? onTap;
  final String? valorInicial;
  final ValueChanged<String>? onChanged;

  @override
  State<CampoEtiquetado> createState() => _CampoEtiquetadoState();
}

class _CampoEtiquetadoState extends State<CampoEtiquetado> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 4),
          child: Text(widget.etiqueta, style: Txt.r(15, color: p.texto)),
        ),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.valorInicial : null,
          obscureText: widget.contrasena && _oculto,
          keyboardType: widget.teclado,
          validator: widget.validator,
          textInputAction: widget.accionTeclado,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofill,
          maxLines: widget.contrasena ? 1 : widget.lineas,
          inputFormatters: widget.formatos,
          readOnly: widget.soloLectura,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          style: Txt.n(14, color: p.texto),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.icono == null ? null : Icon(widget.icono, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 48),
            suffixIcon: widget.contrasena
                ? IconButton(
                    tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(_oculto ? TablerIcons.eye : TablerIcons.eye_off, size: 20),
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : widget.sufijo,
          ),
        ),
      ],
    );
  }
}

/// Buscador en píldora (mapa y encabezado de escritorio).
class Buscador extends StatelessWidget {
  const Buscador({super.key, required this.hint, this.onSubmitted, this.controller, this.alto = 44, this.radio = 22, this.sombra = false});

  final String hint;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final double alto;
  final double radio;
  final bool sombra;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: sombra ? BorderSide.none : BorderSide(color: p.borde),
    );
    return Container(
      height: alto,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        boxShadow: sombra ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 14, offset: Offset(0, 4))] : null,
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: Txt.n(13, color: p.texto),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Txt.n(13, color: p.placeholder),
          filled: true,
          fillColor: p.tarjeta,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(TablerIcons.search, size: 18, color: p.textoSecundario),
          border: borde,
          enabledBorder: borde,
          focusedBorder: borde.copyWith(borderSide: const BorderSide(color: Color(0xFFF2B705), width: 1.5)),
        ),
      ),
    );
  }
}
