import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conexión con Supabase.
///
/// Las claves llegan por `--dart-define` (o `--dart-define-from-file=config/supabase.json`):
/// `SUPABASE_URL` y la clave pública `SUPABASE_ANON_KEY` (sirve la "anon" o la "publishable"). Si faltan, la app usa los repositorios de ejemplo (mock),
/// así se puede seguir trabajando sin backend.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get habilitado => url.isNotEmpty && anonKey.isNotEmpty;

  static Future<void> iniciar() async {
    if (!habilitado) {
      debugPrint('Supabase sin configurar: se usan datos de ejemplo.');
      return;
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }
}

/// Cliente de Supabase (solo usar si [SupabaseConfig.habilitado]).
SupabaseClient get supa => Supabase.instance.client;

/// Archivos elegidos con image_picker que aún no se han subido a Storage.
/// La interfaz guarda solo la clave (texto) y el repositorio busca aquí los bytes al subir.
abstract final class ArchivosLocales {
  static final _archivos = <String, XFile>{};

  /// Registra un archivo y devuelve su clave única.
  static String registrar(XFile archivo) {
    final clave = '${DateTime.now().millisecondsSinceEpoch}_${archivo.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}';
    _archivos[clave] = archivo;
    return clave;
  }

  static XFile? obtener(String clave) => _archivos[clave];

  /// Nombre legible (sin el prefijo de tiempo).
  static String nombre(String clave) => clave.contains('_') ? clave.substring(clave.indexOf('_') + 1) : clave;

  /// Sube el archivo a `bucket/<uid>/<clave>` y devuelve la ruta guardada; si no está registrado devuelve la clave.
  static Future<String> subir(String bucket, String clave) async {
    final archivo = _archivos[clave];
    if (archivo == null) return clave;
    final uid = supa.auth.currentUser!.id;
    final ruta = '$uid/$clave';
    await supa.storage.from(bucket).uploadBinary(
          ruta,
          await archivo.readAsBytes(),
          fileOptions: FileOptions(contentType: archivo.mimeType ?? _tipo(clave), upsert: true),
        );
    _archivos.remove(clave);
    return ruta;
  }

  static String _tipo(String nombre) {
    final n = nombre.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }
}
