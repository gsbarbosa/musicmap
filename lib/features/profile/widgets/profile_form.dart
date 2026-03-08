import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_input.dart';

/// Formulário reutilizável de perfil de artista
/// Usado em complete-profile e edit-profile
class ProfileForm extends StatefulWidget {
  /// userId obrigatório. initialProfile pode ser null (novo perfil)
  final String userId;
  final UserProfile? initialProfile;
  final void Function(UserProfile profile) onSubmit;
  final bool isLoading;

  const ProfileForm({
    super.key,
    required this.userId,
    this.initialProfile,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _artistNameController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _genreController;
  late TextEditingController _instagramController;
  late TextEditingController _contactController;
  late TextEditingController _spotifyController;
  late TextEditingController _youtubeController;
  late TextEditingController _tiktokController;
  late TextEditingController _bioController;

  String _artistType = AppConstants.artistTypeSolo;
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _artistNameController = TextEditingController(text: p?.artistName ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _stateController = TextEditingController(text: p?.state ?? '');
    _genreController = TextEditingController(text: p?.genre ?? '');
    _instagramController = TextEditingController(text: p?.instagram ?? '');
    _contactController = TextEditingController(text: p?.contact ?? '');
    _spotifyController = TextEditingController(text: p?.spotify ?? '');
    _youtubeController = TextEditingController(text: p?.youtube ?? '');
    _tiktokController = TextEditingController(text: p?.tiktok ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _artistType = p?.artistType ?? AppConstants.artistTypeSolo;
    _interests = List.from(p?.interests ?? []);
  }

  @override
  void dispose() {
    _artistNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _genreController.dispose();
    _instagramController.dispose();
    _contactController.dispose();
    _spotifyController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else {
        _interests.add(interest);
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final now = DateTime.now();
    final profile = UserProfile(
      userId: widget.userId,
      artistName: _artistNameController.text.trim(),
      artistType: _artistType,
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      genre: _genreController.text.trim(),
      instagram: _instagramController.text.trim(),
      contact: _contactController.text.trim(),
      spotify: _spotifyController.text.trim().isEmpty ? null : _spotifyController.text.trim(),
      youtube: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
      tiktok: _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      interests: _interests,
      earlyAccess: true,
      status: 'active',
      createdAt: widget.initialProfile?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSubmit(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PPInput(
            label: 'Nome da banda ou artista *',
            hint: 'Como você ou sua banda se apresenta',
            controller: _artistNameController,
            validator: (v) => Validators.required(v, 'Nome'),
          ),
          const SizedBox(height: 20),
          _buildArtistTypeSelector(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PPInput(
                  label: 'Cidade *',
                  controller: _cityController,
                  validator: (v) => Validators.required(v, 'Cidade'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PPInput(
                  label: 'Estado *',
                  hint: 'UF',
                  controller: _stateController,
                  validator: (v) => Validators.required(v, 'Estado'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PPInput(
            label: 'Gênero musical principal *',
            hint: 'Ex: Rock, MPB, Indie, Eletrônica',
            controller: _genreController,
            validator: (v) => Validators.required(v, 'Gênero'),
          ),
          const SizedBox(height: 20),
          PPInput(
            label: 'Instagram *',
            hint: '@seuusername',
            controller: _instagramController,
            validator: (v) => Validators.required(v, 'Instagram'),
          ),
          const SizedBox(height: 20),
          PPInput(
            label: 'Contato principal *',
            hint: 'Email ou telefone',
            controller: _contactController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => Validators.required(v, 'Contato'),
          ),
          const SizedBox(height: 24),
          Text(
            'Opcionais',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'Spotify',
            hint: 'Link do perfil',
            controller: _spotifyController,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'YouTube',
            hint: 'Link do canal',
            controller: _youtubeController,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'TikTok',
            hint: '@usuario',
            controller: _tiktokController,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'Breve descrição / bio',
            hint: 'Conte um pouco sobre seu projeto',
            controller: _bioController,
            maxLines: 3,
            maxLength: 300,
          ),
          const SizedBox(height: 24),
          Text(
            'Interesse em:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.interestOptions.map<Widget>((opt) {
              final selected = _interests.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: selected,
                onSelected: (_) => _toggleInterest(opt),
                backgroundColor: AppColors.surfaceSecondary,
                selectedColor: AppColors.secondary.withOpacity(0.3),
                checkmarkColor: AppColors.secondary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.secondary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          PPButton(
            label: 'Salvar perfil',
            onPressed: _submit,
            isLoading: widget.isLoading,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildArtistTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.artistTypes.map((type) {
            final selected = _artistType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _artistType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF7C5CFF).withOpacity(0.2)
                          : const Color(0xFF2A2F36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7C5CFF)
                            : const Color(0xFF313742),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : null,
                          color: selected ? const Color(0xFF7C5CFF) : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
