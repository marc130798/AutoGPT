import 'package:flutter/material.dart';

import '../../core/theme/taleria_palette.dart';
import '../admin_scope.dart';
import '../admin_texts.dart';
import '../domain/admin_models.dart';
import '../services/admin_loader.dart';
import '../services/admin_session.dart';
import 'app_errors_page.dart';
import 'audit_page.dart';
import 'content_page.dart';
import 'overview_page.dart';
import 'support_page.dart';

enum _Section { overview, content, support, audit, errors }

/// Startseite nach der Anmeldung. Welche Bereiche es gibt, hängt von der Rolle ab.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.session});

  final AdminSession session;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;
  AdminLoader<EnvironmentSettings>? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AdminScope.of(context).repository;
    if (_settings == null && repository != null) {
      _settings = AdminLoader(repository.environmentSettings)..load();
    }
  }

  @override
  void dispose() {
    _settings?.dispose();
    super.dispose();
  }

  List<_Section> _sections(AdminRole role) => [
    if (role.seesOverview) _Section.overview,
    if (role.seesContent) _Section.content,
    if (role.seesSupport) _Section.support,
    if (role.seesAuditLog) _Section.audit,
    if (role.seesAppErrors) _Section.errors,
  ];

  @override
  Widget build(BuildContext context) {
    final identity = widget.session.identity!;
    final config = AdminScope.of(context).config;
    final sections = _sections(identity.role);
    final index = _index.clamp(0, sections.length - 1);
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AdminTexts.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              key: const ValueKey('admin-environment'),
              label: Text(config.isTest ? AdminTexts.environmentTest : AdminTexts.environmentLive),
              backgroundColor: config.isTest ? palette.sand : palette.coral,
            ),
          ),
          Center(child: Text('${identity.email ?? ''} · ${AdminTexts.role(identity.role)}')),
          IconButton(
            key: const ValueKey('admin-sign-out'),
            tooltip: AdminTexts.signOut,
            onPressed: widget.session.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_settings != null)
            ListenableBuilder(
              listenable: _settings!,
              builder: (context, _) => _EnvironmentBanner(settings: _settings!.data, isTest: config.isTest),
            ),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final s in sections)
                      NavigationRailDestination(
                        icon: Icon(_icon(s), key: ValueKey('nav-${s.name}')),
                        label: Text(_label(s)),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: switch (sections[index]) {
                    _Section.overview => const OverviewPage(),
                    _Section.content => const ContentPage(),
                    _Section.support => SupportPage(role: identity.role),
                    _Section.audit => const AuditPage(),
                    _Section.errors => const AppErrorsPage(),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(_Section s) => switch (s) {
    _Section.overview => Icons.insights,
    _Section.content => Icons.map_outlined,
    _Section.support => Icons.support_agent,
    _Section.audit => Icons.receipt_long,
    _Section.errors => Icons.bug_report_outlined,
  };

  static String _label(_Section s) => switch (s) {
    _Section.overview => AdminTexts.overview,
    _Section.content => AdminTexts.content,
    _Section.support => AdminTexts.support,
    _Section.audit => AdminTexts.auditLog,
    _Section.errors => AdminTexts.appErrors,
  };
}

/// Hinweis auf Test-Einstellungen. In der Live-Datenbank ist das ein Alarm.
class _EnvironmentBanner extends StatelessWidget {
  const _EnvironmentBanner({required this.settings, required this.isTest});

  final EnvironmentSettings? settings;
  final bool isTest;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings;
    if (settings == null || !settings.anyTestSetting) return const SizedBox.shrink();
    final palette = context.palette;
    return Container(
      key: ValueKey(isTest ? 'banner-test' : 'banner-live-warning'),
      width: double.infinity,
      color: isTest ? palette.sand : palette.coral,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        isTest ? AdminTexts.testSettingsInTest : AdminTexts.testSettingsInLive,
        style: TextStyle(color: isTest ? palette.ink : palette.paper, fontWeight: isTest ? null : FontWeight.bold),
      ),
    );
  }
}
