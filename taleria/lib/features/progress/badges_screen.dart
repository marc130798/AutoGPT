import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/family_models.dart';
import '../../domain/progress_models.dart';
import '../../l10n/app_localizations.dart';
import '../common/texts.dart';

/// Orden-Sammlung des Kindes: verdiente Orden leuchten, die anderen sind
/// blass und warten noch („Noch nicht gefunden“).
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key, required this.childId});

  final String childId;

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Future<List<BadgeInfo>> _badges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _badges = AppScope.of(context).progress!.fetchBadges(widget.childId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesTitle)),
      body: SafeArea(
        child: FutureBuilder<List<BadgeInfo>>(
          future: _badges,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.failure(error is AppFailure ? error.kind : FailureKind.unknown)),
                ),
              );
            }
            final badges = snapshot.data;
            if (badges == null) return const Center(child: CircularProgressIndicator());
            final earned = badges.where((b) => b.earned).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (earned == 0) ...[
                  Text(l10n.badgesEmpty, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                ],
                for (final badge in badges) _BadgeTile(badge: badge),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final BadgeInfo badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey('badge-${badge.slug}'),
      child: ListTile(
        minTileHeight: 80,
        leading: Opacity(
          opacity: badge.earned ? 1 : 0.3,
          child: ClipOval(child: TaleriaAsset(badge.assetKey, width: 56, height: 56)),
        ),
        title: Text(badge.title),
        subtitle: Text(badge.earned ? l10n.badgeEarnedOn(formatDate(badge.earnedAt!)) : l10n.badgeNotYet),
        trailing: badge.earned ? null : const Icon(Icons.lock_outline),
      ),
    );
  }
}
