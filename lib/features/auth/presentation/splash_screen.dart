import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/logo_alerta.dart';

/// Splash (logo + "Tu ciudad más segura" + ilustración) y luego Carga con barra de progreso.
/// El router redirige cuando termina de restaurarse la sesión.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _cargando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () => setState(() => _cargando = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _cargando ? const _Carga() : const _Splash(),
      ),
    );
  }
}

/// Ilustración de Bogotá recortada como en el Figma (la imagen ocupa ~173 % del ancho).
class _IlustracionBogota extends StatelessWidget {
  const _IlustracionBogota();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => ClipRect(
        child: OverflowBox(
          maxWidth: c.maxWidth * 1.7293,
          minWidth: c.maxWidth * 1.7293,
          alignment: const Alignment(-0.17, 1),
          child: Image.asset('assets/images/ilustracion_bogota.png', fit: BoxFit.fitWidth, alignment: Alignment.bottomCenter),
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth.clamp(0.0, 560.0);
        return Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, height: c.maxHeight * 0.55, child: const _IlustracionBogota()),
            Center(
              child: SizedBox(
                width: ancho,
                height: c.maxHeight,
                child: Padding(
                  padding: EdgeInsets.only(left: 40, right: 40, top: c.maxHeight * 0.16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LogoAlerta(),
                      const SizedBox(height: 36),
                      Text('Tu ciudad', style: Txt.display(40, color: p.texto)),
                      Text('más segura', style: Txt.display(40, color: AppColors.rojoIntenso)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Carga extends StatelessWidget {
  const _Carga();

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return LayoutBuilder(
      builder: (context, c) => Center(
        child: SizedBox(
          width: c.maxWidth.clamp(0.0, 560.0),
          child: Column(
            children: [
              SizedBox(height: c.maxHeight * 0.16),
              const LogoAlerta(),
              const Spacer(),
              Image.asset('assets/images/ilustracion_carga.png', height: c.maxHeight * 0.24, fit: BoxFit.contain),
              const Spacer(),
              Text.rich(
                TextSpan(
                  style: Txt.display(28, color: p.texto),
                  children: const [
                    TextSpan(text: 'Cargando ', style: TextStyle(color: AppColors.rojoIntenso)),
                    TextSpan(text: 'tu ciudad'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Conectando alertas y rutas seguras', style: Txt.n(12, color: p.textoTenue)),
              const SizedBox(height: 54),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.1, end: 1),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeInOut,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 20,
                      color: AppColors.amarilloRol,
                      backgroundColor: context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFD9D9D9),
                    ),
                  ),
                ),
              ),
              SizedBox(height: c.maxHeight * 0.17),
            ],
          ),
        ),
      ),
    );
  }
}
