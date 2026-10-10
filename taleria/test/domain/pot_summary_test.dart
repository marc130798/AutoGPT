import 'package:flutter_test/flutter_test.dart';
import 'package:taleria/domain/budget_models.dart';
import 'package:taleria/domain/pot_summary.dart';

/// Übersicht einer Truhe: Summen je Art und Richtung, passend zum Stand.
void main() {
  var n = 0;
  LedgerEntry entry(Pot pot, int cents, LedgerType type) =>
      LedgerEntry(id: 'e${n++}', pot: pot, amountCents: cents, type: type, createdAt: DateTime(2026, 10, 9));

  test('Summen je Art, nur Buchungen dieser Truhe', () {
    final ledger = [
      entry(Pot.spend, 500, LedgerType.allowance),
      entry(Pot.spend, 500, LedgerType.allowance),
      entry(Pot.spend, 300, LedgerType.task),
      entry(Pot.spend, -200, LedgerType.transfer),
      entry(Pot.save, 200, LedgerType.transfer),
      entry(Pot.spend, -150, LedgerType.purchase),
    ];
    final s = PotSummary.of(Pot.spend, ledger: ledger, balance: 950);
    expect(s.entries, hasLength(5));
    expect(s.incoming, [
      (type: LedgerType.allowance, count: 2, cents: 1000),
      (type: LedgerType.task, count: 1, cents: 300),
    ]);
    expect(s.outgoing, [
      (type: LedgerType.transfer, count: 1, cents: -200),
      (type: LedgerType.purchase, count: 1, cents: -150),
    ]);
    expect(s.older, 0);
    expect(s.isEmpty, isFalse);
  });

  test('Umgepackt hinein und hinaus stehen getrennt', () {
    final ledger = [entry(Pot.save, 400, LedgerType.transfer), entry(Pot.save, -100, LedgerType.transfer)];
    final s = PotSummary.of(Pot.save, ledger: ledger, balance: 300);
    expect(s.incoming.single.cents, 400);
    expect(s.outgoing.single.cents, -100);
  });

  test('Nicht geladene, frühere Buchungen gleichen die Summe aus', () {
    // Das Kassenbuch lädt nur die neuesten Buchungen.
    final s = PotSummary.of(Pot.spend, ledger: [entry(Pot.spend, 300, LedgerType.task)], balance: 1300);
    expect(s.older, 1000);
    final shown = [...s.incoming, ...s.outgoing].fold(0, (sum, l) => sum + l.cents);
    expect(shown + s.older, s.balance);
  });

  test('Leere Truhe', () {
    final s = PotSummary.of(Pot.give, ledger: const [], balance: 0);
    expect(s.isEmpty, isTrue);
    expect(s.incoming, isEmpty);
    expect(s.outgoing, isEmpty);
  });
}
