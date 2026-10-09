import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_controller.dart';
import '../child/child_code_screen.dart';
import '../child/child_home_screen.dart';
import '../common/texts.dart';
import '../home/preview_home_screen.dart';
import '../intro/intro_flow_screen.dart';
import '../lighthouse/lighthouse_screen.dart';
import '../lighthouse/pin_screens.dart';
import 'welcome_screen.dart';

/// Wählt den Startbildschirm passend zur Sitzung: Willkommen, Leuchtturm
/// (mit PIN-Sperre) oder Kinderbereich.
///
/// Wechselt die Art der Sitzung, werden alle geöffneten Unterseiten
/// geschlossen, damit zum Beispiel nach dem Abmelden kein Leuchtturm-Bildschirm
/// offen bleibt.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> with WidgetsBindingObserver {
  SessionController? _session;
  Object? _lastKind;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AppScope.of(context).session;
    if (!identical(session, _session)) {
      _session?.removeListener(_onSessionChanged);
      _session = session..addListener(_onSessionChanged);
      _lastKind = _kindOf(session.state);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _session;
    if (session == null) return;
    if (state == AppLifecycleState.paused) session.appPaused();
    if (state == AppLifecycleState.resumed) session.appResumed();
  }

  /// Was auf dem Bildschirm grundsätzlich zu sehen ist. Ändert sich das,
  /// schließen wir alle Unterseiten.
  static Object _kindOf(SessionState state) => switch (state) {
    SessionParent(:final parent, :final unlocked) => (SessionParent, parent.hasPin, unlocked),
    SessionChild(:final child) => (SessionChild, child.id, child.onboardingCompleted),
    _ => state.runtimeType,
  };

  void _onSessionChanged() {
    final kind = _kindOf(_session!.state);
    if (kind != _lastKind) {
      _lastKind = kind;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _session!.state;
    return switch (state) {
      SessionLoading() => const Scaffold(body: Center(child: CircularProgressIndicator())),
      SessionOffline() => const PreviewHomeScreen(),
      SessionSignedOut() => const WelcomeScreen(),
      SessionChildUnlinked() => const ChildCodeScreen(),
      SessionChild(:final child) when !child.onboardingCompleted => IntroFlowScreen(
        key: ValueKey(child.id),
        state: state,
      ),
      SessionChild() => ChildHomeScreen(state: state),
      SessionParent(:final parent) when !parent.hasPin => const SetPinScreen(),
      SessionParent(:final unlocked) when !unlocked => PinGateScreen(state: state),
      SessionParent(:final parent) => LighthouseScreen(key: ValueKey(parent.id), parent: parent),
      SessionProblem() => _ProblemScreen(problem: state),
    };
  }
}

class _ProblemScreen extends StatelessWidget {
  const _ProblemScreen({required this.problem});

  final SessionProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    final theme = Theme.of(context);
    final noParent = problem.kind == SessionProblemKind.noParentAccount;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(noParent ? Icons.person_off_outlined : Icons.cloud_off_outlined, size: 64),
              const SizedBox(height: 16),
              if (noParent) ...[
                Text(l10n.problemNoParentTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.problemNoParentBody, textAlign: TextAlign.center),
              ] else
                Text(l10n.failure(problem.failure), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              if (!noParent) FilledButton(onPressed: session.retry, child: Text(l10n.retryButton)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => session.signOut(), child: Text(l10n.signOutButton)),
            ],
          ),
        ),
      ),
    );
  }
}
