import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/pantalla_secundaria.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/presentation/verificacion_autoridad_screen.dart' show BordePunteado;
import '../../mapa/domain/modelos_mapa.dart';
import '../../reporte/domain/reporte.dart';
import '../../reporte/presentation/reporte_widgets.dart';
import '../data/perfil_repository.dart';
import 'perfil_screen.dart' show pildoraVehiculo;

/// Botón con borde punteado "+ Agregar …".
class BotonAgregarPunteado extends StatelessWidget {
  const BotonAgregarPunteado({super.key, required this.texto, required this.onTap});

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return CustomPaint(
      painter: BordePunteado(color: p.inputBorde),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(TablerIcons.plus, color: p.texto),
              const SizedBox(width: 8),
              Text(texto, style: Txt.r(18, color: p.texto)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Mis vehículos ----------------

class VehiculosScreen extends ConsumerWidget {
  const VehiculosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final vehiculos = ref.watch(vehiculosProvider);
    return PantallaSecundaria(
      titulo: 'Mis vehículos',
      children: [
        for (final v in vehiculos)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Tarjeta(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconoCirculo(
                        icono: v.tipo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car,
                        fondo: v.tipo == TipoVehiculo.moto ? AppColors.amarillo : AppColors.rojo,
                        color: v.tipo == TipoVehiculo.moto ? Colors.black : Colors.white,
                        tamano: 56,
                        tamanoIcono: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.nombreTipo, style: Txt.r(19, color: p.texto)),
                            Text('${v.marca == 'Chevrolet' ? 'Chevrolet ' : ''}${v.modelo} · ${v.anio}', style: Txt.n(13, color: p.textoSecundario)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          pildoraVehiculo(context, v.estado),
                          PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            icon: Icon(TablerIcons.dots, color: p.textoSecundario),
                            onSelected: (op) {
                              if (op == 'eliminar') ref.read(vehiculosProvider.notifier).eliminar(v.id);
                              if (op == 'reportar') context.go('/reporte');
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'reportar', child: Text('Reportar hurto')),
                              PopupMenuItem(value: 'eliminar', child: Text('Eliminar vehículo')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: p.divisor, height: 24),
                  Row(
                    children: [
                      for (final (etiqueta, valor) in [('Placa', v.placa), ('Color', v.color), ('Reportes', '${v.reportes}')])
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(etiqueta, style: Txt.n(12, color: p.textoSecundario)),
                              Text(valor, style: Txt.nb(16, color: p.texto)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        BotonAgregarPunteado(texto: 'Agregar vehículo', onTap: () => context.push('/perfil/vehiculos/agregar')),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(TablerIcons.shield, color: p.textoSecundario),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registrar tus vehículos acelera los reportes y ayuda a la Policía a identificarlos.',
                  style: Txt.n(13, color: p.textoSecundario),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Agregar vehículo ----------------

class AgregarVehiculoScreen extends ConsumerStatefulWidget {
  const AgregarVehiculoScreen({super.key});

  @override
  ConsumerState<AgregarVehiculoScreen> createState() => _AgregarVehiculoScreenState();
}

class _AgregarVehiculoScreenState extends ConsumerState<AgregarVehiculoScreen> {
  TipoVehiculo _tipo = TipoVehiculo.moto;
  String? _marca;
  String? _modelo;
  String? _color;
  int _anio = DateTime.now().year;
  final _placa = TextEditingController();
  String? _foto;

  @override
  void dispose() {
    _placa.dispose();
    super.dispose();
  }

  void _guardar() {
    String? error;
    if (_marca == null || _modelo == null || _color == null) error = 'Completa marca, modelo y color.';
    if (error == null && !placaValida(_placa.text)) error = 'Placa inválida (ej: ${_tipo == TipoVehiculo.moto ? 'ABC12D' : 'ABC123'}).';
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ref.read(vehiculosProvider.notifier).agregar(
          Vehiculo(
            id: 'v${DateTime.now().millisecondsSinceEpoch}',
            tipo: _tipo,
            marca: _marca!,
            modelo: _modelo!,
            anio: _anio,
            placa: _placa.text.toUpperCase(),
            color: _color!,
            foto: _foto,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehículo guardado.'), backgroundColor: AppColors.verdeExito));
    context.canPop() ? context.pop() : context.go('/perfil/vehiculos');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final marcas = marcasPorVehiculo[_tipo]!;
    final anios = [for (var a = DateTime.now().year; a >= DateTime.now().year - 25; a--) a];
    final modelos = _marca == null ? const <String>[] : [for (final m in marcas[_marca]!) for (final a in anios.take(6)) '$m · $a'];
    return PantallaSecundaria(
      titulo: 'Agregar vehículo',
      anchoMaximo: 520,
      children: [
        SizedBox(
          height: 96,
          child: SelectorTipoVehiculo(
            valor: _tipo,
            alto: 96,
            onChanged: (t) => setState(() {
              _tipo = t;
              _marca = null;
              _modelo = null;
            }),
          ),
        ),
        const SizedBox(height: 16),
        const EtiquetaCampo('Marca', tamano: 15),
        SelectorCampo(valor: _marca, opciones: marcas.keys.toList(), alto: 50, onChanged: (v) => setState(() {
              _marca = v;
              _modelo = null;
            })),
        const SizedBox(height: 10),
        const EtiquetaCampo('Modelo y año', tamano: 15),
        SelectorCampo(
          valor: _modelo == null ? null : '$_modelo · $_anio',
          opciones: modelos,
          alto: 50,
          hint: _marca == null ? 'Elige la marca' : 'Selecciona',
          onChanged: (v) {
            if (v == null) return;
            final partes = v.split(' · ');
            setState(() {
              _modelo = partes.first;
              _anio = int.parse(partes.last);
            });
          },
        ),
        const SizedBox(height: 10),
        const EtiquetaCampo('Placa', tamano: 15),
        TextField(
          controller: _placa,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')), LengthLimitingTextInputFormatter(6)],
          style: Txt.n(14, color: p.texto),
          decoration: InputDecoration(prefixIcon: const Icon(TablerIcons.id, size: 20), hintText: _tipo == TipoVehiculo.moto ? 'ABC12D' : 'ABC123'),
        ),
        const SizedBox(height: 10),
        const EtiquetaCampo('Color', tamano: 15),
        SelectorCampo(valor: _color, opciones: coloresVehiculo, alto: 50, onChanged: (v) => setState(() => _color = v)),
        const SizedBox(height: 14),
        CustomPaint(
          painter: BordePunteado(color: p.inputBorde),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
              if (f != null) setState(() => _foto = f.name);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(_foto == null ? TablerIcons.photo : TablerIcons.photo_check, color: _foto == null ? p.texto : AppColors.verdeExito),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_foto ?? 'Agregar foto del vehículo', overflow: TextOverflow.ellipsis, style: Txt.nb(14, color: p.texto)),
                        Text('Ayuda a identificarlo si lo roban', style: Txt.n(12, color: p.textoSecundario)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        BotonPrincipal(texto: 'Guardar vehículo', color: AppColors.amarillo, onPressed: _guardar),
      ],
    );
  }
}
