import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_manifest.dart';
import '../../core/assets/video_placeholder.dart';
import '../../l10n/app_localizations.dart';

/// Spielt einen Film aus dem Asset-Manifest (Intro, Ankunft auf einer Insel),
/// im Hochformat 9:16 (Paket `video_player`, mit Marc am 16.11.2026
/// abgestimmt). Fehlt die Datei oder klappt das Abspielen nicht, erscheint
/// wie bisher der Platzhalter „Film folgt“.
///
/// Während der Film läuft, gibt es „Überspringen“; am Ende „Nochmal ansehen“
/// und „Weiter“. Ist der Ton auf der Startseite aus, läuft der Film stumm.
/// Blockiert der Browser das Abspielen (noch nicht angetippt), erscheint ein
/// großer Abspiel-Knopf.
class FilmView extends StatefulWidget {
  const FilmView({super.key, required this.assetKey, required this.onContinue});

  final String assetKey;
  final VoidCallback onContinue;

  @override
  State<FilmView> createState() => _FilmViewState();
}

class _FilmViewState extends State<FilmView> {
  VideoPlayerController? _video;
  bool _checked = false;
  bool _failed = false;
  bool _ended = false;
  bool _blocked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    final services = AppScope.of(context);
    final entry = services.manifest.lookup(widget.assetKey);
    final path = entry.path;
    if (path == null || entry.type != AssetType.video || !await services.assets.isAvailable(entry)) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    services.sounds.stopVoice();
    final video = VideoPlayerController.asset(path);
    try {
      await video.initialize();
      await video.setVolume(services.sounds.enabled ? 1 : 0);
    } catch (error) {
      debugPrint('Film nicht abspielbar: $error');
      await video.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await video.dispose();
      return;
    }
    video.addListener(_onTick);
    setState(() => _video = video);
    await _play();
  }

  Future<void> _play() async {
    final video = _video;
    if (video == null) return;
    try {
      if (_ended) await video.seekTo(Duration.zero);
      await video.play();
      if (mounted) setState(() => _ended = _blocked = false);
    } catch (_) {
      // Browser erlaubt Ton erst nach dem Antippen.
      if (mounted) setState(() => _blocked = true);
    }
  }

  void _onTick() {
    final value = _video!.value;
    final ended =
        value.isInitialized && !value.isPlaying && value.position >= value.duration - const Duration(milliseconds: 200);
    if (ended != _ended && mounted) setState(() => _ended = ended);
  }

  @override
  void dispose() {
    _video?.removeListener(_onTick);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return VideoPlaceholder(assetKey: widget.assetKey, onContinue: widget.onContinue);
    final l10n = AppLocalizations.of(context);
    final video = _video;
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: video?.value.aspectRatio ?? 9 / 16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (video == null)
                        const Center(child: CircularProgressIndicator(color: Colors.white))
                      else
                        VideoPlayer(video, key: const ValueKey('film-player')),
                      if (_blocked || _ended)
                        Center(
                          child: IconButton.filled(
                            key: const ValueKey('film-play'),
                            iconSize: 56,
                            tooltip: _ended ? l10n.filmAgain : l10n.filmPlay,
                            onPressed: _play,
                            icon: Icon(_ended ? Icons.replay_rounded : Icons.play_arrow_rounded),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _ended
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('film-again'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: _play,
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(l10n.filmAgain),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('film-continue'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            onPressed: widget.onContinue,
                            child: Text(l10n.continueButton),
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('film-skip'),
                        style: TextButton.styleFrom(foregroundColor: Colors.white70, minimumSize: const Size(48, 48)),
                        onPressed: widget.onContinue,
                        child: Text(l10n.filmSkip),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
