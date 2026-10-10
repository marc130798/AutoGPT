import 'package:flutter/material.dart';

import '../../core/assets/taleria_asset.dart';
import '../../core/theme/taleria_palette.dart';
import '../../domain/content_models.dart';
import '../../l10n/app_localizations.dart';
import '../intro/speech_bubble.dart';

/// Das Bild, das zu Zeile [index] gehört: ihr eigenes oder das letzte davor.
String? pictureFor(List<DialogLine> lines, int index) {
  for (var i = index; i >= 0; i--) {
    if (lines[i].image case final image?) return image;
  }
  return null;
}

/// Bildergeschichte: die Erklärung einer Station als Bilder zum Weiterblättern
/// (Knöpfe oder Wischen). Oben das Bild, darunter, was Talo, Tala oder eine
/// Inselfigur dazu sagt. Zeilen ohne eigenes Bild zeigen das Bild davor.
/// Fehlt die Bilddatei noch, steht der Platzhalter mit dem Namen des Bildes da.
class PictureStory extends StatefulWidget {
  const PictureStory({super.key, required this.lines, required this.onDone});

  final List<DialogLine> lines;
  final VoidCallback onDone;

  @override
  State<PictureStory> createState() => _PictureStoryState();
}

class _PictureStoryState extends State<PictureStory> {
  int _index = 0;

  bool get _last => _index >= widget.lines.length - 1;

  void _next() => _last ? widget.onDone() : setState(() => _index++);

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final lines = widget.lines;
    final image = pictureFor(lines, _index);

    return GestureDetector(
      // Nach links wischen = weiter, nach rechts = zurück.
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -250) _next();
        if (v > 250) _back();
      },
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              // Das Bild höchstens gut halb so hoch wie der Platz, damit der
              // Satz darunter auch auf breiten Bildschirmen zu sehen ist.
              builder: (context, box) => ListView(
                key: ValueKey('story-slide-$_index'),
                padding: const EdgeInsets.all(16),
                children: [
                  if (image != null)
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: box.maxHeight * 0.55,
                          maxWidth: box.maxHeight * 0.55 * 4 / 3,
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: _Picture(image: image),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SpeechBubble.line(lines[_index]),
                ],
              ),
            ),
          ),
          // Punkte: wo in der Geschichte man gerade ist.
          Row(
            key: const ValueKey('story-dots'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < lines.length; i++)
                Container(
                  margin: const EdgeInsets.all(3),
                  width: i == _index ? 12 : 8,
                  height: i == _index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= _index ? palette.gold : palette.placeholderBorder.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_index > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('story-back'),
                      onPressed: _back,
                      child: Text(l10n.tourBack),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: _last
                      ? FilledButton(key: const ValueKey('story-next'), onPressed: _next, child: Text(l10n.introNext))
                      : OutlinedButton(
                          key: const ValueKey('story-next'),
                          onPressed: _next,
                          child: Text(l10n.introNext),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ein Bild der Geschichte mit goldenem Rahmen; neue Bilder blenden über.
class _Picture extends StatelessWidget {
  const _Picture({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.gold, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x44081C30), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, box) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: TaleriaAsset(
              image,
              key: ValueKey('story-image-$image'),
              fit: BoxFit.cover,
              width: box.maxWidth,
              height: box.maxHeight,
            ),
          ),
        ),
      ),
    );
  }
}
