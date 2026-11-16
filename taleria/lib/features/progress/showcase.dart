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
    this.wall = false,
    this.glow = false,
  });

  /// Wie an einer Wand: ohne Kasten, das Bild hängt an einem Nagel, der Name
  /// steht auf einem Messingschild (Orden).
  final bool wall;

  /// Leuchtet golden (gerade aufgehängt).
  final bool glow;

  final String assetKey;
  final String title;

  /// Zum Beispiel „Verliehen am 10.10.2026“ oder „Noch nicht gefunden“.
  final String caption;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    if (wall) return _buildWall(context);
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

  Widget _buildWall(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLarge(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: glow ? const [BoxShadow(color: Color(0xAAFFD66B), blurRadius: 24, spreadRadius: 2)] : const [],
          ),
          child: Column(
            children: [
              // Nagel und Band: Der Orden hängt an der Wand.
              SizedBox(
                height: 22,
                width: 60,
                child: CustomPaint(painter: _NailPainter(earned: earned)),
              ),
              SizedBox(
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(opacity: earned ? 1 : 0.45, child: TaleriaAsset(assetKey, width: 88, height: 88)),
                    if (!earned)
                      Positioned(
                        right: 4,
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
              const SizedBox(height: 6),
              // Messingschild mit dem Namen.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: earned
                        ? const [Color(0xFFF6DE8D), Color(0xFFD1A845)]
                        : const [Color(0xCCE9DFC8), Color(0xCCCFC3A8)],
                  ),
                  border: Border.all(color: earned ? const Color(0xFF8A6A1E) : const Color(0x998A7A5A)),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _fitWords(
                    context,
                    title,
                    theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF3B2A08)),
                    // Schild mit Rand und Innenabstand: etwas schmaler als der Platz.
                    (_TextWidth.of(context) ?? 0) - 14,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFFF4DC),
                  fontWeight: FontWeight.w700,
                  shadows: const [Shadow(color: Color(0xCC000000), offset: Offset(0, 1), blurRadius: 3)],
                ),
              ),
            ],
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

/// Messingnagel mit zwei Bändern nach unten zum Orden.
class _NailPainter extends CustomPainter {
  _NailPainter({required this.earned});

  final bool earned;

  @override
  void paint(Canvas canvas, Size size) {
    final nail = Offset(size.width / 2, 5);
    final band = Paint()
      ..color = earned ? const Color(0xFF24476B) : const Color(0x6624476B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(nail, Offset(size.width * 0.3, size.height), band)
      ..drawLine(nail, Offset(size.width * 0.7, size.height), band)
      ..drawCircle(nail, 5, Paint()..color = const Color(0xFF8A6A1E))
      ..drawCircle(nail.translate(-1, -1), 2.5, Paint()..color = const Color(0xFFFFE9A8));
  }

  @override
  bool shouldRepaint(_NailPainter old) => old.earned != earned;
}
