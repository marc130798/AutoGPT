import 'package:flutter/material.dart';

import '../admin_scope.dart';
import '../admin_texts.dart';
import '../domain/admin_models.dart';
import '../services/admin_loader.dart';
import 'admin_widgets.dart';

/// Zahlen zu Familien, Kindern und Abos (nur owner).
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  AdminLoader<AdminOverview>? _loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loader ??= AdminLoader(AdminScope.of(context).repository!.overview)..load();
  }

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loader = _loader!;
    return ListenableBuilder(
      listenable: loader,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(title: AdminTexts.overview, onReload: loader.load),
          Expanded(
            child: AdminLoadView(
              loading: loader.loading,
              error: loader.error,
              hasData: loader.data != null,
              onRetry: loader.load,
              builder: (context) {
                final o = loader.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (loader.error != null) AdminErrorText(loader.error!),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AdminNumberCard(
                          title: AdminTexts.families,
                          value: '${o.families}',
                          detail: AdminTexts.newFamilies(o.familiesNew7d, o.familiesNew28d),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.children,
                          value: '${o.children}',
                          detail: AdminTexts.onboarded(o.childrenOnboarded),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.activeChildren,
                          value: '${o.childrenActive7d}',
                          detail: AdminTexts.active(o.childrenActive7d, o.childrenActive28d),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.subscriptions,
                          value: '${o.premiumFamilies}',
                          detail: AdminTexts.premium(o.premiumStore, o.premiumManual, o.premiumTest),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.returnWeek1,
                          value: AdminTexts.percentOrDash(
                            AdminOverview.percent(o.returnWeek1Returned, o.returnWeek1Cohort),
                          ),
                          detail: AdminTexts.returned(o.returnWeek1Returned, o.returnWeek1Cohort, 14),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.returnWeek4,
                          value: AdminTexts.percentOrDash(
                            AdminOverview.percent(o.returnWeek4Returned, o.returnWeek4Cohort),
                          ),
                          detail: AdminTexts.returned(o.returnWeek4Returned, o.returnWeek4Cohort, 35),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.appErrors7d,
                          value: '${o.appErrors7d}',
                          detail: AdminTexts.appErrorsDetail(o.appErrors7d),
                        ),
                        AdminNumberCard(
                          title: AdminTexts.budget,
                          value: '${o.childrenWithAllowance}',
                          detail: AdminTexts.budgetUsage(o.childrenWithAllowance, o.tasksApproved28d),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(AdminTexts.overviewNote, style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
