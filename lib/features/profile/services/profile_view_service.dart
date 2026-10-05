import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/firebase/https_callable_web_client.dart';

/// Incrementa visualizações da página pública (Cloud Function `recordProfileView`).
Future<void> recordPublicProfileView(String profileId) async {
  try {
    if (kIsWeb) {
      await postHttpsCallableJson(
        functionName: 'recordProfileView',
        data: <String, dynamic>{'profileId': profileId},
      );
    } else {
      final callable =
          FirebaseFunctions.instance.httpsCallable('recordProfileView');
      await callable.call(<String, dynamic>{'profileId': profileId});
    }
  } catch (_) {
    // Função ainda não deployada ou rede — ignora
  }
}
