import '../../l10n/app_localizations.dart';

// Kinder können sich die Namen der Inselfiguren schwer merken (Marcs Test am
// 20.10.2026). Darum steht bei Figuren mit eigenem Namen das Tier dabei
// („Bruno, der Bär“), und ist eine Antwort genau ihr Name, zeigt der Knopf
// ihr Gesicht.

/// Figur (`bruno` für `character.bruno`), wenn [text] genau ihr Name ist, sonst `null`.
String? figureNamed(AppLocalizations l10n, String text) {
  final key = text.trim().toLowerCase();
  if (key.isEmpty || key.contains(RegExp(r'[^a-zäöüß]'))) return null;
  return l10n.figureAnimal(key).isEmpty ? null : key;
}

/// [name] mit Tier, wenn [name] der eigene Name der Figur [figure] ist
/// („Bruno, der Bär“); sonst [name] unverändert, zum Beispiel „Händler“.
String figureLabel(AppLocalizations l10n, String figure, String name) {
  final animal = l10n.figureAnimal(figure);
  if (animal.isEmpty || name.trim().toLowerCase() != figure) return name;
  return l10n.figureWithAnimal(name, animal);
}
