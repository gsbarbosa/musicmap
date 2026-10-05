import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../firebase_options.dart';

/// Uma única instância do Realtime Database ligada ao [Firebase.app()] e ao
/// `databaseURL` das [DefaultFirebaseOptions].
///
/// Evita `permission-denied` no Flutter Web quando `FirebaseDatabase.instance`
/// não fica alinhado ao token do Auth.
FirebaseDatabase get appFirebaseDatabase => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
