import 'package:flutter/material.dart';

import '../admin_scope.dart';
import '../admin_texts.dart';
import '../services/admin_session.dart';
import 'admin_home_screen.dart';
import 'admin_login_screens.dart';
import 'admin_widgets.dart';

/// Zeigt je nach Stand der Anmeldung die passende Seite.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AdminScope.of(context).session;
    if (session == null) {
      return const AdminNarrowPage(
        children: [
          Text(AdminTexts.noBackendTitle, style: TextStyle(fontSize: 22)),
          SizedBox(height: 12),
          Text(AdminTexts.noBackendBody),
        ],
      );
    }
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => switch (session.stage) {
        AdminStage.loading => const Scaffold(body: Center(child: CircularProgressIndicator())),
        AdminStage.signedOut => AdminLoginScreen(session: session),
        AdminStage.enrollMfa => AdminMfaSetupScreen(session: session),
        AdminStage.verifyMfa => AdminMfaVerifyScreen(session: session),
        AdminStage.notAdmin => AdminNotAdminScreen(session: session),
        AdminStage.ready => AdminHomeScreen(session: session),
      },
    );
  }
}
