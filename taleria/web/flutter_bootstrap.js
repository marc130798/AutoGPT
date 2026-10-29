{{flutter_js}}
{{flutter_build_config}}

// Fehlt einer Schrift ein Zeichen, sucht Flutter Ersatzschriften standardmäßig bei
// Google (fonts.gstatic.com). Taleria bringt alle Schriften selbst mit (pubspec.yaml),
// darum zeigt die Adresse auf den eigenen Server, nie auf einen fremden Dienst.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    fontFallbackBaseUrl: 'assets/fonts/ersatz/',
  },
});
