import 'package:flutter_test/flutter_test.dart';
import 'package:palace_pulse/features/workspace/ledger/ledger_math.dart';
import 'package:palace_pulse/shared/models/ledger_entry.dart';

LedgerEntry _entry({
  required int amountCents,
  required String paidBy,
  required Map<String, int> participants,
  String splitMode = LedgerEntry.splitEqual,
  String kind = LedgerEntry.kindExpense,
}) {
  final now = DateTime(2026, 10, 5);
  return LedgerEntry(
    id: 'e',
    profileId: 'p',
    title: 'Teste',
    kind: kind,
    amountCents: amountCents,
    date: now,
    category: LedgerEntry.categoryOutro,
    paidBy: paidBy,
    splitMode: splitMode,
    participants: participants,
    createdBy: paidBy,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('converte reais com vírgula e milhar', () {
    expect(parseReaisToCents('10'), 1000);
    expect(parseReaisToCents('10,5'), 1050);
    expect(parseReaisToCents('R\$ 1.234,56'), 123456);
    expect(parseReaisToCents('0'), isNull);
    expect(parseReaisToCents('10,999'), isNull);
  });

  test('divide igual e distribui o centavo que sobra', () {
    final shares = sharesOf(
      _entry(amountCents: 100, paidBy: 'a', participants: {'c': 1, 'a': 1, 'b': 1}),
    );
    expect(shares, {'a': 34, 'b': 33, 'c': 33});
    expect(shares.values.reduce((a, b) => a + b), 100);
  });

  test('cotas 2 e 1 fecham o valor', () {
    final shares = sharesOf(
      _entry(
        amountCents: 300,
        paidBy: 'a',
        splitMode: LedgerEntry.splitShares,
        participants: {'a': 2, 'b': 1},
      ),
    );
    expect(shares, {'a': 200, 'b': 100});
  });

  test('despesa igual deixa o pagador credor', () {
    final balances = ledgerBalances([
      _entry(amountCents: 3000, paidBy: 'a', participants: {'a': 1, 'b': 1, 'c': 1}),
    ]);
    expect(balances['a'], 2000);
    expect(balances['b'], -1000);
    expect(balances['c'], -1000);
  });

  test('cachê recebido por uma pessoa gera o que os outros devem', () {
    final balances = ledgerBalances([
      _entry(
        amountCents: 40000,
        paidBy: 'batera',
        kind: LedgerEntry.kindIncome,
        participants: {'batera': 1, 'guitarra': 1, 'baixo': 1, 'voz': 1},
      ),
    ]);
    expect(balances['batera'], 30000);
    expect(balances['guitarra'], -10000);
    expect(balances.values.reduce((a, b) => a + b), 0);
  });

  test('acerto reduz a dívida', () {
    final expense = _entry(
      amountCents: 2000,
      paidBy: 'a',
      participants: {'a': 1, 'b': 1},
    );
    final settlement = _entry(
      amountCents: 1000,
      paidBy: 'b',
      kind: LedgerEntry.kindSettlement,
      splitMode: LedgerEntry.splitAmounts,
      participants: {'a': 1000},
    );
    expect(ledgerBalances([expense, settlement]), isEmpty);
  });

  test('sugere o menor número de transferências', () {
    final transfers = simplifyBalances({'a': 5000, 'b': 1000, 'c': -6000});
    expect(transfers, hasLength(2));
    expect(transfers.first.fromUid, 'c');
    expect(transfers.first.toUid, 'a');
    expect(transfers.first.amountCents, 5000);
    expect(transfers.last.amountCents, 1000);
    expect(transfers.last.toUid, 'b');
  });

  test('rejeita partes que não fecham o total', () {
    final error = validateLedgerEntry(
      _entry(
        amountCents: 1000,
        paidBy: 'a',
        splitMode: LedgerEntry.splitAmounts,
        participants: {'a': 400, 'b': 400},
      ),
    );
    expect(error, isNotNull);
  });
}
