import 'package:flutter/widgets.dart';

import '../../core/app_scope.dart';
import '../../services/sounds.dart';

/// Liest beim Erscheinen einmal die Aufnahmen [files] nacheinander vor
/// (fehlende werden übersprungen) und hört beim Verlassen auf.
class SpeakOnce extends StatefulWidget {
  const SpeakOnce({super.key, required this.files, required this.child});

  final List<String> files;
  final Widget child;

  @override
  State<SpeakOnce> createState() => _SpeakOnceState();
}

class _SpeakOnceState extends State<SpeakOnce> {
  Sounds? _sounds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sounds != null) return;
    final sounds = _sounds = AppScope.of(context).sounds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sounds.voices(widget.files);
    });
  }

  @override
  void dispose() {
    _sounds?.stopVoice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
