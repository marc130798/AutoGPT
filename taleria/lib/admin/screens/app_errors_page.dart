import 'package:flutter/material.dart';

import '../admin_scope.dart';
import '../admin_texts.dart';
import '../domain/admin_models.dart';
import '../services/admin_loader.dart';
import 'admin_widgets.dart';

/// Fehlerprotokoll der App für die Beta (nur owner).
class AppErrorsPage extends StatefulWidget {
  const AppErrorsPage({super.key});

  @override
  State<AppErrorsPage> createState() => _AppErrorsPageState();
}

class _AppErrorsPageState extends State<AppErrorsPage> {
  AdminLoader<List<AppErrorInfo>>? _loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AdminScope.of(context).repository!;
    _loader ??= AdminLoader(() => repository.appErrors())..load();
  }

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loader = _loader!;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: loader,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(title: AdminTexts.appErrors, onReload: loader.load),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(AdminTexts.appErrorsNote, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: AdminLoadView(
              loading: loader.loading,
              error: loader.error,
              hasData: loader.data != null,
              onRetry: loader.load,
              builder: (context) {
                final errors = loader.data!;
                if (errors.isEmpty) return const Center(child: Text(AdminTexts.appErrorsEmpty));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final e in errors)
                      Card(
                        child: ExpansionTile(
                          title: Text(e.error, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(AdminTexts.appErrorLine(e)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                '${e.error}\n\n${e.stack ?? ''}',
                                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
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
