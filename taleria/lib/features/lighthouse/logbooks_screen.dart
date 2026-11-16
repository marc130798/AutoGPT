import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/logbooks.dart';
import '../../l10n/app_localizations.dart';
import '../../services/open_file_stub.dart' if (dart.library.js_interop) '../../services/open_file_web.dart';

/// Leuchtturm: die Logbücher zum Ausdrucken, je Insel ein Heft mit
/// Vorschaubild. „PDF öffnen“ öffnet die Datei in einem neuen Tab, von dort
/// drucken oder speichern die Eltern sie. Nur im Elternbereich, denn im
/// Kinderbereich gibt es keine Links nach außen (CLAUDE.md).
class LogbooksScreen extends StatelessWidget {
  const LogbooksScreen({super.key, this.open = openFileNextToApp});

  /// Öffnet eine Datei neben der App; `false`, wenn das hier nicht geht.
  final bool Function(String path) open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.logbooksTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.logbooksIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          for (final book in logbooks)
            _LogbookCard(
              book: book,
              onOpen: () {
                if (open(book.path)) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(l10n.logbooksOnlyWeb)));
              },
            ),
        ],
      ),
    );
  }
}

class _LogbookCard extends StatelessWidget {
  const _LogbookCard({required this.book, required this.onOpen});

  final Logbook book;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.seaDeep.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Die erste Seite des Hefts als kleines Bild.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.seaDeep.withValues(alpha: 0.2)),
                boxShadow: const [BoxShadow(color: Color(0x22081C30), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TaleriaAsset('logbook.${book.island}', width: 84, height: 119, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: theme.textTheme.titleLarge),
                  Text(l10n.logbooksPages, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: ValueKey('logbook-open-${book.island}'),
                    onPressed: onOpen,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l10n.logbooksOpen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
