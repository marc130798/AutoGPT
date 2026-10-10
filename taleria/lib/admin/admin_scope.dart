import 'package:flutter/widgets.dart';

import '../core/config/app_config.dart';
import 'data/admin_repository.dart';
import 'services/admin_session.dart';

/// Alles, was die Seiten des Adminbereichs brauchen.
class AdminServices {
  const AdminServices({required this.config, required this.session, this.repository});

  final AppConfig config;
  final AdminSession? session;

  /// `null` ohne Server.
  final AdminRepository? repository;
}

class AdminScope extends InheritedWidget {
  const AdminScope({super.key, required this.services, required super.child});

  final AdminServices services;

  static AdminServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminScope>();
    assert(scope != null, 'AdminScope fehlt');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AdminScope oldWidget) => services != oldWidget.services;
}
