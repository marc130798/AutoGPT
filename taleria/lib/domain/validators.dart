/// Prüfregeln für Eingaben. Jede Funktion gibt `null` zurück, wenn alles
/// stimmt, sonst einen Grund. Die Oberfläche übersetzt den Grund in Text.
library;

enum EmailProblem { empty, invalid }

enum PasswordProblem { tooShort }

enum PinProblem { format, tooSimple }

enum NicknameProblem { tooShort, tooLong, invalidCharacters }

enum ShipNameProblem { tooShort, tooLong, invalidCharacters }

enum WishTitleProblem { tooShort, tooLong }

enum WishAmountProblem { notANumber, outOfRange }

/// Mindestlänge für Eltern-Passwörter (auch in supabase/config.toml).
const int minPasswordLength = 10;

const int minNicknameLength = 2;
const int maxNicknameLength = 20;
const int maxShipNameLength = 30;
const int maxWishTitleLength = 40;

/// Wunschschatz: 1 € bis 10.000 € (passt zu savings_goals in der Datenbank).
const int minWishEuros = 1;
const int maxWishEuros = 10000;

/// Zeichen für Anmelde-Codes, ohne leicht verwechselbare I, L, O, 0 und 1.
/// Muss zu create_child_login_code() in der Datenbank passen.
const String loginCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const int loginCodeLength = 8;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
final _pinPattern = RegExp(r'^[0-9]{4,6}$');
final _nicknamePattern = RegExp(r"^[\p{L}\p{N} '\-]+$", unicode: true);
final _letterPattern = RegExp(r'\p{L}', unicode: true);

EmailProblem? validateEmail(String input) {
  final value = input.trim();
  if (value.isEmpty) return EmailProblem.empty;
  if (!_emailPattern.hasMatch(value)) return EmailProblem.invalid;
  return null;
}

PasswordProblem? validatePassword(String input) {
  if (input.length < minPasswordLength) return PasswordProblem.tooShort;
  return null;
}

/// Eltern-PIN: 4 bis 6 Ziffern, nicht leicht zu erraten
/// (keine gleichen Ziffern wie 1111, keine Reihe wie 1234 oder 9876).
PinProblem? validatePin(String pin) {
  if (!_pinPattern.hasMatch(pin)) return PinProblem.format;
  final digits = pin.codeUnits.map((c) => c - 48).toList();
  final allSame = digits.every((d) => d == digits.first);
  bool isSequence(int step) {
    for (var i = 1; i < digits.length; i++) {
      if (digits[i] - digits[i - 1] != step) return false;
    }
    return true;
  }

  if (allSame || isSequence(1) || isSequence(-1)) return PinProblem.tooSimple;
  return null;
}

/// Spitzname: 2 bis 20 Zeichen, Buchstaben, Ziffern, Leerzeichen, Bindestrich
/// oder Apostroph, mindestens ein Buchstabe. Ein echter Name ist nicht nötig.
NicknameProblem? validateNickname(String input) {
  final value = input.trim();
  if (value.characters < minNicknameLength) return NicknameProblem.tooShort;
  if (value.characters > maxNicknameLength) return NicknameProblem.tooLong;
  if (!_nicknamePattern.hasMatch(value) || !_letterPattern.hasMatch(value)) {
    return NicknameProblem.invalidCharacters;
  }
  return null;
}

/// Schiffsname: 2 bis 30 Zeichen, sonst wie beim Spitznamen.
ShipNameProblem? validateShipName(String input) {
  final value = input.trim();
  if (value.characters < minNicknameLength) return ShipNameProblem.tooShort;
  if (value.characters > maxShipNameLength) return ShipNameProblem.tooLong;
  if (!_nicknamePattern.hasMatch(value) || !_letterPattern.hasMatch(value)) {
    return ShipNameProblem.invalidCharacters;
  }
  return null;
}

WishTitleProblem? validateWishTitle(String input) {
  final value = input.trim();
  if (value.characters < 2) return WishTitleProblem.tooShort;
  if (value.characters > maxWishTitleLength) return WishTitleProblem.tooLong;
  return null;
}

/// Betrag eines Wunschschatzes in ganzen Euro (Schätzen ist erlaubt).
WishAmountProblem? validateWishEuros(String input) {
  final euros = int.tryParse(input.trim());
  if (euros == null) return WishAmountProblem.notANumber;
  if (euros < minWishEuros || euros > maxWishEuros) return WishAmountProblem.outOfRange;
  return null;
}

/// Ganze Euro in Cent (Geld immer als ganze Zahl in Cent, CLAUDE.md).
int eurosToCents(int euros) => euros * 100;

/// Geburtsjahre zur Auswahl, neueste zuerst: Kinder von 6 bis 17 Jahren.
/// Empfohlen ist Taleria ab 10, aber die Eltern entscheiden.
List<int> selectableBirthYears(DateTime now) => [for (var age = 6; age <= 17; age++) now.year - age];

/// Macht aus einer Eingabe wie „abcd-2345“ den Code „ABCD2345“.
String normalizeLoginCode(String input) => input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

bool isCompleteLoginCode(String input) {
  final code = normalizeLoginCode(input);
  return code.length == loginCodeLength && code.split('').every(loginCodeAlphabet.contains);
}

/// Zeigt den Code in zwei Vierergruppen: „ABCD 2345“.
String formatLoginCode(String code) {
  final normalized = normalizeLoginCode(code);
  if (normalized.length <= 4) return normalized;
  return '${normalized.substring(0, 4)} ${normalized.substring(4)}';
}

extension on String {
  /// Anzahl sichtbarer Zeichen (ohne die Länge von UTF-16-Paaren zu zählen).
  int get characters => runes.length;
}
