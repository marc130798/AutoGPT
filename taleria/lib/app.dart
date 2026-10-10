import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/config/orientation_policy.dart';
import 'core/theme/taleria_palette.dart';
import 'core/theme/taleria_theme.dart';
import 'features/common/hide_hints_on_push.dart';
import 'features/start/session_gate.dart';
import 'l10n/app_localizations.dart';

class TaleriaApp extends StatefulWidget {
  const TaleriaApp({super.key, required this.services});

  final AppServices services;

  @override
  State<TaleriaApp> createState() => _TaleriaAppState();
}

class _TaleriaAppState extends State<TaleriaApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final _hideHints = HideHintsOnPush(_messengerKey);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: MaterialApp(
        scaffoldMessengerKey: _messengerKey,
        navigatorObservers: [_hideHints],
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        // Gebaut wird nur Stufe 1. Sobald es Kinder-Profile gibt, kommt die
        // Stufe aus dem Profil.
        theme: taleriaThemeForStage(1),
        locale: const Locale('de'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => _TabletFrame(child: child ?? const SizedBox.shrink()),
        home: const SessionGate(),
      ),
    );
  }
}

/// Auf breiten Bildschirmen (Tablet quer) steht der Inhalt in der Mitte,
/// links und rechts ist Meer.
class _TabletFrame extends StatelessWidget {
  const _TabletFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= tabletShortestSide * 1.2) return child;
    return ColoredBox(
      color: context.palette.sea,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: tabletShortestSide * 1.2),
          child: child,
        ),
      ),
    );
  }
}
