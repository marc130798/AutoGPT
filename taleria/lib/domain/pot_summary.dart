import 'budget_models.dart';

/// Eine Zeile der Übersicht: alle Buchungen einer Art in eine Richtung.
typedef PotSummaryLine = ({LedgerType type, int count, int cents});

/// Wie sich der Stand einer Truhe zusammensetzt (Kinderbereich: Truhe
/// antippen): was dazukam und was wegging, je Art der Buchung.
///
/// Das Kassenbuch lädt nur die neuesten Buchungen. Was davor war, steht
/// zusammen in [older], damit die Summe immer zum Stand vom Server passt.
class PotSummary {
  const PotSummary._({
    required this.pot,
    required this.balance,
    required this.entries,
    required this.incoming,
    required this.outgoing,
    required this.older,
  });

  factory PotSummary.of(Pot pot, {required List<LedgerEntry> ledger, required int balance}) {
    final entries = [
      for (final e in ledger)
        if (e.pot == pot) e,
    ];
    List<PotSummaryLine> lines({required bool positive}) {
      final result = <PotSummaryLine>[];
      for (final type in LedgerType.values) {
        final group = [
          for (final e in entries)
            if (e.type == type && (positive ? e.amountCents > 0 : e.amountCents < 0)) e,
        ];
        if (group.isEmpty) continue;
        result.add((type: type, count: group.length, cents: group.fold(0, (sum, e) => sum + e.amountCents)));
      }
      return result;
    }

    final shown = entries.fold(0, (sum, e) => sum + e.amountCents);
    return PotSummary._(
      pot: pot,
      balance: balance,
      entries: entries,
      incoming: lines(positive: true),
      outgoing: lines(positive: false),
      older: balance - shown,
    );
  }

  final Pot pot;

  /// Stand der Truhe (vom Server).
  final int balance;

  /// Die geladenen Buchungen dieser Truhe, neueste zuerst.
  final List<LedgerEntry> entries;

  /// Was dazukam, je Art (Beträge positiv).
  final List<PotSummaryLine> incoming;

  /// Was wegging, je Art (Beträge negativ).
  final List<PotSummaryLine> outgoing;

  /// Summe der früheren, nicht geladenen Buchungen (meist 0).
  final int older;

  /// Noch nie etwas gebucht.
  bool get isEmpty => entries.isEmpty && older == 0;
}
