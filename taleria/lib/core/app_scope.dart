import 'dart:math';

import 'package:flutter/widgets.dart';

import '../data/budget_repository.dart';
import '../data/child_repository.dart';
import '../data/content_repository.dart';
import '../data/family_repository.dart';
import '../data/local_settings.dart';
import '../services/session_controller.dart';
import '../services/sounds.dart';
import 'assets/asset_manifest.dart';
import 'assets/asset_repository.dart';
import 'backend/backend.dart';
import 'config/app_config.dart';

/// Alles, was die App zum Laufen braucht, an einer Stelle.
class AppServices {
  AppServices({
    required this.config,
    required this.assets,
    required this.manifest,
    required this.backendHealth,
    required this.session,
    required this.family,
    required this.children,
    required this.content,
    required this.progress,
    required this.settings,
    required this.budget,
    this.manifestError,
    this.sceneMotion = true,
    Random? random,
    Sounds? sounds,
  }) : random = random ?? _defaultRandom,
       sounds = sounds ?? Sounds();

  static final _defaultRandom = Random();

  final AppConfig config;
  final AssetRepository assets;
  final TaleriaAssetManifest manifest;
  final BackendHealthCheck backendHealth;

  /// Wer benutzt die App gerade (Eltern, Kind, niemand)?
  final SessionController session;

  /// `null`, wenn kein Server eingerichtet ist.
  final FamilyRepository? family;

  /// Avatar, Schiff, Wunschschätze, Intro. `null` ohne Server.
  final ChildRepository? children;

  /// Inseln, Stationen und Fragen. `null` ohne Server.
  final ContentRepository? content;

  /// Fortschritt lesen und Stationen abgeben. `null` ohne Server.
  final ProgressRepository? progress;

  /// Heuer, Aufträge, Truhen und Wunschschätze. `null` ohne Server.
  final BudgetRepository? budget;

  /// Kleine Einstellungen auf diesem Gerät.
  final LocalSettings settings;

  /// Musik im Hauptmenü und kurze Töne. Ohne Angabe still (Tests).
  final Sounds sounds;

  /// Zufall für die Quiz-Auswahl (in Tests fest vorgegeben).
  final Random random;

  /// Bewegte Szenen (Wellen, Wolken, Nebel-Start, segelndes Schiff). In Tests
  /// aus, damit die Bildschirme zur Ruhe kommen. Im Gerät gilt zusätzlich
  /// „Bewegung reduzieren“.
  final bool sceneMotion;

  /// Gesetzt, wenn das Manifest nicht geladen werden konnte. Die App läuft
  /// dann mit grauen Platzhaltern weiter.
  final Object? manifestError;
}

/// Gibt [AppServices] an alle Bildschirme weiter.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope fehlt über diesem Widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
