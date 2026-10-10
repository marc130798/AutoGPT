import 'package:flutter/widgets.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../services/sounds.dart';

/// Meldet, wann Bildschirme kommen und gehen (für die Musik im Hauptmenü).
final menuRouteObserver = RouteObserver<ModalRoute<void>>();

/// Spielt die Musik des Hauptmenüs, solange dieser Bildschirm vorn ist
/// (Startseite und Karte). Kommt ein anderer Bildschirm darüber (Insel,
/// Station, Leuchtturm), pausiert sie; geht es zurück, läuft sie weiter.
class MenuMusic extends StatefulWidget {
  const MenuMusic({super.key, required this.child, this.music = AssetKeys.musicHome});

  final Widget child;
  final String music;

  @override
  State<MenuMusic> createState() => _MenuMusicState();
}

class _MenuMusicState extends State<MenuMusic> implements RouteAware {
  Sounds? _sounds;
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds = AppScope.of(context).sounds;
    final route = ModalRoute.of(context);
    if (route != _route) {
      menuRouteObserver.unsubscribe(this);
      _route = route;
      // Meldet sich an und ruft dabei didPush auf.
      if (route != null) {
        menuRouteObserver.subscribe(this, route);
      } else {
        _sounds?.music(widget.music);
      }
    }
  }

  @override
  void dispose() {
    menuRouteObserver.unsubscribe(this);
    _sounds?.music(null);
    super.dispose();
  }

  @override
  void didPush() => _sounds?.music(widget.music);

  @override
  void didPopNext() => _sounds?.music(widget.music);

  @override
  void didPushNext() => _sounds?.music(null);

  @override
  void didPop() => _sounds?.music(null);

  @override
  Widget build(BuildContext context) => widget.child;
}
