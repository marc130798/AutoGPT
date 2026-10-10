import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../services/lighthouse_controller.dart';
import '../common/busy_action.dart';
import '../common/texts.dart';

/// Leuchtturm: Abo-Stand, was kostenlos dabei ist und was das Abo bringt.
/// Kaufen geht erst mit RevenueCat (Schritt 9b). In der Testumgebung lässt
/// sich das Abo testweise schalten.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.controller});

  final LighthouseController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final sub = controller.subscription;
            final premium = sub.premium;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  key: const ValueKey('subscription-status'),
                  color: premium ? palette.success.withValues(alpha: 0.12) : null,
                  child: ListTile(
                    leading: Icon(
                      premium ? Icons.workspace_premium : Icons.sailing_outlined,
                      color: premium ? palette.success : null,
                    ),
                    title: Text(
                      premium
                          ? (sub.validUntil == null
                                ? l10n.subscriptionPremium
                                : l10n.subscriptionPremiumUntil(formatDate(sub.validUntil!)))
                          : l10n.subscriptionFree,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: sub.isTest ? Text(l10n.subscriptionTestNote) : Text(l10n.subscriptionAccountNote),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.subscriptionFreeHeading, style: theme.textTheme.titleMedium),
                for (final text in [
                  l10n.subscriptionFreeIslands,
                  l10n.subscriptionFreeChild,
                  l10n.subscriptionFreeBudget,
                ])
                  ListTile(dense: true, leading: const Icon(Icons.check), title: Text(text)),
                const SizedBox(height: 8),
                Text(l10n.subscriptionPremiumHeading, style: theme.textTheme.titleMedium),
                for (final text in [l10n.subscriptionPremiumIslands, l10n.subscriptionPremiumChildren])
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.star_outline, color: palette.gold),
                    title: Text(text),
                  ),
                const SizedBox(height: 16),
                if (!premium) ...[
                  // Kaufen kommt mit RevenueCat (Schritt 9b), bis dahin ausgegraut.
                  FilledButton(
                    key: const ValueKey('subscription-buy'),
                    onPressed: null,
                    child: Text(l10n.subscriptionBuy),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.subscriptionBuySoon, style: theme.textTheme.bodySmall),
                ],
                if (sub.testPurchases) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      key: const ValueKey('test-premium'),
                      value: sub.premium && sub.isTest,
                      title: Text(l10n.subscriptionTestSwitch),
                      subtitle: Text(l10n.subscriptionTestHint),
                      onChanged: (active) => runWithFeedback(context, () => controller.setTestPremium(active: active)),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
