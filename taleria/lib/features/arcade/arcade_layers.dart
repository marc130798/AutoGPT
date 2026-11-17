import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/assets/asset_keys.dart';
import '../../core/assets/character_image.dart';
import '../../core/assets/taleria_asset.dart';
import '../../domain/arcade_games.dart';
import '../../l10n/app_localizations.dart';

// Was die Spielfelder der richtigen Spiele zeigen: Hintergrund, Dinge,
// Spielfigur. Alles aus Bildern (BILDER.md 182 bis 205); die Trefferflächen
// kommen aus den Regeln in `lib/domain/arcade/`.

/// Bild mit leerem Ersatz, wenn die Datei fehlt.
Widget _img(String key, {BoxFit fit = BoxFit.contain, Alignment alignment = Alignment.center}) =>
    TaleriaAsset(key, fit: fit, alignment: alignment, fallback: const SizedBox.shrink());

Widget _at(double cx, double cy, double w, double h, Widget child) =>
    Positioned(left: cx - w / 2, top: cy - h / 2, width: w, height: h, child: child);

Widget _blinking(bool blink, Widget child) => Opacity(opacity: blink ? 0.35 : 1, child: child);

/// Alle Ebenen eines Spiels (unten nach oben), ohne die Anzeige oben.
List<Widget> arcadeLayers(ArcadeRound round, Size size) {
  final u = size.height;
  final blink = round.safe && (round.time * 8).floor().isEven;
  return switch (round) {
    GullFlightGame g => _gull(g, u, blink),
    CraneGame g => _crane(g, u, blink),
    DeliveryGame g => _lanes(g, size, blink, catcher: 'game.delivery.boat'),
    BottleGame g => _lanes(g, size, blink, catcher: 'game.bottles.net'),
    NutRunGame g => _nuts(g, u, blink),
    PearlDiveGame g => _pearls(g, u, blink),
    _ => const [],
  };
}

/// Antippen oder Ziehen auf dem Spielfeld.
void arcadePointer(ArcadeRound round, Offset local, Size size, {required bool down}) {
  final u = size.height;
  switch (round) {
    case GullFlightGame g when down:
      g.flap();
    case CraneGame g when down:
      g.drop();
    case LaneGame g when down:
      g.moveTo((local.dx / size.width * LaneGame.lanes).floor());
    case NutRunGame g when down:
      g.jump();
    case PearlDiveGame g:
      g.swimTo(local.dx / u, local.dy / u);
    default:
  }
}

// ---------- Mias Möwenflug ----------

List<Widget> _gull(GullFlightGame g, double u, bool blink) {
  final bird = u * 0.1;
  return [
    Positioned.fill(
      child: _img('game.gull.background', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
    ),
    Positioned.fill(
      child: CustomPaint(
        painter: SeaPainter(time: g.time, top: GullFlightGame.sea),
      ),
    ),
    for (final o in g.obstacles) ..._gullObstacle(o, g, u),
    for (final p in g.pickups)
      if (!p.taken) _gullPickup(p, g, u),
    Positioned(
      left: g.birdX * u - bird * 0.6,
      top: g.y * u - bird / 2,
      width: bird * 1.2,
      height: bird,
      child: _blinking(
        blink,
        Transform.rotate(
          angle: (g.vy * 0.45).clamp(-0.45, 0.6),
          // Das Bild schaut nach links, Mia fliegt nach rechts.
          child: Transform.flip(
            flipX: true,
            child: const TaleriaAsset(
              'character.mia.fly',
              fit: BoxFit.contain,
              fallback: CharacterImage('character.mia', fallback: SizedBox.shrink()),
            ),
          ),
        ),
      ),
    ),
  ];
}

/// Hindernis: unten ein Turm aus Kisten bis ins Wasser, oben ein Fischernetz
/// an einem Seil. Die Trefferfläche bleibt die aus den Regeln.
List<Widget> _gullObstacle(GullObstacle o, GullFlightGame game, double unit) {
  final w = GullFlightGame.obstacleWidth * unit;
  final left = o.x * unit;
  final center = o.centerAt(game.time) * unit;
  final top = center - o.gapHalf * unit;
  final bottom = center + o.gapHalf * unit;
  final seaTop = GullFlightGame.sea * unit;
  final crate = w * 1.12;
  final crates = ((seaTop - bottom) / crate).ceil() + 1;
  final netW = w * 1.5;
  final netH = netW * 1.5;
  return [
    Positioned(
      left: left + w / 2 - crate / 2,
      top: bottom,
      width: crate,
      height: max(0, seaTop - bottom + crate * 0.3),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: crate * crates,
          child: Column(
            children: [
              for (var i = 0; i < crates; i++)
                SizedBox.square(
                  dimension: crate,
                  child: _img('game.gull.crate', fit: BoxFit.fill),
                ),
            ],
          ),
        ),
      ),
    ),
    // Seil von oben bis zum Netz.
    Positioned(
      left: left + w / 2 - 2,
      top: 0,
      width: 4,
      height: max(0, top - netH * 0.85),
      child: const ColoredBox(color: Color(0xFFC9A66B)),
    ),
    Positioned(
      left: left + w / 2 - netW / 2,
      top: top - netH,
      width: netW,
      height: netH,
      child: _img('game.gull.net', fit: BoxFit.fill),
    ),
  ];
}

/// Taler oder Sparglas, leicht schwebend.
Widget _gullPickup(GullPickup p, GullFlightGame game, double unit) {
  final size = p.jar ? 0.1 * unit : GullFlightGame.pickupRadius * 2.4 * unit;
  final bob = sin(game.time * 4 + p.x * 9) * 0.006 * unit;
  final pulse = p.jar ? 1 + sin(game.time * 6) * 0.05 : 1.0;
  return _at(
    p.x * unit,
    p.y * unit + bob,
    size,
    size,
    Transform.scale(scale: pulse, child: _img(p.jar ? 'game.gull.jar' : 'game.gull.coin')),
  );
}

// ---------- Bootsbauers Kran ----------

List<Widget> _crane(CraneGame g, double u, bool blink) {
  final beamY = (CraneGame.top - 0.1) * u;
  final hook = 0.075 * u;
  final itemSize = 0.08 * u;
  Widget item(CraneItem i) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: _img(i.boot ? 'game.crane.boot' : 'game.crane.bag')),
      if (!i.boot)
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3C94B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8A5A10), width: 2),
            ),
            child: Text(
              '${i.value}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF3A2605)),
            ),
          ),
        ),
    ],
  );
  final held = g.held;
  return [
    Positioned.fill(
      child: _img('game.crane.background', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
    ),
    Positioned.fill(
      child: CustomPaint(
        painter: SeaPainter(time: g.time, top: CraneGame.water + 0.03, alpha: 0.55),
      ),
    ),
    // Der Kran: ein Holzbalken über das ganze Bild mit Stütze links.
    Positioned(
      left: 0,
      right: 0,
      top: beamY,
      height: 0.03 * u,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF8A5A2B),
          border: Border.all(color: const Color(0xFF5E3B1A), width: 3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    Positioned(
      left: 6,
      top: beamY,
      width: 0.03 * u,
      height: 0.45 * u,
      child: const ColoredBox(color: Color(0xFF6E4520)),
    ),
    // Laufkatze mit Seil und Haken.
    Positioned(
      left: g.trolley * u - 0.025 * u,
      top: beamY - 0.012 * u,
      width: 0.05 * u,
      height: 0.05 * u,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF4A5560),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2C343B), width: 2),
        ),
      ),
    ),
    Positioned(
      left: g.trolley * u - 1.5,
      top: beamY + 0.03 * u,
      width: 3,
      height: max(0, g.hookY * u - hook * 0.45 - beamY - 0.03 * u),
      child: const ColoredBox(color: Color(0xFF5E4630)),
    ),
    for (final i in g.items)
      _at(i.x * u, (CraneGame.water - 0.01) * u + sin(g.time * 3 + i.phase) * 0.006 * u, itemSize, itemSize, item(i)),
    if (held != null) _at(g.trolley * u, g.hookY * u + itemSize * 0.55, itemSize, itemSize, item(held)),
    _at(g.trolley * u, g.hookY * u, hook, hook, _blinking(blink, _img('game.crane.hook'))),
  ];
}

// ---------- Ottis Lieferboot und Elsas Flaschenfänger ----------

List<Widget> _lanes(LaneGame g, Size size, bool blink, {required String catcher}) {
  final u = size.height;
  final scroll = (g.time * g.speed * u) % size.height;
  final thing = 0.1 * u;
  final bottles = g is BottleGame;
  Widget sea(double top) => Positioned(
    left: 0,
    right: 0,
    top: top,
    height: size.height + 1,
    child: _img(AssetKeys.mapBackground, fit: BoxFit.cover),
  );
  Widget content(LaneThing t) {
    if (t.kind == 'rock') return _img('game.delivery.rock');
    final picture = _img('item.${t.kind}');
    if (bottles) {
      return Stack(
        children: [
          Positioned.fill(child: Transform.rotate(angle: -0.5, child: _img('game.bottles.bottle'))),
          Positioned.fill(
            child: Padding(padding: EdgeInsets.all(thing * 0.24), child: picture),
          ),
        ],
      );
    }
    // Waren schwimmen auf einem kleinen Floß aus Holz.
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(thing * 0.08),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xCCB98A55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6E4520), width: 2),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(padding: EdgeInsets.all(thing * 0.16), child: picture),
        ),
      ],
    );
  }

  return [
    sea(scroll - size.height),
    sea(scroll),
    Positioned.fill(child: CustomPaint(painter: _LanePainter(LaneGame.lanes))),
    for (final t in g.things) _at(g.laneX(t.lane) * u, t.y * u, thing, thing, content(t)),
    _at(g.catcherX * u, LaneGame.catchY * u + 0.03 * u, 0.13 * u, 0.13 * u, _blinking(blink, _img(catcher))),
  ];
}

/// Feine Linien zwischen den Bahnen.
class _LanePainter extends CustomPainter {
  _LanePainter(this.lanes);

  final int lanes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var i = 1; i < lanes; i++) {
      final x = size.width * i / lanes;
      for (var y = 0.0; y < size.height; y += 26) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 12), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LanePainter old) => false;
}

// ---------- Emmas Nussjagd ----------

List<Widget> _nuts(NutRunGame g, double u, bool blink) {
  final emma = 0.12 * u;
  final run = g.onGround ? sin(g.time * 18).abs() * 0.008 * u : 0.0;
  String key(NutThingType t) => switch (t) {
    NutThingType.nut => 'game.nuts.nut',
    NutThingType.mushroom => 'game.nuts.mushroom',
    NutThingType.log => 'game.nuts.log',
    NutThingType.hollow => 'game.nuts.hollow',
  };
  return [
    Positioned.fill(
      child: _img('game.nuts.background', fit: BoxFit.cover, alignment: Alignment.bottomCenter),
    ),
    for (final t in g.things)
      if (t.type == NutThingType.nut)
        if (!t.taken) _at(t.x * u, t.y * u, t.w * u * 1.3, t.h * u * 1.3, _img(key(t.type))) else const SizedBox()
      else
        // Hindernisse und Versteck stehen auf dem Boden, etwas größer als die Trefferfläche.
        Positioned(
          left: (t.x - t.w * 0.65) * u,
          top: (t.y - t.h * 1.25) * u,
          width: t.w * 1.3 * u,
          height: t.h * 1.3 * u,
          child: _img(key(t.type), alignment: Alignment.bottomCenter),
        ),
    Positioned(
      left: g.emmaX * u - emma * 0.55,
      top: g.y * u - emma + 0.012 * u - run,
      width: emma * 1.1,
      height: emma,
      child: _blinking(
        blink,
        const TaleriaAsset(
          'character.emma.run',
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          fallback: CharacterImage('character.emma', fallback: SizedBox.shrink()),
        ),
      ),
    ),
  ];
}

// ---------- Talas Perlentaucher ----------

List<Widget> _pearls(PearlDiveGame g, double u, bool blink) {
  final shell = 0.085 * u;
  final jelly = 0.085 * u;
  final diver = 0.13 * u;
  return [
    Positioned.fill(child: _img(AssetKeys.underwaterBackground, fit: BoxFit.cover)),
    for (final s in g.shells)
      _at(
        s.x * u,
        s.y * u - shell * 0.3,
        shell,
        shell,
        Opacity(
          opacity: s.taken ? 0.45 : 1,
          child: _img(s.openAt(g.time) && !s.taken ? 'game.pearl.shell.open' : 'game.pearl.shell.closed'),
        ),
      ),
    for (final j in g.jellies) _at(j.x * u, j.yAt(g.time) * u, jelly, jelly, _img('game.pearl.jelly')),
    _at(
      g.x * u,
      g.y * u,
      diver,
      diver,
      _blinking(
        blink,
        const TaleriaAsset(
          'game.pearl.diver',
          fit: BoxFit.contain,
          fallback: CharacterImage('character.tala', fallback: SizedBox.shrink()),
        ),
      ),
    ),
  ];
}

/// Wasser vorn mit Wellenkante (Möwenflug, Kran).
class SeaPainter extends CustomPainter {
  SeaPainter({required this.time, required this.top, this.alpha = 1});

  final double time;

  /// Oberkante des Wassers (Anteil der Höhe).
  final double top;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final seaTop = top * size.height;
    final rect = Rect.fromLTRB(0, seaTop, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF39B3C9).withValues(alpha: alpha),
            const Color(0xFF1E7FA0).withValues(alpha: alpha),
          ],
        ).createShader(rect),
    );
    final foam = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final wave = Path()..moveTo(0, seaTop);
    for (var x = 0.0; x <= size.width + 10; x += 10) {
      wave.lineTo(x, seaTop + sin(x / 18 + time * 3) * 2.5);
    }
    canvas.drawPath(wave, foam);
  }

  @override
  bool shouldRepaint(SeaPainter old) => true;
}

/// Eine Anzeige oben im Spiel.
class ArcadeHudItem {
  const ArcadeHudItem({required this.icon, required this.text, required this.label, required this.key});

  final Widget icon;
  final String text;

  /// Für Vorlesen.
  final String label;
  final String key;
}

/// Anzeigen oben je Spiel (Herzen und Stufe kommen dazu).
List<ArcadeHudItem> arcadeHud(AppLocalizations l10n, ArcadeRound round) {
  Widget icon(String key, IconData fallback, Color color) => SizedBox.square(
    dimension: 24,
    child: TaleriaAsset(
      key,
      fit: BoxFit.contain,
      fallback: Icon(fallback, color: color, size: 22),
    ),
  );
  const coin = Icon(Icons.monetization_on_rounded, color: Color(0xFFE0A526), size: 22);
  ArcadeHudItem points(int n) =>
      ArcadeHudItem(icon: coin, text: '$n', label: l10n.arcadePoints(n), key: 'arcade-points');
  return switch (round) {
    GullFlightGame g => [
      ArcadeHudItem(icon: coin, text: '${g.pocket}', label: l10n.arcadePocket(g.pocket), key: 'arcade-pocket'),
      ArcadeHudItem(
        icon: icon('game.gull.jar', Icons.savings_rounded, const Color(0xFF3E8FB0)),
        text: '${g.saved}',
        label: l10n.arcadeSaved(g.saved),
        key: 'arcade-saved',
      ),
    ],
    CraneGame g => [
      ArcadeHudItem(
        icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF8A5A2B), size: 22),
        text: l10n.arcadeCraneOrder(g.target),
        label: l10n.arcadeCraneOrder(g.target),
        key: 'arcade-order',
      ),
      ArcadeHudItem(
        icon: icon('game.crane.bag', Icons.inventory_2_rounded, const Color(0xFF8A5A2B)),
        text: '${g.sum}',
        label: l10n.arcadeCraneBox(g.sum),
        key: 'arcade-box',
      ),
      points(g.points),
    ],
    DeliveryGame g => [
      ArcadeHudItem(
        icon: SizedBox.square(
          dimension: 28,
          child: CharacterImage('character.${g.current.speaker}', fallback: const SizedBox.shrink()),
        ),
        text: '${l10n.arcadeDeliveryWants} ${l10n.arcadeItem(g.current.wants)} ${g.got}/${DeliveryGame.perCustomer}',
        label: '${l10n.arcadeDeliveryWants} ${l10n.arcadeItem(g.current.wants)}',
        key: 'arcade-customer',
      ),
      points(g.points),
    ],
    BottleGame g => [
      ArcadeHudItem(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF3E9B5A), size: 22),
        text: l10n.arcadeBottlesHint,
        label: l10n.arcadeBottlesHint,
        key: 'arcade-hint',
      ),
      points(g.points),
    ],
    NutRunGame g => [
      ArcadeHudItem(
        icon: icon('game.nuts.nut', Icons.circle, const Color(0xFFA0522D)),
        text: '${g.carried}',
        label: l10n.arcadeNutsCarried(g.carried),
        key: 'arcade-carried',
      ),
      ArcadeHudItem(
        icon: icon('game.nuts.hollow', Icons.home_rounded, const Color(0xFF7A5230)),
        text: '${g.stored}',
        label: l10n.arcadeNutsStored(g.stored),
        key: 'arcade-stored',
      ),
    ],
    PearlDiveGame g => [
      ArcadeHudItem(
        icon: icon(AssetKeys.pearl, Icons.circle_outlined, Colors.white),
        text: '${g.pearls}',
        label: l10n.arcadePearlCount(g.pearls),
        key: 'arcade-pearls',
      ),
    ],
    _ => const [],
  };
}
