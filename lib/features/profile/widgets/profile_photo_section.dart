import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../firebase_options.dart';
import '../../../shared/widgets/pp_button.dart';

/// Upload de foto da banda (Storage) — o URL é repassado ao formulário; o usuário salva o perfil em seguida.
class ProfilePhotoSection extends StatefulWidget {
  final String ownerUserId;
  final String profileId;
  final String? photoUrl;
  final ValueChanged<String?> onUrlChanged;
  final bool allowUpload;

  const ProfilePhotoSection({
    super.key,
    required this.ownerUserId,
    required this.profileId,
    required this.photoUrl,
    required this.onUrlChanged,
    this.allowUpload = true,
  });

  @override
  State<ProfilePhotoSection> createState() => _ProfilePhotoSectionState();
}

class _ProfilePhotoSectionState extends State<ProfilePhotoSection> {
  bool _uploading = false;

  static const _maxBytes = 5 * 1024 * 1024;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (bytes.length > _maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem muito grande (máx. 5 MB).')),
        );
      }
      return;
    }
    final contentType = _contentTypeOf(x);
    setState(() => _uploading = true);
    try {
      final ext = _extensionFor(contentType);
      final objectPath = 'profile_photos/${widget.ownerUserId}/${widget.profileId}.$ext';
      final url = kIsWeb
          ? await _uploadOnWeb(bytes, objectPath, contentType)
          : await _uploadWithSdk(bytes, objectPath, contentType);
      widget.onUrlChanged(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto enviada. Toque em Salvar perfil para confirmar.'),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        final denied = e.code == 'unauthorized' || e.code == 'unauthenticated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              denied
                  ? 'Não foi possível enviar a foto. Saia, entre de novo e tente outra vez.'
                  : 'Não foi possível enviar a foto. Tente de novo em instantes.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar a foto. Tente de novo em instantes.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _contentTypeOf(XFile file) {
    final mime = file.mimeType?.split(';').first.trim().toLowerCase();
    if (mime != null && mime.startsWith('image/')) return mime;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _extensionFor(String contentType) {
    if (contentType == 'image/png') return 'png';
    if (contentType == 'image/webp') return 'webp';
    return 'jpg';
  }

  Future<String> _uploadWithSdk(Uint8List bytes, String objectPath, String contentType) async {
    final ref = FirebaseStorage.instance.ref(objectPath);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// No navegador o SDK sobe em modo resumível e as regras recusam o arquivo.
  /// O envio simples manda o tipo e o tamanho na mesma requisição.
  Future<String> _uploadOnWeb(Uint8List bytes, String objectPath, String contentType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'unauthenticated');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'unauthenticated');
    }
    final bucket = DefaultFirebaseOptions.currentPlatform.storageBucket;
    final uri = Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/$bucket/o',
      {'uploadType': 'media', 'name': objectPath},
    );
    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Firebase $token',
        'Content-Type': contentType,
      },
      body: bytes,
    );
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'unauthorized');
    }
    if (resp.statusCode != 200) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'unknown');
    }
    final data = jsonDecode(resp.body);
    if (data is! Map) {
      throw FirebaseException(plugin: 'firebase_storage', code: 'unknown');
    }
    final name = data['name']?.toString() ?? objectPath;
    final encoded = name.split('/').map(Uri.encodeComponent).join('%2F');
    final downloadToken = data['downloadTokens']?.toString().split(',').first.trim();
    final tokenQuery = (downloadToken == null || downloadToken.isEmpty)
        ? 'alt=media'
        : 'alt=media&token=$downloadToken';
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded?$tokenQuery';
  }

  Future<void> _remove() async {
    final url = widget.photoUrl;
    widget.onUrlChanged(null);
    if (url != null && url.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto da banda', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surfaceSecondary,
              backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                  ? NetworkImage(widget.photoUrl!)
                  : null,
              child: widget.photoUrl == null || widget.photoUrl!.isEmpty
                  ? const Icon(Icons.music_note_rounded, size: 36)
                  : null,
            ),
            const SizedBox(width: 16),
            if (widget.allowUpload)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PPButton(
                      label: 'Escolher imagem',
                      onPressed: _pickAndUpload,
                      isLoading: _uploading,
                      variant: PPButtonVariant.outline,
                    ),
                    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                      TextButton(
                        onPressed: _uploading ? null : _remove,
                        child: const Text('Remover foto'),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (widget.allowUpload)
          Text(
            'JPEG, PNG ou WebP · até 5 MB',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
