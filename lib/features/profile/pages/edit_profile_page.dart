import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/firebase_rtdb_user_message.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_error_state.dart';
import '../../../shared/widgets/workspace_page_scaffold.dart';
import '../widgets/profile_form.dart';

class EditProfilePage extends ConsumerWidget {
  final String profileId;

  const EditProfilePage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(profileId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Perfil não encontrado')),
          );
        }
        return _EditProfileContent(profile: profile);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: PPErrorState(
            debugDetails: e.toString(),
            onRetry: () => ref.invalidate(userProfileProvider(profileId)),
          ),
        ),
      ),
    );
  }
}

class _EditProfileContent extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _EditProfileContent({required this.profile});

  @override
  ConsumerState<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends ConsumerState<_EditProfileContent> {
  final _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(UserProfile profile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(profileServiceProvider).saveProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                const Text('Perfil atualizado com sucesso!'),
              ],
            ),
            backgroundColor: AppColors.surfaceSecondary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = firebaseRtdbSaveUserMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEditAsync = ref.watch(profileCanEditMetadataProvider(widget.profile.id));

    return canEditAsync.when(
      data: (canEdit) {
        return WorkspacePageScaffold(
          title: canEdit ? 'Editar projeto' : 'Projeto (somente leitura)',
          subtitle: widget.profile.artistName,
          leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Voltar',
          ),
          body: PageContainer(
            maxWidth: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(color: AppColors.error))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ProfileForm(
                  ownerUserId: widget.profile.ownerUserId,
                  initialProfile: widget.profile,
                  onSubmit: _saveProfile,
                  isLoading: _isLoading,
                  scrollController: _scrollController,
                  readOnly: !canEdit,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => WorkspacePageScaffold(
        title: 'Projeto',
        subtitle: widget.profile.artistName,
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => WorkspacePageScaffold(
        title: 'Projeto',
        subtitle: widget.profile.artistName,
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar',
        ),
        body: Center(
          child: PPErrorState(
            debugDetails: e.toString(),
            onRetry: () => ref.invalidate(profileCanEditMetadataProvider(widget.profile.id)),
          ),
        ),
      ),
    );
  }
}
