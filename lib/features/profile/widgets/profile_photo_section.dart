import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
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
    final name = x.name.toLowerCase();
    var contentType = 'image/jpeg';
    if (name.endsWith('.png')) {
      contentType = 'image/png';
    } else if (name.endsWith('.webp')) {
      contentType = 'image/webp';
    }
    setState(() => _uploading = true);
    try {
      final ext = contentType == 'image/png'
          ? 'png'
          : (contentType == 'image/webp' ? 'webp' : 'jpg');
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(widget.ownerUserId)
          .child('${widget.profileId}.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final url = await ref.getDownloadURL();
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
        final hint = kIsWeb
            ? ' No Flutter Web é comum faltar CORS no bucket: na raiz do projeto rode '
                '`gsutil cors set storage-cors.json gs://SEU_BUCKET` (veja Console > Storage > bucket).'
            : '';
        final snackDuration =
            kIsWeb ? const Duration(seconds: 10) : const Duration(seconds: 4);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar foto (${e.code}): ${e.message}$hint'),
            duration: snackDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final hint = kIsWeb
            ? ' Se aparecer falha de rede/CORS, aplique `storage-cors.json` no bucket com gsutil.'
            : '';
        final snackDuration =
            kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 4);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar foto: $e$hint'),
            duration: snackDuration,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
