import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../domain/real_games.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';
import 'game_frame.dart';

/// Eisstand: Für jeden Tag (Sonne, Wolken, Regen) setzt das Kind einen Preis
/// und öffnet den Stand. Dann sieht es, wie viele kommen, wie viel Eis
/// weggeht und wie viel schmilzt. Es darf so oft probieren, wie es will.
class IceStandGameView extends StatefulWidget {
  const IceStandGameView({super.key, required this.game, required this.onFinished});

  final GameInfo game;
  final ValueChanged<int> onFinished;

  @override
  State<IceStandGameView> createState() => _IceStandGameViewState();
}

class _IceStandGameViewState extends State<IceStandGameView> {
  late final IceStandGame _game = IceStandGame(widget.game);

  /// Ergebnis sichtbar (bis das Kind den Preis ändert).
  bool _showResult = false;

  /// Zählt die Versuche, damit die Kugeln bei jedem Öffnen neu erscheinen.
  int _tries = 0;

  /// Ergebnis-Karte: Nach dem Öffnen scrollt die Seite dorthin.
  final _resultKey = GlobalKey();

  void _open() {
    final result = _game.open();
    if (result.earned == _game.bestEarned(_game.day)) AppScope.of(context).sounds.effect(AssetKeys.soundCorrect);
    setState(() {
      _showResult = true;
      _tries++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _resultKey.currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300), alignment: 0.9);
      }
    });
  }

  void _setPrice(int value) => setState(() {
    _game.setPrice(value);
    _showResult = false;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final game = _game;
    final day = game.day;
    final result = _showResult ? game.last : null;

    final Widget button;
    if (result == null) {
      button = FilledButton.icon(
        key: const ValueKey('ice-open'),
        onPressed: _open,
        icon: const Icon(Icons.storefront_outlined),
        label: Text(l10n.iceOpen),
      );
    } else if (game.isLast) {
      button = FilledButton(
        key: const ValueKey('game-finish'),
        onPressed: () => widget.onFinished(game.stars),
        child: Text(l10n.realGameToResult),
      );
    } else {
      button = FilledButton(
        key: const ValueKey('ice-next-day'),
        onPressed: () => setState(() {
          game.next();
          _showResult = false;
        }),
        child: Text(l10n.iceNextDay),
      );
    }

    final (IconData weatherIcon, String weatherText, Color weatherColor) = switch (day.weather) {
      'rain' => (Icons.umbrella_rounded, l10n.iceWeatherRain, palette.seaDeep),
      'clouds' => (Icons.cloud_rounded, l10n.iceWeatherClouds, palette.sea),
      _ => (Icons.wb_sunny_rounded, l10n.iceWeatherSun, palette.gold),
    };

    return GameFrame(
      scene: false,
      game: widget.game,
      button: button,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.iceDay(game.index + 1, game.total), style: theme.textTheme.labelLarge),
            const SizedBox(width: 12),
            Icon(weatherIcon, color: weatherColor, key: ValueKey('ice-weather-${day.weather}')),
            const SizedBox(width: 4),
            Text(weatherText, style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        if (day.image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: TaleriaAsset(
                day.image!,
                fit: BoxFit.cover,
                fallback: ColoredBox(
                  color: weatherColor.withValues(alpha: 0.2),
                  child: Icon(weatherIcon, size: 64, color: weatherColor),
                ),
              ),
            ),
          )
        else
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: weatherColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(weatherIcon, size: 64, color: weatherColor),
          ),
        for (final line in day.scene) ...[const SizedBox(height: 8), SpeechBubble.line(line)],
        const SizedBox(height: 12),
        Text(l10n.iceStock(day.stock), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(l10n.icePriceLabel, textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              key: const ValueKey('ice-price-down'),
              tooltip: l10n.icePriceDown,
              iconSize: 32,
              onPressed: game.price > widget.game.priceMin ? () => _setPrice(game.price - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 140,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.icePrice(game.price),
                  key: const ValueKey('ice-price'),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            IconButton.filledTonal(
              key: const ValueKey('ice-price-up'),
              tooltip: l10n.icePriceUp,
              iconSize: 32,
              onPressed: game.price < widget.game.priceMax ? () => _setPrice(game.price + 1) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        if (result != null) ...[
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _resultKey,
            child: _IceResult(key: ValueKey('ice-result-$_tries'), result: result, verdict: _verdict(l10n, result)),
          ),
          if (!game.bestFoundToday || game.bestPrices(day).length > 1)
            TextButton(
              key: const ValueKey('ice-try-again'),
              onPressed: () => setState(() => _showResult = false),
              child: Text(l10n.iceTryAgain),
            ),
        ],
      ],
    );
  }

  /// Rückmeldung: bester Preis, zu billig oder zu teuer.
  ({String text, bool best}) _verdict(AppLocalizations l10n, IceTry result) {
    final best = _game.bestPrices(_game.day);
    if (best.contains(result.price)) return (text: l10n.iceBest, best: true);
    if (result.price < best.first) {
      return (text: result.missed > 0 ? l10n.iceTooCheapSoldOut : l10n.iceTooCheap, best: false);
    }
    return (text: l10n.iceTooDear, best: false);
  }
}

/// Ergebnis eines Tages: Kugeln (verkauft bunt, geschmolzen grau), Zahlen und Rückmeldung.
class _IceResult extends StatelessWidget {
  const _IceResult({super.key, required this.result, required this.verdict});

  final IceTry result;
  final ({String text, bool best}) verdict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = context.palette;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Card(
      color: verdict.best ? palette.gold.withValues(alpha: 0.25) : palette.paper,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Die verkauften Kugeln erscheinen nacheinander.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? result.sold.toDouble() : 0, end: result.sold.toDouble()),
              duration: Duration(milliseconds: reduced ? 1 : 60 * result.sold + 200),
              builder: (context, value, _) => Wrap(
                spacing: 2,
                runSpacing: 2,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < result.stock; i++)
                    Icon(
                      i < value.floor() ? Icons.icecream : Icons.water_drop_outlined,
                      size: 22,
                      color: i < value.floor() ? palette.coral : palette.ink.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.iceCustomers(result.customers), key: const ValueKey('ice-customers')),
            Text(
              l10n.iceSold(result.sold, result.earned),
              key: const ValueKey('ice-sold'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            if (result.missed > 0) Text(l10n.iceMissed(result.missed)),
            if (result.melted > 0) Text(l10n.iceMelted(result.melted)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (verdict.best) ...[Icon(Icons.star_rounded, color: palette.gold), const SizedBox(width: 4)],
                Flexible(
                  child: Text(
                    verdict.text,
                    key: const ValueKey('game-feedback'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(color: verdict.best ? palette.success : palette.coral),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
