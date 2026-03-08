// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Configuração do Firebase
///
/// Para gerar automaticamente: execute `dart run flutterfire_cli:flutterfire configure`
/// ou substitua os valores abaixo pelos do seu projeto no Firebase Console.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: 'AIzaSyCvi8ONz_r64wdgUvvtsBw8JCY2H-9Gxbg',
      authDomain: 'palacepulse-2262c.firebaseapp.com',
      databaseURL: 'https://palacepulse-2262c-default-rtdb.firebaseio.com',
      projectId: 'palacepulse-2262c',
      storageBucket: 'palacepulse-2262c.firebasestorage.app',
      messagingSenderId: '968493250566',
      appId: '1:968493250566:web:fac018a0237b8eaea32b87',
    );
  }
}
