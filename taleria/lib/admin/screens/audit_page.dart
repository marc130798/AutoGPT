import 'package:flutter/material.dart';

import '../admin_scope.dart';
import '../admin_texts.dart';
import '../domain/admin_models.dart';
import '../services/admin_loader.dart';
import 'admin_widgets.dart';

/// Letzte Einträge im Audit-Log (nur owner). Das Protokoll lässt sich nicht ändern.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  AdminLoader<List<AuditEntry>>? _loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AdminScope.of(context).repository!;
    _loader ??= AdminLoader(() => repository.auditLog())..load();
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
          AdminPageHeader(title: AdminTexts.auditLog, onReload: loader.load),
          Expanded(
            child: AdminLoadView(
              loading: loader.loading,
              error: loader.error,
              hasData: loader.data != null,
              onRetry: loader.load,
              builder: (context) {
                final entries = loader.data!;
                if (entries.isEmpty) return const Center(child: Text(AdminTexts.auditEmpty));
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      title: Text('${AdminTexts.auditAction(e.action)}${AdminTexts.auditTarget(e)}'),
                      subtitle: Text('${AdminTexts.dateTime(e.createdAt)} · ${AdminTexts.auditWho(e)}\n${e.reason}'),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
