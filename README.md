# Alerta Vial

App de seguridad vial para Bogotá en Flutter, para **Web (PWA)** y **Android**.
Estado: **Sprint 1** (tema, componentes base, Splash, Login con roles, Inicio del ciudadano, Mapa).

## Requisitos

- Flutter 3.47+ (Dart 3.13+)
- Chrome (para web) y Android Studio con un emulador (API 24+), o un dispositivo Android
- Android SDK con platform 36 y **NDK 28.2.13676358** (lo pide el plugin de Gradle de Flutter). Si falta:
  `android sdk install ndk/28.2.13676358` (Android CLI de `cmdline-tools/latest/bin`)

```bash
flutter pub get
```

## Cómo correrlo

### Web (Chrome)

```bash
flutter run -d chrome
```

### Emulador de Android

1. Abre Android Studio → *Device Manager* → inicia un emulador (o ejecuta `flutter emulators --launch <id>`).
2. Verifica que aparezca con `flutter devices`.
3. Ejecuta:

```bash
flutter run -d emulator-5554
```

(Si solo hay un dispositivo conectado basta con `flutter run`.) Para probar "Mi ubicación" en el emulador,
define una ubicación en *Extended controls → Location*.

### Compilar

```bash
flutter build web
```

```bash
flutter build apk --debug
```

La PWA queda en `build/web` (manifest con nombre "Alerta Vial", color de tema `#FF383C` e íconos en `web/icons`).
El APK queda en `build/app/outputs/flutter-apk/app-debug.apk`.

### Pruebas y análisis

```bash
flutter analyze
```

```bash
flutter test
```

## Acceso de demostración

El login es simulado (`MockAuthRepository`): **cualquier correo con `@` y cualquier contraseña** funcionan.
Elige el rol (Ciudadano / DEV / Autoridad) antes de entrar; el router redirige a la pantalla de inicio del rol
y bloquea las rutas de otros roles.

## Arquitectura

- **Estado:** `flutter_riverpod` (Notifiers y FutureProviders).
- **Rutas:** `go_router` con redirección por sesión y rol (`lib/core/router/app_router.dart`).
- **Datos:** repositorios con interfaz + implementación `Mock*` (latencia simulada). Para conectar la API,
  crea una implementación con `dio` y cámbiala en el `Provider` del repositorio.

```
lib/
  core/       constants (colores, breakpoints), theme (claro/oscuro), router
  widgets/    AppShell adaptable, HUD inferior, barra lateral, tarjetas, botones, chips, etiquetas de riesgo
  features/
    auth/       Splash, Login con selector de rol, sesión
    inicio/     Saludo, clima, acciones rápidas, zonas de riesgo
    mapa/       flutter_map + OSM, pines de hurto, zonas de calor, filtros, mi ubicación
    reporte/    (próximo sprint)
    alertas/    (próximo sprint)
    perfil/     Datos del usuario, Ajustes (tema Sistema/Claro/Oscuro), cerrar sesión
    dev/        Panel DEV (próximo sprint)
    autoridad/  Panel de Autoridad (próximo sprint)
```

**Diseño adaptable:** ancho < 840 px → HUD inferior (Inicio, Mapa, SOS flotante, Alertas, Perfil);
ancho ≥ 840 px → barra lateral con destinos según el rol.

## Decisiones tomadas (no definidas en el encargo)

- **Diseño de Figma:** no se recibió el enlace del archivo "Imagenes APP alerta"; la interfaz se construyó a partir
  de la paleta, fuentes y estructura descritas. Ajustar al tener acceso al Figma.
- **Ajustes** vive como sección dentro de **Perfil** (selector de tema persistido con `shared_preferences`).
- **Sesión** guardada con `flutter_secure_storage`; si falla (p. ej. web sin contexto seguro), queda solo en memoria.
- **SOS** muestra una confirmación y una notificación simulada (sin backend aún).
- **CAI cercanos** abre una hoja inferior con una lista de ejemplo; al tocar uno, centra el mapa en él.
- **Zonas de calor** se dibujan como círculos concéntricos semitransparentes (`CircleLayer`), sin plugin de heatmap.
- **Mapa en modo oscuro:** los tiles de OSM se invierten con un `ColorFilter` (sin proveedor de tiles oscuro).
- **Clima** es de ejemplo (`MockClimaRepository`), fijo en Bogotá.
- **Reportar, Alertas, Panel DEV y Panel Autoridad** muestran "Próximamente" (fuera del alcance del Sprint 1).
- **Íconos PWA** generados por script (triángulo amarillo de advertencia sobre rojo); el ícono Android es el de Flutter por defecto.
- **google_fonts 9** devuelve `TextTheme` de `package:material_ui`; por eso el tema se arma con los helpers de
  `TextStyle` (`GoogleFonts.notoSans` / `GoogleFonts.mPlusRounded1c`). Las fuentes se descargan en tiempo de ejecución.
- **Android:** `compileSdk` y `targetSdk` 36; permisos `INTERNET`, `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION`
  (solo primer plano, sin `ACCESS_BACKGROUND_LOCATION`).
- **Tiles OSM** se usan directamente de `tile.openstreetmap.org` (válido para desarrollo; para producción usar un
  proveedor con SLA según la política de uso de OSM).
