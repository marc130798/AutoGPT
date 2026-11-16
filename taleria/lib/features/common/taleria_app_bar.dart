import 'package:flutter/material.dart';

import 'wood_sign.dart';

/// Kopf der Seiten im Kinderbereich: kein blauer Balken, sondern das
/// Hintergrundbild läuft bis zum oberen Rand. Darauf schweben ein Holzschild
/// mit dem Titel und ein runder Holzknopf zum Zurückgehen (wie auf der
/// Startseite). Die Seite braucht dafür `extendBodyBehindAppBar: true` und
/// eine `SafeArea` um den Inhalt, damit nichts unter dem Schild liegt.
class TaleriaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TaleriaAppBar({super.key, required this.title});

  final String title;

  static const double height = 68;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final canGoBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return AppBar(
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 64,
      leading: canGoBack
          ? Center(
              child: BackButton(
                style: IconButton.styleFrom(
                  fixedSize: const Size(46, 46),
                  backgroundColor: WoodColors.mid,
                  foregroundColor: WoodColors.cream,
                  side: const BorderSide(color: WoodColors.edge, width: 2.5),
                  elevation: 3,
                  shadowColor: const Color(0x88081C30),
                ),
              ),
            )
          : null,
      centerTitle: true,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: WoodSign(text: title),
      ),
      // Gleich breit wie der Zurück-Knopf, damit das Schild in der Mitte steht.
      actions: const [SizedBox(width: 64)],
    );
  }
}
