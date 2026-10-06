import 'package:palace_pulse/core/constants/app_constants.dart';

/// Ficha da pessoa (`people/{uid}`). É o artista, separado do projeto/banda.
class PersonCard {
  final String userId;
  final String displayName;
  final List<String> instruments;
  final String city;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonCard({
    required this.userId,
    required this.displayName,
    this.instruments = const [],
    this.city = '',
    this.state = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasName => displayName.trim().length >= 2;

  factory PersonCard.fromMap(String userId, Map<String, dynamic> map) {
    return PersonCard(
      userId: userId,
      displayName: map['displayName']?.toString() ?? '',
      instruments: _instrumentsFrom(map['instruments']),
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName.trim(),
      'instruments': instruments,
      'city': city.trim(),
      'state': state.trim().toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<String> _instrumentsFrom(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where(_allowed).toList();
    }
    if (raw is Map) {
      return raw.keys.map((e) => e.toString()).where(_allowed).toList();
    }
    return const [];
  }

  static bool _allowed(String value) => AppConstants.instrumentOptions.contains(value);
}
