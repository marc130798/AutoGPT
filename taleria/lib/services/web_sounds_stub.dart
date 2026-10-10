import '../core/assets/asset_manifest.dart';
import '../data/local_settings.dart';
import 'sounds.dart';

/// Außerhalb des Browsers gibt es keine [WebSounds]; dort spielt `AudioSounds`.
Sounds? createWebSounds({
  required TaleriaAssetManifest manifest,
  required List<String> effects,
  LocalSettings? settings,
}) => null;
