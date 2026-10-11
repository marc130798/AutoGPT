import 'package:flutter/material.dart';

import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';

/// Bilder der Bildergeschichte, die die App selbst zeichnet. Bei Münzen,
/// Scheinen und Beträgen kommt es auf genaue Zahlen an, und die malt Gemini
/// nicht zuverlässig. In den Inhaltsdateien: `"bild": "drawing:<name>"`.
const storyDrawingPrefix = 'drawing:';

/// Alle Zeichnungen, die es gibt (gleiche Liste in tool/content/content_model.dart).
const storyDrawings = {
  'euro_coins',
  'cents_to_euro',
  'comma_amount',
  'euro_notes',
  'big_coins_first',
  'nets_year',
  'nets_cost',
};

/// Eine Zeichnung im Format 4:3, passt sich der Größe an.
class StoryDrawing extends StatelessWidget {
  const StoryDrawing({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (background, content) = switch (name) {
      'euro_coins' => (
        _velvet,
        _coinRows([
          const [1, 2, 5],
          const [10, 20, 50],
          const [100, 200],
        ]),
      ),
      'cents_to_euro' => (
        _velvet,
        _equation([
          const EuroCoin(cents: 50, scale: 3.6),
          _sign('+'),
          const EuroCoin(cents: 50, scale: 3.6),
          _sign('='),
          const EuroCoin(cents: 100, scale: 3.6),
        ]),
      ),
      'comma_amount' => (_velvet, _commaAmount(l10n, 205)),
      'euro_notes' => (_wood, const _NoteFan()),
      'big_coins_first' => (_wood, _bigFirst(l10n)),
      'nets_year' => (_velvet, _netsYear(l10n)),
      'nets_cost' => (_velvet, _netsCost(l10n)),
      _ => (_velvet, const SizedBox.shrink()),
    };
    // Material sorgt für die Schrift der App, egal wo die Zeichnung liegt.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        key: ValueKey('story-drawing-$name'),
        decoration: BoxDecoration(gradient: background),
        child: Padding(
          padding: const EdgeInsets.all(12),
          // Gezeichnet für 400 × 300 Punkte, dann passend verkleinert.
          child: FittedBox(
            child: SizedBox(width: 400, height: 300, child: Center(child: content)),
          ),
        ),
      ),
    );
  }

  static const _velvet = RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.1,
    colors: [Color(0xFF2E5C8A), Color(0xFF173A5E), Color(0xFF0E2640)],
  );

  static const _wood = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB98552), Color(0xFF94643A), Color(0xFF7A4F2C)],
  );

  static Widget _coinRows(List<List<int>> rows) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (final row in rows)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final cents in row)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: EuroCoin(cents: cents),
              ),
          ],
        ),
    ],
  );

  static Widget _sign(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
    ),
  );

  static Widget _equation(List<Widget> parts) => Row(mainAxisAlignment: MainAxisAlignment.center, children: parts);

  /// Vor dem Komma stehen die Euro, dahinter die Cent: 2 € und 5 ct sind 2,05 €.
  /// Euro und Cent haben je eine Farbe, in den Münzen und im Betrag.
  static Widget _commaAmount(AppLocalizations l10n, int cents) {
    const euroColor = Color(0xFF2F6DB5);
    const centColor = Color(0xFFC0473F);
    final euros = cents ~/ 100;
    final rest = cents % 100;
    Widget part(int coin, String caption, Color color) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EuroCoin(cents: coin, scale: 3.2),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Text(
            caption,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            part(euros * 100, l10n.coinEuros(euros), euroColor),
            _sign('+'),
            part(rest, l10n.coinCents(rest), centColor),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 44, height: 1.1, fontWeight: FontWeight.w900, color: Color(0xFF3B2A18)),
              children: [
                TextSpan(
                  text: '$euros',
                  style: const TextStyle(color: euroColor),
                ),
                const TextSpan(text: ','),
                TextSpan(
                  text: rest.toString().padLeft(2, '0'),
                  style: const TextStyle(color: centColor),
                ),
                // Geschütztes Leerzeichen wie in formatCents.
                const TextSpan(text: '\u00A0€'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Ein Schild auf Papier, zum Beispiel „billig · hält 1 Monat“.
  static Widget _chip(String text, {Color color = const Color(0xFF173A5E), double size = 16}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color),
    ),
  );

  /// Für ein Jahr: 12 billige Netze (je ein Monat) oder ein gutes Netz.
  static Widget _netsYear(AppLocalizations l10n) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(l10n.drawingCheapNet, size: 14),
            const SizedBox(height: 10),
            // Drei Reihen zu je vier Netzen: ein Netz pro Monat.
            SizedBox(
              width: 4 * 34 + 3 * 8,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (var month = 1; month <= 12; month++)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FishingNet(size: 34),
                        Text(
                          '$month',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chip(l10n.drawingGoodNet, size: 14),
            const SizedBox(height: 14),
            const FishingNet(size: 120, good: true),
          ],
        ),
      ),
    ],
  );

  /// 12 billige Netze zu 5 Taler kosten 60 Taler, das gute Netz nur 20.
  static Widget _netsCost(AppLocalizations l10n) {
    // Passt eine Zeile nicht, wird sie kleiner statt abgeschnitten.
    Widget row(Widget net, int count, int price, Color total, {bool best = false}) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 70, child: Center(child: net)),
          const SizedBox(width: 6),
          _chip('$count × ${l10n.drawingTaler(price)}', size: 18),
          _sign('='),
          _chip(l10n.drawingTaler(count * price), color: total, size: 24),
          if (best) ...[const SizedBox(width: 6), const Icon(Icons.check_circle, color: Color(0xFF7BD389), size: 34)],
        ],
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        row(const FishingNet(size: 54), 12, 5, const Color(0xFFC0473F)),
        row(const FishingNet(size: 64, good: true), 1, 20, const Color(0xFF2E7D4F), best: true),
      ],
    );
  }

  /// Ein Betrag mit möglichst wenigen Münzen: erst die großen.
  static Widget _bigFirst(AppLocalizations l10n) {
    const coins = [200, 50, 20, 10];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, cents) in coins.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF173A5E)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    EuroCoin(cents: cents, scale: 3.4),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Text(
            '= ${formatCents(coins.reduce((a, b) => a + b))}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF173A5E)),
          ),
        ),
      ],
    );
  }
}

/// Eine Euro-Münze in ungefähr echter Größe und Farbe: 1, 2, 5 Cent Kupfer,
/// 10, 20, 50 Cent Gold, 1 und 2 Euro zweifarbig.
class EuroCoin extends StatelessWidget {
  const EuroCoin({super.key, required this.cents, this.scale = 4});

  final int cents;

  /// Punkte pro Millimeter.
  final double scale;

  /// Durchmesser in Millimetern (echte Münzen).
  static const _mm = {1: 16.25, 2: 18.75, 5: 21.25, 10: 19.75, 20: 22.25, 50: 24.25, 100: 23.25, 200: 25.75};

  static const _copper = [Color(0xFFF2B98A), Color(0xFFC07A45), Color(0xFF8A4F22)];
  static const _gold = [Color(0xFFFFF0B0), Color(0xFFE2BC4E), Color(0xFFA9832A)];
  static const _silver = [Color(0xFFFFFFFF), Color(0xFFCFCFCF), Color(0xFF8E8E8E)];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = (_mm[cents] ?? 22) * scale;
    final euro = cents >= 100;
    final (outer, inner) = switch (cents) {
      100 => (_gold, _silver),
      200 => (_silver, _gold),
      < 10 => (_copper, null),
      _ => (_gold, null),
    };
    RadialGradient shine(List<Color> c) =>
        RadialGradient(center: const Alignment(-0.35, -0.45), radius: 0.95, colors: c, stops: const [0, 0.55, 1]);
    return Semantics(
      label: euro ? l10n.coinEuros(cents ~/ 100) : l10n.coinCents(cents),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: shine(outer),
          border: Border.all(color: outer.last, width: size * 0.035),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(2, 3))],
        ),
        child: Center(
          child: Container(
            width: size * 0.66,
            height: size * 0.66,
            decoration: inner == null
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: shine(inner),
                    border: Border.all(color: inner.last.withValues(alpha: 0.6)),
                  ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${euro ? cents ~/ 100 : cents}',
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3B2A18),
                      ),
                    ),
                    Text(
                      euro ? l10n.drawingEuro : l10n.drawingCent,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF3B2A18)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Euro-Scheine 5, 10, 20 und 50, aufgefächert: je größer der Wert, desto größer der Schein.
class _NoteFan extends StatelessWidget {
  const _NoteFan();

  @override
  Widget build(BuildContext context) {
    const notes = [5, 10, 20, 50];
    return SizedBox(
      width: 380,
      height: 270,
      child: Stack(
        children: [
          for (final (i, euros) in notes.indexed)
            Positioned(
              left: 8 + i * 52.0,
              top: 8 + i * 42.0,
              child: Transform.rotate(
                angle: -0.08 + i * 0.05,
                child: EuroNote(euros: euros),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ein Euro-Schein in seiner Farbe, mit großem Wert und Torbogen.
class EuroNote extends StatelessWidget {
  const EuroNote({super.key, required this.euros});

  final int euros;

  /// Farbe (dunkel, hell) und Breite in Millimetern (echte Scheine).
  static const _look = {
    5: (Color(0xFF7D8A8F), Color(0xFFD7DDDF), 120.0),
    10: (Color(0xFFC0473F), Color(0xFFF4C2B8), 127.0),
    20: (Color(0xFF3F6FB5), Color(0xFFBFD5F2), 133.0),
    50: (Color(0xFFD9772A), Color(0xFFF8D2A8), 140.0),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (dark, light, mm) = _look[euros] ?? (const Color(0xFF7D8A8F), const Color(0xFFD7DDDF), 120.0);
    final width = mm * 1.5;
    final height = width * 0.52;
    final number = TextStyle(fontSize: height * 0.36, height: 1, fontWeight: FontWeight.w900, color: dark);
    return Semantics(
      label: l10n.coinEuros(euros),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(colors: [light, Color.lerp(light, dark, 0.35)!]),
          border: Border.all(color: dark, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(2, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$euros', style: number),
                Text(
                  l10n.drawingEuro,
                  style: TextStyle(fontSize: height * 0.14, fontWeight: FontWeight.w800, color: dark),
                ),
              ],
            ),
            const Spacer(),
            // Torbogen wie auf den echten Scheinen.
            Container(
              width: width * 0.32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                border: Border.all(color: dark.withValues(alpha: 0.6), width: 2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ein Fischernetz mit Schwimmern. Das gute ist dick und kräftig, das billige
/// dünn und hat ein Loch.
class FishingNet extends StatelessWidget {
  const FishingNet({super.key, required this.size, this.good = false});

  final double size;
  final bool good;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size * 0.8),
    painter: _NetPainter(good: good),
  );
}

class _NetPainter extends CustomPainter {
  _NetPainter({required this.good});

  final bool good;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.18, w * 0.88, h * 0.76),
      Radius.circular(w * 0.18),
    );
    final rope = Paint()
      ..color = good ? const Color(0xFF8A5A2B) : const Color(0xFFD8C7A3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = good ? w * 0.06 : w * 0.035;
    final mesh = Paint()
      ..color = good ? const Color(0xFFB98552) : const Color(0xFFE9DFC8)
      ..strokeWidth = good ? w * 0.035 : w * 0.018;
    // Eigene Ebene, damit das Loch nur das Netz ausschneidet, nicht den Hintergrund.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.clipRRect(frame);
    final step = w * (good ? 0.16 : 0.2);
    for (var x = -h; x < w + h; x += step) {
      canvas.drawLine(Offset(x, h * 0.18), Offset(x + h, h * 1.1), mesh);
      canvas.drawLine(Offset(x + h, h * 0.18), Offset(x, h * 1.1), mesh);
    }
    if (!good) {
      // Das Loch im billigen Netz.
      canvas.drawCircle(Offset(w * 0.62, h * 0.62), w * 0.14, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();
    canvas.drawRRect(frame, rope);
    // Schwimmer oben am Netz.
    final cork = Paint()..color = const Color(0xFFE8833A);
    for (final fx in [0.25, 0.5, 0.75]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * fx, h * 0.18), width: w * 0.16, height: h * 0.14), cork);
    }
  }

  @override
  bool shouldRepaint(_NetPainter oldDelegate) => oldDelegate.good != good;
}
