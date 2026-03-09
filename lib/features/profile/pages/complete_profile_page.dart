import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_logo.dart';
import '../widgets/duplicate_profile_dialog.dart';
import '../widgets/profile_form.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
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

    final profileService = ref.read(profileServiceProvider);

    try {
      final isNew = profile.id.isEmpty;
      if (isNew) {
        final atLimit = await profileService.isAtEarlyAccessLimit();
        if (atLimit) {
          setState(() {
            _errorMessage = 'As vagas do pré-lançamento foram esgotadas. Em breve teremos novidades!';
            _isLoading = false;
          });
          return;
        }
        final duplicate = await profileService.findDuplicateProfile(
          profile.artistName,
          profile.instagram,
        );
        if (duplicate != null && mounted) {
          setState(() => _isLoading = false);
          await DuplicateProfileDialog.show(
            context,
            artistName: profile.artistName,
            instagram: profile.instagram,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se você é integrante ou representante oficial, entre em contato conosco para reivindicar o perfil.'),
                backgroundColor: AppColors.surfaceSecondary,
              ),
            );
          }
          return;
        }
      }

      await profileService.saveProfile(profile);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await profileService.markProfileCompleted(user.uid);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                const Text('Perfil salvo com sucesso!'),
              ],
            ),
            backgroundColor: AppColors.surfaceSecondary,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('early_access_limit_reached')
            ? 'As vagas do pré-lançamento foram esgotadas. Em breve teremos novidades!'
            : 'Erro ao salvar perfil. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: PageContainer(
          maxWidth: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Center(child: PPLogo(showTagline: true, fontSize: 32)),
              const SizedBox(height: 48),
              Text(
                'Cadastrar banda/artista',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Conte um pouco sobre você ou sua banda para garantir seu acesso antecipado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
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
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ProfileForm(
                ownerUserId: user.uid,
                onSubmit: _saveProfile,
                isLoading: _isLoading,
                scrollController: _scrollController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
