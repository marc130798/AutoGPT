import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/taleria_theme.dart';
import 'admin_scope.dart';
import 'admin_texts.dart';
import 'screens/admin_gate.dart';

/// Adminbereich als eigene Web-App (CLAUDE.md Abschnitt 10), nicht Teil der Store-App.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.services});

  final AdminServices services;

  @override
  Widget build(BuildContext context) {
    return AdminScope(
      services: services,
      child: MaterialApp(
        title: AdminTexts.appTitle,
        debugShowCheckedModeBanner: false,
        theme: taleriaThemeForStage(1),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AdminGate(),
      ),
    );
  }
}
