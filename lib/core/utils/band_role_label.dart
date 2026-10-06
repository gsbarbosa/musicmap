import '../constants/app_constants.dart';

/// O que a pessoa pode fazer na banda, em linguagem de quem toca.
String bandRoleLabel(String role) {
  switch (role) {
    case AppConstants.roleAdmin:
      return 'Convida e edita a banda';
    case AppConstants.roleEditor:
      return 'Monta a agenda';
    case AppConstants.roleViewer:
      return 'Só acompanha';
    case 'owner':
      return 'Dono da banda';
    default:
      return 'Integrante';
  }
}
