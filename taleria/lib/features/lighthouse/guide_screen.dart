import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';

/// Ein Kapitel der Anleitung für Eltern.
typedef GuideChapter = ({String id, IconData icon, String title, String body});

/// Alle Kapitel in der Reihenfolge, in der Eltern sie beim Start brauchen.
List<GuideChapter> guideChapters(AppLocalizations l10n) => [
  (id: 'about', icon: Icons.sailing_rounded, title: l10n.guideAboutTitle, body: l10n.guideAboutBody),
  (id: 'connect', icon: Icons.phonelink_lock_rounded, title: l10n.guideConnectTitle, body: l10n.guideConnectBody),
  (id: 'pace', icon: Icons.air_rounded, title: l10n.guidePaceTitle, body: l10n.guidePaceBody),
  (id: 'station', icon: Icons.auto_stories_rounded, title: l10n.guideStationTitle, body: l10n.guideStationBody),
  (id: 'progress', icon: Icons.military_tech_rounded, title: l10n.guideProgressTitle, body: l10n.guideProgressBody),
  (id: 'money', icon: Icons.savings_rounded, title: l10n.guideMoneyTitle, body: l10n.guideMoneyBody),
  (id: 'tasks', icon: Icons.task_alt_rounded, title: l10n.guideTasksTitle, body: l10n.guideTasksBody),
  (id: 'reward', icon: Icons.emoji_events_rounded, title: l10n.guideRewardTitle, body: l10n.guideRewardBody),
  (id: 'report', icon: Icons.insights_rounded, title: l10n.guideReportTitle, body: l10n.guideReportBody),
  (id: 'logbooks', icon: Icons.menu_book_rounded, title: l10n.guideLogbooksTitle, body: l10n.guideLogbooksBody),
  (id: 'sound', icon: Icons.volume_up_rounded, title: l10n.guideSoundTitle, body: l10n.guideSoundBody),
  (id: 'safety', icon: Icons.shield_rounded, title: l10n.guideSafetyTitle, body: l10n.guideSafetyBody),
];

/// Leuchtturm: Anleitung für Eltern (Marcs Wunsch am 16.11.2026). Jedes Thema
/// klappt auf, damit die Seite kurz bleibt; das erste ist offen.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final chapters = guideChapters(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      // Kein ListView: Die Seite ist kurz, so sind alle Themen gleich gebaut.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.guideIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            for (final (i, c) in chapters.indexed)
              Card(
                key: ValueKey('guide-${c.id}'),
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: i == 0,
                  leading: CircleAvatar(
                    backgroundColor: palette.gold.withValues(alpha: 0.25),
                    child: Icon(c.icon, color: palette.seaDeep),
                  ),
                  title: Text(c.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedAlignment: Alignment.centerLeft,
                  children: [Text(c.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45))],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
