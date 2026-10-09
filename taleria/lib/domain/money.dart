/// Geld ist immer eine ganze Zahl in Cent (CLAUDE.md). Diese Hilfen wandeln
/// Eingaben wie „2,50“ in Cent um und zeigen Cent als „2,50 €“ an.
library;

/// Höchstbetrag einer einzelnen Eingabe in Cent (1.000 €).
const int maxAmountCents = 100000;

final _amountPattern = RegExp(r'^(\d{1,6})(?:[,.](\d{1,2}))?$');

/// „5“, „5,5“, „5,50“ oder „5.50“ → Cent. `null` bei ungültiger Eingabe.
int? parseEuroInput(String input) {
  final match = _amountPattern.firstMatch(input.trim().replaceAll('€', '').trim());
  if (match == null) return null;
  final euros = int.parse(match.group(1)!);
  final centsText = (match.group(2) ?? '0').padRight(2, '0');
  return euros * 100 + int.parse(centsText);
}

enum AmountProblem { invalid, zero, tooLarge }

/// Prüft einen eingegebenen Betrag (größer als 0, höchstens [max] Cent).
AmountProblem? validateAmount(String input, {int max = maxAmountCents}) {
  final cents = parseEuroInput(input);
  if (cents == null) return AmountProblem.invalid;
  if (cents == 0) return AmountProblem.zero;
  if (cents > max) return AmountProblem.tooLarge;
  return null;
}

/// 1234 → „12,34 €“, -250 → „-2,50 €“. Mit geschütztem Leerzeichen vor dem €.
String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = (abs ~/ 100).toString();
  final rest = (abs % 100).toString().padLeft(2, '0');
  final grouped = StringBuffer();
  for (var i = 0; i < euros.length; i++) {
    if (i > 0 && (euros.length - i) % 3 == 0) grouped.write('.');
    grouped.write(euros[i]);
  }
  return '${negative ? '-' : ''}$grouped,$rest €';
}

/// Cent als Eingabetext für Formulare: 250 → „2,50“.
String centsToInput(int cents) => '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
