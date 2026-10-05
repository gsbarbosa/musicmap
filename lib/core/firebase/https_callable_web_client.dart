import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Chama uma Cloud Function `onCall` via HTTP + JSON (protocolo oficial).
///
/// No **Flutter Web**, o plugin `cloud_functions` pode falhar ao converter o
/// resultado (`dartify`) com *Unsupported operation: Int64 accessor not
/// supported by dart2js*. Este cliente evita essa conversão.
Future<dynamic> postHttpsCallableJson({
  required String functionName,
  required Map<String, dynamic> data,
  String region = 'us-central1',
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw FirebaseFunctionsException(
      code: 'unauthenticated',
      message: 'Faça login para continuar.',
    );
  }
  final token = await user.getIdToken();
  final projectId = Firebase.app().options.projectId;
  if (projectId.isEmpty) {
    throw FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'Projeto Firebase sem projectId.',
    );
  }
  final uri = Uri.parse(
    'https://$region-$projectId.cloudfunctions.net/$functionName',
  );
  final resp = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'data': data}),
  );

  final Map<String, dynamic> decoded;
  try {
    final raw = jsonDecode(resp.body);
    if (raw is! Map) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Resposta inválida da função (${resp.statusCode}).',
      );
    }
    decoded = Map<String, dynamic>.from(
      raw.map((k, v) => MapEntry(k.toString(), v)),
    );
  } on FirebaseFunctionsException {
    rethrow;
  } catch (_) {
    throw FirebaseFunctionsException(
      code: 'internal',
      message: 'Não foi possível ler a resposta (${resp.statusCode}).',
    );
  }

  if (decoded['error'] != null) {
    final err = decoded['error'];
    if (err is Map) {
      final msg = err['message']?.toString() ?? 'Erro na função';
      final status = err['status']?.toString();
      throw FirebaseFunctionsException(
        code: _httpsErrorStatusToFunctionsCode(status),
        message: msg,
      );
    }
    throw FirebaseFunctionsException(
      code: 'internal',
      message: err.toString(),
    );
  }

  return decoded['result'];
}

String _httpsErrorStatusToFunctionsCode(String? status) {
  if (status == null || status.isEmpty) return 'internal';
  return status.toLowerCase().replaceAll('_', '-');
}
