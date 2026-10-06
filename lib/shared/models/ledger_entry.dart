/// Lançamento do caixa da banda (`ledger/{profileId}/{entryId}`).
/// Despesa, receita (cachê) e acerto usam o mesmo saldo: quem pagou menos a própria cota.
class LedgerEntry {
  final String id;
  final String profileId;
  final String title;
  /// expense | income | settlement
  final String kind;
  final int amountCents;
  final DateTime date;
  final String category;
  final String paidBy;
  /// equal | shares | amounts
  final String splitMode;
  /// Igual e cotas: peso. Por valor e acerto: centavos.
  final Map<String, int> participants;
  /// Nome no momento do lançamento, para quem sair da banda.
  final Map<String, String> names;
  final String? showId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LedgerEntry({
    required this.id,
    required this.profileId,
    required this.title,
    required this.kind,
    required this.amountCents,
    required this.date,
    required this.category,
    required this.paidBy,
    required this.splitMode,
    required this.participants,
    this.names = const {},
    this.showId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  static const kindExpense = 'expense';
  static const kindIncome = 'income';
  static const kindSettlement = 'settlement';

  static const splitEqual = 'equal';
  static const splitShares = 'shares';
  static const splitAmounts = 'amounts';

  static const categoryTransporte = 'transporte';
  static const categoryEnsaio = 'ensaio';
  static const categoryEstudio = 'estudio';
  static const categoryAlimentacao = 'alimentacao';
  static const categoryEquipamento = 'equipamento';
  static const categoryDivulgacao = 'divulgacao';
  static const categoryCache = 'cache';
  static const categoryOutro = 'outro';
  static const categoryAcerto = 'acerto';

  static const expenseCategories = [
    categoryTransporte,
    categoryEnsaio,
    categoryEstudio,
    categoryAlimentacao,
    categoryEquipamento,
    categoryDivulgacao,
    categoryOutro,
  ];

  static const incomeCategories = [
    categoryCache,
    categoryOutro,
  ];

  static String kindLabel(String kind) {
    switch (kind) {
      case kindIncome:
        return 'Receita';
      case kindSettlement:
        return 'Acerto';
      default:
        return 'Despesa';
    }
  }

  static String categoryLabel(String category) {
    switch (category) {
      case categoryTransporte:
        return 'Transporte';
      case categoryEnsaio:
        return 'Ensaio';
      case categoryEstudio:
        return 'Estúdio';
      case categoryAlimentacao:
        return 'Alimentação';
      case categoryEquipamento:
        return 'Equipamento';
      case categoryDivulgacao:
        return 'Divulgação';
      case categoryCache:
        return 'Cachê';
      case categoryAcerto:
        return 'Acerto';
      default:
        return 'Outro';
    }
  }

  factory LedgerEntry.fromMap(String id, String profileId, Map<String, dynamic> map) {
    return LedgerEntry(
      id: id,
      profileId: profileId,
      title: map['title']?.toString() ?? '',
      kind: map['kind']?.toString() ?? kindExpense,
      amountCents: _asInt(map['amountCents']),
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      category: map['category']?.toString() ?? categoryOutro,
      paidBy: map['paidBy']?.toString() ?? '',
      splitMode: map['splitMode']?.toString() ?? splitEqual,
      participants: _intMap(map['participants']),
      names: _stringMap(map['names']),
      showId: map['showId']?.toString(),
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title.trim(),
      'kind': kind,
      'amountCents': amountCents,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'category': category,
      'paidBy': paidBy,
      'splitMode': splitMode,
      'participants': participants,
      if (names.isNotEmpty) 'names': names,
      if (showId != null && showId!.isNotEmpty) 'showId': showId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, int>{};
    for (final entry in raw.entries) {
      final n = _asInt(entry.value);
      if (n > 0) out[entry.key.toString()] = n;
    }
    return out;
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }
}
