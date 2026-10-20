import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/taleria_palette.dart';
import '../../l10n/app_localizations.dart';

/// Erklärung oben auf einer Menü-Seite (Talo oder Tala erklären die Seite).
/// Beim ersten Besuch steht sie offen da. Danach ist sie zugeklappt, und ein
/// kleiner „?“-Knopf klappt sie auf und wieder zu (Marcs Wunsch am
/// 20.10.2026). Gemerkt wird das je Kind auf diesem Gerät.
class PageIntro extends StatefulWidget {
  const PageIntro({super.key, required this.childId, required this.page, required this.children});

  final String childId;

  /// Name der Seite, zum Beispiel `tasks`.
  final String page;

  /// Die Sprechblasen der Erklärung.
  final List<Widget> children;

  @override
  State<PageIntro> createState() => _PageIntroState();
}

class _PageIntroState extends State<PageIntro> {
  /// Schon einmal gesehen? `null`, solange das noch lädt.
  bool? _seen;
  bool _open = false;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seen != null || _loading) return;
    _loading = true;
    final settings = AppScope.of(context).settings;
    settings.pageIntroSeen(widget.childId, widget.page).catchError((Object _) => false).then((seen) {
      if (!mounted) return;
      setState(() {
        _seen = seen;
        _open = !seen;
      });
      if (!seen) settings.setPageIntroSeen(widget.childId, widget.page).ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final seen = _seen;
    if (seen == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (seen)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: _open ? 8 : 0),
                child: Tooltip(
                  message: _open ? l10n.pageIntroHide : l10n.pageIntroShow,
                  child: Material(
                    key: const ValueKey('page-intro-help'),
                    color: palette.paper.withValues(alpha: 0.95),
                    shape: CircleBorder(side: BorderSide(color: palette.gold, width: 2)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() => _open = !_open),
                      child: SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          _open ? Icons.close_rounded : Icons.question_mark_rounded,
                          color: palette.ink,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_open) ...widget.children,
        ],
      ),
    );
  }
}
