import '../../shared/models/user_profile.dart';

/// Avaliação simples de completude do perfil para o painel operacional
class ProfileCompletenessResult {
  final int percent;
  final bool isIncomplete;
  final List<String> hints;

  const ProfileCompletenessResult({
    required this.percent,
    required this.isIncomplete,
    required this.hints,
  });
}

ProfileCompletenessResult evaluateProfileCompleteness(UserProfile p) {
  final hints = <String>[];
  var points = 0;
  const total = 6;

  if (p.artistName.trim().isNotEmpty) {
    points++;
  } else {
    hints.add('Nome artístico');
  }

  if (p.city.trim().isNotEmpty && p.state.trim().isNotEmpty) {
    points++;
  } else {
    hints.add('Cidade e estado');
  }

  if (p.genre.trim().isNotEmpty) {
    points++;
  } else {
    hints.add('Gênero musical');
  }

  if ((p.bio ?? '').trim().length >= 40) {
    points++;
  } else {
    hints.add('Bio (pelo menos ~40 caracteres)');
  }

  if (p.instagram.trim().isNotEmpty || p.contact.trim().isNotEmpty) {
    points++;
  } else {
    hints.add('Instagram ou outro contato');
  }

  if (p.photoUrl != null && p.photoUrl!.trim().isNotEmpty) {
    points++;
  } else {
    hints.add('Foto do perfil');
  }

  final percent = ((points / total) * 100).round();
  return ProfileCompletenessResult(
    percent: percent,
    isIncomplete: points < total,
    hints: hints,
  );
}
