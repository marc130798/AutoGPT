import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../admin_texts.dart';
import '../data/admin_failure.dart';

/// Schmale Spalte in der Mitte, für Anmeldung und Zwei-Faktor.
class AdminNarrowPage extends StatelessWidget {
  const AdminNarrowPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AdminTexts.appTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: children),
        ),
      ),
    );
  }
}

/// Fehlermeldung in Korallrot.
class AdminErrorText extends StatelessWidget {
  const AdminErrorText(this.failure, {super.key});

  final AdminFailure failure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        AdminTexts.failure(failure),
        key: const ValueKey('admin-error'),
        style: TextStyle(color: context.palette.coral),
      ),
    );
  }
}

/// Ladekreis, Fehler oder Inhalt einer Seite.
class AdminLoadView extends StatelessWidget {
  const AdminLoadView({
    super.key,
    required this.loading,
    required this.error,
    required this.hasData,
    required this.onRetry,
    required this.builder,
  });

  final bool loading;
  final AdminFailure? error;
  final bool hasData;
  final VoidCallback onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (!hasData && loading) return const Center(child: CircularProgressIndicator());
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) AdminErrorText(error!),
            OutlinedButton(onPressed: onRetry, child: const Text(AdminTexts.reload)),
          ],
        ),
      );
    }
    return builder(context);
  }
}

/// Kopfzeile einer Seite mit „Neu laden“.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({super.key, required this.title, required this.onReload, this.trailing});

  final String title;
  final VoidCallback onReload;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ?trailing,
          IconButton(
            key: const ValueKey('admin-reload'),
            tooltip: AdminTexts.reload,
            onPressed: onReload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

/// Eine Kachel mit Zahl und Erklärung in der Übersicht.
class AdminNumberCard extends StatelessWidget {
  const AdminNumberCard({super.key, required this.title, required this.value, required this.detail});

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: context.palette.seaDeep)),
              const SizedBox(height: 4),
              Text(detail, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
