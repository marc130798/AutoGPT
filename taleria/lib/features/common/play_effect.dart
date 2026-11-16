import 'package:flutter/widgets.dart';

import '../../core/app_scope.dart';

/// Spielt einen kurzen Ton (zum Beispiel `sound.chest_open`). Ohne App
/// darüber (einzelne Widget-Tests) bleibt es still statt abzustürzen.
/// Ton aus auf der Startseite gilt wie immer (`Sounds.effect`).
void playEffect(BuildContext context, String key) {
  final scope = context.getInheritedWidgetOfExactType<AppScope>();
  scope?.services.sounds.effect(key);
}
