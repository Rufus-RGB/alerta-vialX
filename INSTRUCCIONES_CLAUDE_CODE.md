# Alerta Vial — Instrucciones para Claude Code

Estás en la carpeta raíz del repositorio de GitHub "Proyecto Alerta VialX". Construye la app **Alerta Vial** en **Flutter** para **WEB (PWA)** y **ANDROID**, replicando fielmente TODO el diseño de Figma indicado abajo. Trabaja de forma autónoma, sprint por sprint, sin detenerte entre sprints.

---

## 0. Crear el proyecto

```bash
flutter create --org co.alertavial --project-name alerta_vial --platforms=android,web .
flutter pub add flutter_map latlong2 geolocator go_router flutter_riverpod dio google_fonts image_picker flutter_secure_storage shared_preferences flutter_svg
```

- Android: `targetSdk 36`. Permisos: `INTERNET`, `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION` (ubicación solo con la app abierta).
- PWA: en `web/manifest.json` pon el nombre "Alerta Vial", el color de tema `#FF383C` y los íconos.

---

## 1. Diseño de Figma (fuente de verdad)

Archivo: **Imagenes APP alerta** → `https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta`

**USAR** solo estas dos páginas:
- **Principal**: todas las pantallas de celular, en claro y oscuro.
- **Multiplataforma (PC · Tablet · Android)**: versiones Android, tablet y PC/web.

**NO USAR**: Cover, Presentacion Poryecto, Respaldo, Boceto Base ni Botones Base. Son presentaciones, bocetos y copias de respaldo.

### Cómo leer el diseño con el MCP de Figma
1. Por cada sección: `get_metadata` del nodo de la sección para listar sus pantallas (frames).
2. Por cada pantalla: `get_design_context` + `get_screenshot`. Guarda la captura en `docs/diseno/<seccion>/<pantalla>.png` para no repetir llamadas.
3. Imágenes e ilustraciones (Hero Bogotá, ilustración del Splash, etc.): `download_assets` a `assets/images/` y regístralas en `pubspec.yaml`.
4. Los íconos son de estilo Tabler (línea). Recréalos como SVG en `assets/icons/` o usa un paquete de íconos equivalente.
5. Las conexiones del prototipo de Figma (botones, HUD, flechas atrás) definen la navegación. Respétalas.
6. Si el MCP falla o llega al límite, usa las capturas ya guardadas en `docs/diseno/`.

### Secciones — página Principal (celular, base 428×926)

| Sección | Enlace |
|---|---|
| 1 · Acceso (todos los roles) | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-6 |
| 2 · Ciudadano · Inicio y mapa | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-9 |
| 3 · Ciudadano · Reportar hurto | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-12 |
| 4 · Ciudadano · Alertas | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-15 |
| 5 · Ciudadano · Perfil | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-18 |
| 6 · DEV (administrador) | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-21 |
| 7 · Autoridad (Policía / SIJIN) | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2098-24 |

### Secciones — página Multiplataforma

| Sección | Enlace |
|---|---|
| Android · 1 · Acceso | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-2 |
| Android · 2 · Inicio y mapa | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-613 |
| Android · 3 · Reportar hurto | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-2188 |
| Android · 4 · Alertas | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-3561 |
| Android · 5 · Perfil | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-4326 |
| Android · 6 · DEV | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-6693 |
| Android · 7 · Autoridad | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-8310 |
| PC / Web · Acceso y Ciudadano | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-10263 |
| PC / Web · DEV | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2118-6 |
| PC / Web · Autoridad | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2118-9 |
| Tablet · Acceso y Ciudadano | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2108-10266 |
| Tablet · DEV | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2118-12 |
| Tablet · Autoridad | https://www.figma.com/design/kcJCXcydeW6jwJah2GrV3z/Imagenes-APP-alerta?node-id=2118-15 |

Cada sección tiene la fila **Modo claro** arriba y la fila **Modo oscuro** abajo. Implementa ambos.

---

## 2. Reglas de diseño

- **Colores:** rojo `#FF383C`, amarillo `#F2B705`, fondo oscuro `#0A1216`, fondo claro `#F5F6F8`, tarjeta oscura `#121B21`, borde oscuro `#24303A`, azul autoridad `#185FA5`, morado DEV `#534AB7`, verde éxito `#1D9E75`.
- **Fuentes** (google_fonts): "M PLUS Rounded 1c" para títulos y botones, "Noto Sans" para textos y datos.
- **Modo claro y oscuro:** `ThemeMode.system` + selector en Ajustes.
- **Diseño adaptable** (usar `LayoutBuilder`):
  - ancho **< 840 px** → diseño de **celular/Android**, con el HUD inferior (Inicio, Mapa, botón SOS rojo flotante al centro con la curva, Alertas, Perfil).
  - **840 – 1279 px** → diseño de **Tablet**, con un riel lateral de íconos.
  - **≥ 1280 px** → diseño de **PC/Web**, con la barra lateral completa según el rol.
- **Colores por rol:** ciudadano amarillo, DEV morado, autoridad azul (insignias, íconos en círculo de color, ítem activo de la barra lateral).
- Radios de 12–16 px, sombras suaves y tarjetas con borde fino en modo oscuro.

---

## 3. Arquitectura

- `flutter_riverpod` para el estado y `go_router` para las rutas, con **redirección por rol**: ciudadano → Inicio, dev → Panel DEV, autoridad → Panel Autoridad.
- Carpetas:
  - `lib/core/` (tema, rutas, constantes, breakpoints)
  - `lib/widgets/` (HUD, barra lateral, tarjetas, botones, chips, etiquetas de riesgo, tablas, KPIs)
  - `lib/features/{auth, inicio, mapa, reporte, alertas, perfil, dev, autoridad}/` (cada una con `data/`, `models/`, `screens/`, `widgets/`)
- Datos: **repositorios falsos (mock)** con los mismos datos del diseño (Kennedy, Bosa, Ciudad Bolívar, Engativá, placas ABC12D, HGT567…), detrás de interfaces listas para conectar luego a una API (FastAPI + MongoDB en Render).
- Mapa: `flutter_map` + OpenStreetMap, con pines de hurto, zonas de calor, filtros Todas/Motos/Autos, búsqueda y "mi ubicación" (`geolocator`).

---

## 4. Plan de sprints (hazlos en orden)

| Sprint | Secciones de Figma | Incluye |
|---|---|---|
| **1** | Acceso + Inicio y mapa | Tema, componentes base, HUD y barras laterales, Splash, Loading, Login con rol, Crear cuenta, Recuperar contraseña, Permisos, Verificación de autoridad, Inicio, Menú lateral, Notificaciones, Mapa, Detalle de reporte (mapa), Emergencia SOS |
| **2** | Reportar hurto + Alertas | Pasos 1–3, Reporte enviado, Estado del reporte, Sin conexión, Alertas, Detalle de alerta, Configurar alertas |
| **3** | Perfil | Perfil, Editar perfil, Ajustes, Mis reportes (y estado vacío), Vehículos, Agregar vehículo, Zonas favoritas, Agregar zona, Privacidad y datos, Centro de ayuda |
| **4** | DEV | Panel DEV y sus 12 herramientas (Usuarios, Moderación, Autoridades, Zonas de riesgo, Notificaciones masivas, CAI y puntos, Analítica, Registros, Estado del servicio, Roles y permisos, Exportar datos, Sistema) |
| **5** | Autoridad | Panel Autoridad, Mapa de incidencias, Casos (tablero), Detalle del caso, Consulta de placas, Verificación, Actuaciones, Reportes oficiales |

**Al cerrar cada sprint:**
1. Corre `flutter analyze` y corrige todos los errores.
2. Compila `flutter build web` y `flutter build apk --debug`.
3. Haz commit y push a una rama `sprint-N` y luego fusiónala a `main`.
4. Actualiza `README.md` con lo hecho, cómo correrlo (`flutter run -d chrome` y en el emulador de Android) y las decisiones que tomaste.

Si una decisión no está definida en el diseño, elige la opción más simple, anótala en el README y sigue.
