import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';

/// Escrita via REST API do Realtime Database com `?auth=<ID token>`.
///
/// No Flutter Web o SDK às vezes não associa o JWT ao WebSocket; o refresh em
/// `securetoken.googleapis.com` aparece, mas o PUT no RTDB falha com
/// `permission-denied`. O REST com `auth` no query é o método oficial para
/// enviar o ID token em cada requisição.
class RtdbRestClient {
  RtdbRestClient._();

  static String get _baseUrl {
    final u = DefaultFirebaseOptions.currentPlatform.databaseURL!;
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  static String _encodedPath(String path) {
    final segments = path.split('/')..removeWhere((s) => s.isEmpty);
    return segments.map(Uri.encodeComponent).join('/');
  }

  static Uri _uri(String path, String idToken) {
    final p = _encodedPath(path);
    return Uri.parse('$_baseUrl/$p.json').replace(
      queryParameters: {'auth': idToken},
    );
  }

  /// GET com `?auth=` (útil no Web quando o SDK não envia JWT no WebSocket).
  static Future<dynamic> getJson(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('no_id_token');
    }
    final uri = _uri(path, token);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('RTDB REST GET ${resp.statusCode}: ${resp.body}');
    }
    final body = resp.body.trim();
    if (body.isEmpty || body == 'null') return null;
    return jsonDecode(body);
  }

  /// [ServerValue.increment] via REST (documentação Firebase: `.sv.increment`).
  static Future<void> incrementAtPath(String path, int delta) async {
    await putJson(path, {'.sv': {'increment': delta}});
  }

  static Future<void> putJson(String path, Object? value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('no_id_token');
    }
    final uri = _uri(path, token);
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(value),
    );
    if (resp.statusCode != 200) {
      throw Exception('RTDB REST PUT ${resp.statusCode}: ${resp.body}');
    }
  }

  static Future<void> patchJson(String path, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('no_id_token');
    }
    final uri = _uri(path, token);
    final resp = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (resp.statusCode != 200) {
      throw Exception('RTDB REST PATCH ${resp.statusCode}: ${resp.body}');
    }
  }

  /// Remove nó (rollback se falhar vínculo após criar perfil).
  static Future<void> delete(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('not_authenticated');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('no_id_token');
    }
    final uri = _uri(path, token);
    final resp = await http.delete(uri);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('RTDB REST DELETE ${resp.statusCode}: ${resp.body}');
    }
  }
}
