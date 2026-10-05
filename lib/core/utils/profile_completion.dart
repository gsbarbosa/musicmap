import '../../shared/models/user_profile.dart';

/// Itens do checklist e pesos para a barra de progresso do perfil
class ProfileCompletion {
  final bool basicComplete;
  final bool bioComplete;
  final bool streamingComplete;
  final bool interestsComplete;

  const ProfileCompletion({
    required this.basicComplete,
    required this.bioComplete,
    required this.streamingComplete,
    required this.interestsComplete,
  });

  /// Quatro blocos com peso igual (25% cada)
  int get percent {
    var n = 0;
    if (basicComplete) n += 25;
    if (bioComplete) n += 25;
    if (streamingComplete) n += 25;
    if (interestsComplete) n += 25;
    return n;
  }

  bool get allComplete =>
      basicComplete && bioComplete && streamingComplete && interestsComplete;

  static ProfileCompletion fromProfile(UserProfile p) {
    final basic = p.artistName.trim().isNotEmpty &&
        p.city.trim().isNotEmpty &&
        p.state.trim().length == 2 &&
        p.genre.trim().isNotEmpty &&
        p.instagram.trim().isNotEmpty &&
        p.contact.trim().isNotEmpty;
    final bio = (p.bio?.trim().isNotEmpty ?? false);
    final streaming = (p.spotify?.trim().isNotEmpty ?? false) ||
        (p.youtube?.trim().isNotEmpty ?? false) ||
        (p.tiktok?.trim().isNotEmpty ?? false);
    final interests = p.interests.isNotEmpty;
    return ProfileCompletion(
      basicComplete: basic,
      bioComplete: bio,
      streamingComplete: streaming,
      interestsComplete: interests,
    );
  }
}
