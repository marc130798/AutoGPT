import 'package:flutter/material.dart';

/// Blendet den Hinweis unten (SnackBar) aus, sobald sich eine neue Seite öffnet.
/// Sonst verdeckt ein Hinweis der alten Seite für ein paar Sekunden die Knöpfe
/// der neuen (zum Beispiel „Weiter“ in einer Station), und Kinder tippen ins Leere.
class HideHintsOnPush extends NavigatorObserver {
  HideHintsOnPush(this.messengerKey);

  final GlobalKey<ScaffoldMessengerState> messengerKey;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Nur echte Seiten, nicht Dialoge oder Menüs.
    if (route is PageRoute) messengerKey.currentState?.hideCurrentSnackBar();
  }
}
