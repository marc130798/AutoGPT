import 'package:flutter/widgets.dart';

import '../../core/app_scope.dart';
import '../../core/assets/asset_keys.dart';
import '../../services/sounds.dart';

/// Meldet, wann Seiten kommen und gehen (für die Musik im Hauptmenü).
/// Nur ganze Seiten zählen: Ein Dialog über einer Menü-Seite (zum Beispiel
/// „Ich habe etwas gekauft“) hält die Musik nicht an.
final menuRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Spielt die Musik des Hauptmenüs, solange diese Seite vorn ist: Startseite,
/// Karte und die anderen Menü-Seiten (Schatztruhe, Aufträge, Orden, Sammlung,
/// Rundgang). Kommt eine Seite ohne Musik darüber (Insel, Station, Begegnung
/// auf See, Leuchtturm), pausiert sie; geht es zurück, läuft sie weiter.
class MenuMusic extends StatefulWidget {
  const MenuMusic({super.key, required this.child, this.music = AssetKeys.musicHome});

  final Widget child;
  final String music;

  @override
  State<MenuMusic> createState() => _MenuMusicState();
}

class _MenuMusicState extends State<MenuMusic> implements RouteAware {
  /// Die Seite, die die Musik zuletzt bestellt hat. Beim Zurückgehen meldet
  /// Flutter zuerst der Seite darunter, dass sie wieder vorn ist, und erst
  /// danach der Seite, die geht; die gehende Seite darf die Musik dann nicht
  /// mehr anhalten.
  static _MenuMusicState? _owner;

  Sounds? _sounds;
  ModalRoute<void>? _route;

  void _claim() {
    _owner = this;
    _sounds?.music(widget.music);
  }

  void _release() {
    if (_owner != this) return;
    _owner = null;
    _sounds?.music(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sounds = AppScope.of(context).sounds;
    final route = ModalRoute.of(context);
    if (route != _route) {
      menuRouteObserver.unsubscribe(this);
      _route = route;
      // Meldet sich an und ruft dabei didPush auf.
      if (route is PageRoute<dynamic>) {
        menuRouteObserver.subscribe(this, route);
      } else {
        _claim();
      }
    }
  }

  @override
  void dispose() {
    menuRouteObserver.unsubscribe(this);
    _release();
    super.dispose();
  }

  @override
  void didPush() => _claim();

  @override
  void didPopNext() => _claim();

  @override
  void didPushNext() => _release();

  @override
  void didPop() => _release();

  @override
  Widget build(BuildContext context) => widget.child;
}
