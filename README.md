# Alerta Vial

App de seguridad vial para Bogotá en Flutter, para **Web (PWA)** y **Android**, construida a partir del Figma
[Imagenes APP alerta](https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta)
(páginas **Principal** y **Multiplataforma**). Las capturas de referencia están en `docs/diseno/`.

## Estado por sprint

| Sprint | Rama | Contenido |
|---|---|---|
| 3 | `sprint-3` | Perfil (celular y PC), Editar perfil, Ajustes (tema Claro/Oscuro/Sistema), Mis reportes con filtros y estado vacío, Mis vehículos, Agregar vehículo, Zonas favoritas, Agregar zona (mapa + radio), Privacidad y datos, Centro de ayuda (preguntas frecuentes) |
| 2 | `sprint-2` | Reportar hurto (pasos 1–3 en celular, un solo paso en tablet/PC), Reporte enviado, Estado del reporte, Sin conexión (reporte pendiente + reintentar), Alertas, Detalle de alerta, Configurar alertas (persistido) |
| 1 | `sprint-1` | Tema y componentes base, HUD con curva del SOS, riel (tablet) y barra lateral (PC), Splash, Carga, Login con rol, Crear cuenta, Recuperar contraseña, Permisos, Verificación de autoridad, Inicio, Menú lateral, Notificaciones, Mapa, Detalle de reporte, Emergencia SOS |

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

1. Abre Android Studio → *Device Manager* → inicia un emulador (o `flutter emulators --launch <id>`).
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

La PWA queda en `build/web` (manifest "Alerta Vial", color de tema `#FF383C`, íconos en `web/icons`).
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
(ciudadano → Inicio, DEV → Panel DEV, autoridad → Panel Autoridad) y bloquea las rutas de los otros roles.
Google y Apple entran como ciudadano de prueba. "Crear cuenta" lleva a la pantalla de Permisos y luego al Inicio.

## Diseño adaptable

| Ancho | Diseño | Navegación |
|---|---|---|
| < 840 px | Celular / Android (base 428×926) | HUD inferior: Inicio, Mapa, **SOS** con curva, Alertas, Perfil |
| 840 – 1279 px | Tablet (base 1194×834) | Riel lateral de íconos (88 px) |
| ≥ 1280 px | PC / Web (base 1440×900) | Barra lateral completa (248 px) según el rol |

Colores por rol: ciudadano amarillo, DEV morado, autoridad azul (insignias, avatar e ítem activo de la barra).

## Arquitectura

- **Estado:** `flutter_riverpod` (Notifiers y FutureProviders).
- **Rutas:** `go_router` con redirección por sesión y rol (`lib/core/router/app_router.dart`).
- **Datos:** repositorios con interfaz + implementación `Mock*` con los datos del diseño (Kennedy, Bosa,
  Ciudad Bolívar, Engativá; placas ABC12D, HGT567…). Para la API (FastAPI + MongoDB en Render) basta con crear
  una implementación con `dio` y cambiarla en el `Provider` del repositorio.
- **Íconos:** `flutter_tabler_icons` (mismo estilo Tabler de línea del Figma). La sirena del logo, los logos de
  Google/Apple y las ilustraciones (Bogotá, carga, hero, banner GPS) se descargaron del Figma a `assets/`.

```
lib/
  core/       constants (colores, breakpoints), theme (claro/oscuro + Paleta), router
  widgets/    AppShell, HUD, barra lateral/riel, menú lateral, tarjetas, botones, campos, chips, etiquetas de riesgo
  features/
    auth/       Splash/Carga, Login, Crear cuenta, Recuperar, Permisos, Verificación de autoridad
    inicio/     Inicio (celular y panel tablet/PC), Notificaciones, Emergencia SOS
    mapa/       Mapa (flutter_map + OSM), detalle de reporte, filtros, búsqueda, mi ubicación
    reporte/    Asistente de reporte, enviado, estado y sin conexión
    alertas/    Alertas, detalle y configuración
    perfil/     Perfil, edición, ajustes, mis reportes, vehículos, zonas favoritas, privacidad y ayuda
    dev/ autoridad/   (siguientes sprints)
```

## Decisiones tomadas (no definidas en el diseño)

- **Mapa real en vez del mapa dibujado del Figma:** se usa OpenStreetMap con un filtro de color (gris claro en
  modo claro, gris invertido en oscuro) para parecerse al mapa del diseño. Zonas de calor = círculos concéntricos
  con opacidad decreciente (aproximan el degradado radial). Tiles directos de `tile.openstreetmap.org`
  (válido para desarrollo; en producción usar un proveedor con SLA).
- **Pines:** rojo con advertencia para reportes de riesgo alto/medio; círculo amarillo con el vehículo para
  reportes informativos (p. ej. "Vehículo recuperado").
- **Splash + Carga** se muestran juntos mientras se restaura la sesión (~2,6 s).
- **Login de celular:** el botón de rol activo usa el color del rol (ciudadano `#FABD03` como en el Figma).
- **Recuperar contraseña:** primero envía el código (mock) y luego habilita los 4 dígitos y el contador 0:45.
- **Verificación de autoridad:** exige correo `.gov.co` y foto del carné (`image_picker`); la solicitud es simulada.
- **Permisos:** "Continuar" pide el permiso de ubicación en primer plano con `geolocator`; las notificaciones
  quedan como preferencia (sin push todavía).
- **SOS:** mantener presionado 3 s envía una alerta simulada; "Llamar al 123" abre el marcador (`url_launcher`).
- **Detalle de reporte:** hoja inferior en celular y diálogo en tablet/PC; "Compartir" copia el texto al portapapeles.
- **Tablet:** login dividido como en PC; en las pantallas de acceso secundarias el formulario se centra en una tarjeta.
- **google_fonts 9** devuelve `TextTheme` de `package:material_ui`; el tema se arma con los helpers de `TextStyle`.
  Las fuentes se descargan en tiempo de ejecución.
- **Android:** `compileSdk`/`targetSdk` 36; permisos `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
  (solo primer plano). El ícono de Android es el de Flutter por defecto.
- **Sin conexión (Sprint 2):** antes de enviar, el repositorio hace una petición ligera con `dio`; si falla,
  el reporte se guarda en `shared_preferences` y se muestra la pantalla "Sin conexión" con "Reintentar".
- **Ubicación del reporte:** tocar el mapa mueve el pin y nombra la localidad más cercana (sin geocodificación
  externa); la dirección es editable. La búsqueda acepta nombres de localidades.
- **Placas:** se validan con el formato colombiano (ABC123 autos / ABC12D motos).
- **Perfil (Sprint 3):** vehículos, zonas favoritas, privacidad y localidad se guardan localmente con
  `shared_preferences` (mock); el nivel de riesgo de una zona nueva se calcula con las zonas de riesgo cercanas.
  Cambiar contraseña, descargar datos y el chat de soporte son simulados. Eliminar cuenta cierra la sesión.
- **Recarga en web:** al recargar, la ruta pedida se conserva a través del Splash (`/splash?desde=…`).
- **Ramas:** cada sprint se sube a su rama `sprint-N`, creada desde la anterior.
