import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_card.dart';
import '../../../shared/widgets/pp_logo.dart';
import '../../profile/services/profile_view_service.dart';

/// Página pública `/artist/:profileId` (sem login)
class PublicArtistPage extends ConsumerWidget {
  final String profileId;

  const PublicArtistPage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userProfileProvider(profileId));

    return async.when(
      data: (profile) {
        if (profile == null) {
          return _NotFound(onHome: () => context.go('/'));
        }
        final visible = profile.status == 'active' && profile.publicProfile;
        if (!visible) {
          return _NotFound(onHome: () => context.go('/'));
        }
        return _PublicBody(profile: profile);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: _NotFound(onHome: () => context.go('/')),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  final VoidCallback onHome;

  const _NotFound({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PageContainer(
        maxWidth: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Perfil não encontrado ou indisponível',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(onPressed: onHome, child: const Text('Ir para a página inicial')),
          ],
        ),
      ),
    );
  }
}

class _PublicBody extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _PublicBody({required this.profile});

  @override
  ConsumerState<_PublicBody> createState() => _PublicBodyState();
}

class _PublicBodyState extends ConsumerState<_PublicBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      recordPublicProfileView(widget.profile.id);
    });
  }

  Future<void> _open(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    var u = url.trim();
    if (!u.startsWith('http')) u = 'https://$u';
    final uri = Uri.tryParse(u);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: PageContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PPLogo(showTagline: false, fontSize: 22),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Music Map'),
                    ),
                  ],
                ),
              ),
            ),
            PageContainer(
              maxWidth: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(p.photoUrl!),
                        )
                      else
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceSecondary,
                          child: Icon(Icons.music_note_rounded, size: 36),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.artistName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.city} – ${p.state}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bio, cidade, links e contato.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _infoRow(context, 'Gênero', p.genre),
                  _linkRow(context, 'Instagram', p.instagram, () {
                    final ig = p.instagram.replaceAll('@', '');
                    _open('https://instagram.com/$ig');
                  }),
                  _infoRow(context, 'Contato', p.contact),
                  if (p.spotify != null && p.spotify!.trim().isNotEmpty)
                    _linkRow(context, 'Spotify', p.spotify!, () => _open(p.spotify)),
                  if (p.youtube != null && p.youtube!.trim().isNotEmpty)
                    _linkRow(context, 'YouTube', p.youtube!, () => _open(p.youtube)),
                  if (p.tiktok != null && p.tiktok!.trim().isNotEmpty)
                    _linkRow(context, 'TikTok', p.tiktok!, () => _open(p.tiktok)),
                  if (p.bio != null && p.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Sobre', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      p.bio!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  PPCard(
                    child: Text(
                      'Quer cadastrar sua banda no ${AppConstants.appName}? '
                      'Entre ou crie uma conta para organizar agenda, tarefas e lançamentos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Criar conta'),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _linkRow(BuildContext context, String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
