import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';

// Ehrenwand für Orden und Vitrine für Funde (Marcs Wunsch am 20.10.2026):
// drei Plätze je Reihe mit großem Bild statt einer Liste.

/// Ein Platz an der Ehrenwand oder in der Vitrine: großes Bild, Name, darunter
/// das Datum. Noch nicht gefunden: blass mit Schloss. Antippen zeigt das Bild groß.
class ShowcaseTile extends StatelessWidget {
  const ShowcaseTile({
    super.key,
    required this.assetKey,
    required this.title,
    required this.caption,
    required this.earned,
  });

  final String assetKey;
  final String title;

  /// Zum Beispiel „Verliehen am 10.10.2026“ oder „Noch nicht gefunden“.
  final String caption;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return MergeSemantics(
      child: Material(
        color: palette.paper.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: earned ? palette.gold : const Color(0xFFE2C27A).withValues(alpha: 0.7),
            width: earned ? 2.5 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLarge(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: earned ? 1 : 0.3, child: TaleriaAsset(assetKey, width: 84, height: 84)),
                      if (!earned)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: palette.paper,
                            child: Icon(Icons.lock_outline, size: 16, color: palette.ink),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _fitWords(
                    context,
                    title,
                    theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                    _TextWidth.of(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(caption, textAlign: TextAlign.center, maxLines: 2, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lange Wörter wie „Meistertauscher“ nicht mitten im Wort trennen: Passt
  /// das breiteste Wort nicht in die Zeile, wird die Schrift etwas kleiner.
  static TextStyle _fitWords(BuildContext context, String text, TextStyle style, double? maxWidth) {
    if (maxWidth == null || style.fontSize == null) return style;
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = max(widest, painter.width);
      painter.dispose();
    }
    if (widest <= maxWidth) return style;
    return style.copyWith(fontSize: style.fontSize! * maxWidth / widest * 0.97);
  }

  void _showLarge(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('showcase-large'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(opacity: earned ? 1 : 0.3, child: TaleriaAsset(assetKey, width: 200, height: 200)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(caption, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }
}

/// Drei Plätze je Reihe, alle in einer Reihe gleich hoch.
class ShowcaseGrid extends StatelessWidget {
  const ShowcaseGrid({super.key, required this.children});

  final List<Widget> children;

  static const _perRow = 3;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _TextWidth(
        // Platz für Text in einem Platz: Breite ohne Abstände und Innenrand.
        width: (constraints.maxWidth - _gap * (_perRow - 1)) / _perRow - 12,
        child: _rows(),
      ),
    );
  }

  Widget _rows() {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += _perRow)
          Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < start + _perRow; i++) ...[
                    if (i > start) const SizedBox(width: _gap),
                    Expanded(child: i < children.length ? children[i] : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Gibt den Plätzen weiter, wie breit ihr Text sein darf.
class _TextWidth extends InheritedWidget {
  const _TextWidth({required this.width, required super.child});

  final double width;

  static double? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_TextWidth>()?.width;

  @override
  bool updateShouldNotify(_TextWidth oldWidget) => oldWidget.width != width;
}
