import '../../../shared/models/ledger_entry.dart';

class LedgerTransfer {
  final String fromUid;
  final String toUid;
  final int amountCents;

  const LedgerTransfer({
    required this.fromUid,
    required this.toUid,
    required this.amountCents,
  });
}

/// Converte "10", "10,5", "1.234,56" ou "R$ 10,50" em centavos.
int? parseReaisToCents(String raw) {
  var text = raw.trim().replaceAll(RegExp(r'[^\d,.]'), '');
  if (text.isEmpty) return null;

  String intPart;
  String decimals;
  if (text.contains(',')) {
    final index = text.lastIndexOf(',');
    intPart = text.substring(0, index).replaceAll('.', '').replaceAll(',', '');
    decimals = text.substring(index + 1);
  } else if ('.'.allMatches(text).length == 1 && text.split('.').last.length <= 2) {
    final index = text.lastIndexOf('.');
    intPart = text.substring(0, index);
    decimals = text.substring(index + 1);
  } else {
    intPart = text.replaceAll('.', '');
    decimals = '';
  }

  if (intPart.isEmpty) intPart = '0';
  if (decimals.length > 2) return null;
  if (!RegExp(r'^\d+$').hasMatch(intPart) || (decimals.isNotEmpty && !RegExp(r'^\d+$').hasMatch(decimals))) {
    return null;
  }
  decimals = decimals.padRight(2, '0');
  final cents = int.tryParse('$intPart$decimals');
  if (cents == null || cents <= 0) return null;
  return cents;
}

String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final reais = abs ~/ 100;
  final decimals = (abs % 100).toString().padLeft(2, '0');
  final grouped = reais.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
  return '${negative ? '-' : ''}R\$ $grouped,$decimals';
}

String centsToInput(int cents) {
  final abs = cents.abs();
  final reais = abs ~/ 100;
  final decimals = (abs % 100).toString().padLeft(2, '0');
  return '$reais,$decimals';
}

/// Cota de cada participante. A soma fecha [LedgerEntry.amountCents].
Map<String, int> sharesOf(LedgerEntry entry) {
  if (entry.splitMode == LedgerEntry.splitAmounts) {
    return Map<String, int>.from(entry.participants);
  }
  final weights = entry.participants.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final totalWeight = weights.fold<int>(0, (sum, item) => sum + item.value);
  if (totalWeight <= 0 || entry.amountCents <= 0) return {};

  final shares = <String, int>{};
  var allocated = 0;
  for (final item in weights) {
    final share = (entry.amountCents * item.value) ~/ totalWeight;
    shares[item.key] = share;
    allocated += share;
  }
  var remainder = entry.amountCents - allocated;
  var index = 0;
  while (remainder > 0 && weights.isNotEmpty) {
    final key = weights[index % weights.length].key;
    shares[key] = shares[key]! + 1;
    remainder--;
    index++;
  }
  return shares;
}

/// Positivo: a banda deve a essa pessoa. Negativo: ela deve à banda.
Map<String, int> ledgerBalances(List<LedgerEntry> entries) {
  final totals = <String, int>{};
  void add(String uid, int delta) {
    if (uid.isEmpty || delta == 0) return;
    totals[uid] = (totals[uid] ?? 0) + delta;
  }

  for (final entry in entries) {
    add(entry.paidBy, entry.amountCents);
    for (final share in sharesOf(entry).entries) {
      add(share.key, -share.value);
    }
  }
  totals.removeWhere((_, value) => value == 0);
  return totals;
}

/// Menor lista de transferências que zera os saldos.
List<LedgerTransfer> simplifyBalances(Map<String, int> balances) {
  final debtors = <MapEntry<String, int>>[];
  final creditors = <MapEntry<String, int>>[];
  for (final entry in balances.entries) {
    if (entry.value < 0) debtors.add(MapEntry(entry.key, -entry.value));
    if (entry.value > 0) creditors.add(MapEntry(entry.key, entry.value));
  }
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final transfers = <LedgerTransfer>[];
  var debtorIndex = 0;
  var creditorIndex = 0;
  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final pay = debtors[debtorIndex].value < creditors[creditorIndex].value
        ? debtors[debtorIndex].value
        : creditors[creditorIndex].value;
    if (pay > 0) {
      transfers.add(
        LedgerTransfer(
          fromUid: debtors[debtorIndex].key,
          toUid: creditors[creditorIndex].key,
          amountCents: pay,
        ),
      );
    }
    final remainingDebt = debtors[debtorIndex].value - pay;
    final remainingCredit = creditors[creditorIndex].value - pay;
    if (remainingDebt == 0) {
      debtorIndex++;
    } else {
      debtors[debtorIndex] = MapEntry(debtors[debtorIndex].key, remainingDebt);
    }
    if (remainingCredit == 0) {
      creditorIndex++;
    } else {
      creditors[creditorIndex] = MapEntry(creditors[creditorIndex].key, remainingCredit);
    }
  }
  return transfers;
}

String? validateLedgerEntry(LedgerEntry entry) {
  if (entry.title.trim().isEmpty) return 'Informe um título';
  if (entry.amountCents <= 0) return 'Informe um valor maior que zero';
  if (entry.paidBy.isEmpty) return 'Informe quem pagou';
  if (entry.participants.isEmpty) return 'Escolha quem entra na divisão';
  if (entry.kind == LedgerEntry.kindSettlement) {
    if (entry.participants.length != 1) return 'O acerto é entre duas pessoas';
    if (entry.participants.containsKey(entry.paidBy)) {
      return 'Quem paga o acerto não pode ser quem recebe';
    }
    if (entry.participants.values.first != entry.amountCents) {
      return 'O acerto precisa fechar o valor';
    }
    return null;
  }
  if (entry.splitMode == LedgerEntry.splitAmounts) {
    final sum = entry.participants.values.fold<int>(0, (total, part) => total + part);
    if (sum != entry.amountCents) return 'A soma das partes precisa fechar o total';
  } else if (entry.participants.values.any((weight) => weight <= 0)) {
    return 'As cotas precisam ser maiores que zero';
  }
  return null;
}

String ledgerPersonName(LedgerEntry entry, String uid, {String? liveName}) {
  final live = liveName?.trim() ?? '';
  if (live.isNotEmpty) return live;
  final snapshot = entry.names[uid]?.trim() ?? '';
  if (snapshot.isNotEmpty) return snapshot;
  return 'Nome não definido';
}
