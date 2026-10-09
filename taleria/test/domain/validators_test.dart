import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/validators.dart';

void main() {
  group('E-Mail', () {
    test('gültige Adresse', () => expect(validateEmail(' eltern@beispiel.de '), isNull));
    test('leer', () => expect(validateEmail('  '), EmailProblem.empty));
    test('ohne @', () => expect(validateEmail('eltern.beispiel.de'), EmailProblem.invalid));
    test('ohne Endung', () => expect(validateEmail('eltern@beispiel'), EmailProblem.invalid));
  });

  group('Passwort', () {
    test('mindestens 10 Zeichen', () {
      expect(validatePassword('123456789'), PasswordProblem.tooShort);
      expect(validatePassword('1234567890'), isNull);
    });
  });

  group('Eltern-PIN', () {
    test('4 bis 6 Ziffern sind erlaubt', () {
      expect(validatePin('2468'), isNull);
      expect(validatePin('13579'), isNull);
      expect(validatePin('081547'), isNull);
    });

    test('falsches Format', () {
      for (final pin in ['', '123', '1234567', '12a4', ' 2468']) {
        expect(validatePin(pin), PinProblem.format, reason: pin);
      }
    });

    test('zu leicht zu erraten', () {
      for (final pin in ['0000', '1111', '1234', '4321', '123456', '987654']) {
        expect(validatePin(pin), PinProblem.tooSimple, reason: pin);
      }
    });
  });

  group('Spitzname', () {
    test('erlaubt', () {
      for (final name in ['Mila', 'Lö', 'Ben 2', 'Anna-Lena', "Jo'", '  Ben  ', 'Zoë']) {
        expect(validateNickname(name), isNull, reason: name);
      }
    });

    test('zu kurz oder zu lang', () {
      expect(validateNickname('X'), NicknameProblem.tooShort);
      expect(validateNickname('  X  '), NicknameProblem.tooShort);
      expect(validateNickname('A' * 21), NicknameProblem.tooLong);
      expect(validateNickname('A' * 20), isNull);
    });

    test('ungültige Zeichen oder kein Buchstabe', () {
      for (final name in ['Mila!', 'mila@mail.de', '12', 'https://x']) {
        expect(validateNickname(name), NicknameProblem.invalidCharacters, reason: name);
      }
    });
  });

  test('Geburtsjahre: Kinder von 6 bis 17 Jahren, neuestes zuerst', () {
    final years = selectableBirthYears(DateTime(2026, 10, 9));
    expect(years.first, 2020);
    expect(years.last, 2009);
    expect(years, contains(2016)); // 10 Jahre, empfohlenes Startalter
    expect(years, hasLength(12));
  });

  group('Anmelde-Code', () {
    test('Eingabe wird vereinheitlicht', () {
      expect(normalizeLoginCode('abcd-2345'), 'ABCD2345');
      expect(normalizeLoginCode(' ab cd 23 45 '), 'ABCD2345');
    });

    test('vollständig nur mit 8 erlaubten Zeichen', () {
      expect(isCompleteLoginCode('ABCD 2345'), isTrue);
      expect(isCompleteLoginCode('ABCD234'), isFalse);
      // O, 0, I, 1 und L kommen in Codes nicht vor.
      expect(isCompleteLoginCode('ABCD234O'), isFalse);
      expect(isCompleteLoginCode('ABCD2340'), isFalse);
      expect(isCompleteLoginCode('ABCD2341'), isFalse);
      expect(isCompleteLoginCode('ABCD234L'), isFalse);
    });

    test('Anzeige in zwei Vierergruppen', () {
      expect(formatLoginCode('ABCD2345'), 'ABCD 2345');
    });

    test('Alphabet passt zur Datenbank (31 Zeichen, ohne I, L, O, 0, 1)', () {
      expect(loginCodeAlphabet.length, 31);
      for (final c in ['I', 'L', 'O', '0', '1']) {
        expect(loginCodeAlphabet.contains(c), isFalse, reason: c);
      }
    });
  });
}
