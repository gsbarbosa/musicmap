/// Constantes da aplicação Palace Pulse
class AppConstants {
  AppConstants._();

  // Marca
  static const String appName = 'Palace Pulse';
  static const String appTagline = 'O mapa da cena independente';

  // Firebase paths
  static const String usersPath = 'users';
  static const String profilesPath = 'profiles';
  static const String profilesByOwnerPath = 'profiles_by_owner';

  // Valores de perfil
  static const String artistTypeSolo = 'artista solo';
  static const String artistTypeBand = 'banda';

  static const List<String> artistTypes = [artistTypeSolo, artistTypeBand];

  /// Web Client ID do Google OAuth (Firebase Console > Auth > Sign-in method > Google)
  static const String googleWebClientId =
      '968493250566-8h4k3n4skhn3fgcb2gob6hls1rb6oegf.apps.googleusercontent.com';

  static const List<String> interestOptions = [
    'tocar em shows',
    'collabs',
    'ser encontrado por produtoras',
    'divulgar lançamentos',
  ];
}
