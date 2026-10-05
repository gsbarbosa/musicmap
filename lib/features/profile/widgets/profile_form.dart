import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/brazilian_cities.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_dropdown.dart';
import '../../../shared/widgets/pp_input.dart';
import 'profile_photo_section.dart';

/// Formulário reutilizável de perfil de artista
/// Usado em complete-profile e edit-profile
class ProfileForm extends StatefulWidget {
  /// ownerUserId - dono do perfil
  /// initialProfile pode ser null (novo perfil)
  /// scrollController - para rolar ao topo quando houver erro de validação
  final String ownerUserId;
  final UserProfile? initialProfile;
  final void Function(UserProfile profile) onSubmit;
  final bool isLoading;
  final ScrollController? scrollController;
  final bool readOnly;

  const ProfileForm({
    super.key,
    required this.ownerUserId,
    this.initialProfile,
    required this.onSubmit,
    this.isLoading = false,
    this.scrollController,
    this.readOnly = false,
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
  String? _selectedState;
  String? _selectedCity;
  String? _selectedGenre;
  List<String> _interests = [];
  bool _declarationAccepted = false;
  late bool _publicProfile;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _publicProfile = p?.publicProfile ?? true;
    _photoUrl = p?.photoUrl;
    _artistNameController = TextEditingController(text: p?.artistName ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _stateController = TextEditingController(text: p?.state ?? '');
    _genreController = TextEditingController(text: p?.genre ?? '');
    _selectedState = p?.state?.trim().isNotEmpty == true ? p!.state.toUpperCase() : null;
    _selectedCity = p?.city?.trim().isNotEmpty == true ? p!.city : null;
    if (_selectedCity != null &&
        _selectedState != null &&
        !(brazilianCitiesByState[_selectedState] ?? []).contains(_selectedCity)) {
      _cityController.text = _selectedCity!;
      _selectedCity = otherCityValue;
    }
    _selectedGenre = p?.genre?.trim().isNotEmpty == true ? p!.genre : null;
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

  List<DropdownMenuItem<String>> _buildCityDropdownItems() {
    if (_selectedState == null) {
      return [const DropdownMenuItem(value: null, child: Text('Selecione o estado primeiro'))];
    }
    final cities = brazilianCitiesByState[_selectedState] ?? [];
    return [
      const DropdownMenuItem(value: null, child: Text('Selecione...')),
      ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
      const DropdownMenuItem(value: otherCityValue, child: Text('Outra (informar)')),
    ];
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

  void _scrollToTop() {
    widget.scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _submit() {
    if (widget.readOnly) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifique os campos obrigatórios (marcados com *).')),
        );
      }
      _scrollToTop();
      return;
    }
    final isNewProfile = widget.initialProfile == null;
    if (isNewProfile && !_declarationAccepted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aceite a declaração no final do formulário para continuar.')),
        );
      }
      _scrollToTop();
      return;
    }

    final city = _selectedCity == otherCityValue
        ? _cityController.text.trim()
        : (_selectedCity ?? '');
    final state = _selectedState ?? _stateController.text.trim();
    if (city.isEmpty || state.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione estado e cidade.')),
        );
      }
      _scrollToTop();
      return;
    }

    final now = DateTime.now();
    final profile = UserProfile(
      id: widget.initialProfile?.id ?? '',
      ownerUserId: widget.ownerUserId,
      artistName: _artistNameController.text.trim(),
      artistType: _artistType,
      city: city,
      state: state,
      genre: _selectedGenre ?? _genreController.text.trim(),
      instagram: _instagramController.text.trim(),
      contact: _contactController.text.trim(),
      spotify: _spotifyController.text.trim().isEmpty ? null : _spotifyController.text.trim(),
      youtube: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
      tiktok: _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      interests: _interests,
      earlyAccess: widget.initialProfile?.earlyAccess ?? true,
      status: widget.initialProfile?.status ?? 'active',
      publicProfile: _publicProfile,
      photoUrl: _photoUrl,
      createdAt: widget.initialProfile?.createdAt ?? now,
      updatedAt: now,
      representationDeclarationAcceptedAt:
          isNewProfile ? now : widget.initialProfile?.representationDeclarationAcceptedAt,
    );

    widget.onSubmit(profile);
  }

  @override
  Widget build(BuildContext context) {
    final ro = widget.readOnly;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ro) ...[
            Material(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.visibility_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Você tem acesso somente leitura a estes dados.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (widget.initialProfile != null && widget.initialProfile!.id.isNotEmpty) ...[
            ProfilePhotoSection(
              ownerUserId: widget.ownerUserId,
              profileId: widget.initialProfile!.id,
              photoUrl: _photoUrl,
              onUrlChanged: (u) => setState(() => _photoUrl = u),
              allowUpload: !ro,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Perfil público'),
              subtitle: Text(
                _publicProfile
                    ? 'Seu perfil pode aparecer no link compartilhável e na descoberta pública.'
                    : 'Seu perfil fica oculto da página pública.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _publicProfile,
              onChanged: ro ? null : (v) => setState(() => _publicProfile = v),
            ),
            const SizedBox(height: 16),
          ],
          PPInput(
            label: 'Nome da banda ou artista *',
            hint: 'Como você ou sua banda se apresenta',
            controller: _artistNameController,
            enabled: !ro,
            validator: (v) => Validators.required(v, 'Nome'),
          ),
          const SizedBox(height: 20),
          IgnorePointer(ignoring: ro, child: _buildArtistTypeSelector()),
          const SizedBox(height: 20),
          PPDropdown<String>(
            label: 'Estado *',
            hint: 'Selecione o estado',
            value: _selectedState,
            enabled: !ro,
            items: [
              const DropdownMenuItem(value: null, child: Text('Selecione...')),
              ...AppConstants.brazilianStates.map(
                (e) => DropdownMenuItem(value: e.key, child: Text('${e.key} - ${e.value}')),
              ),
            ],
            onChanged: (v) {
              setState(() {
                _selectedState = v;
                _selectedCity = null;
                _cityController.clear();
              });
            },
            validator: (v) => v == null || v.isEmpty ? 'Selecione o estado' : null,
          ),
          const SizedBox(height: 20),
          PPDropdown<String>(
            label: 'Cidade *',
            hint: _selectedState == null ? 'Selecione o estado primeiro' : 'Selecione a cidade',
            value: _selectedCity,
            enabled: !ro,
            items: _buildCityDropdownItems(),
            onChanged: _selectedState == null
                ? null
                : (v) => setState(() => _selectedCity = v),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Selecione a cidade';
              if (v == otherCityValue && _cityController.text.trim().isEmpty) {
                return 'Informe o nome da cidade';
              }
              return null;
            },
          ),
          if (_selectedCity == otherCityValue) ...[
            const SizedBox(height: 16),
            PPInput(
              label: 'Nome da cidade *',
              hint: 'Digite sua cidade',
              controller: _cityController,
              enabled: !ro,
              validator: (v) => _selectedCity == otherCityValue && (v == null || v.trim().isEmpty)
                  ? 'Informe o nome da cidade'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 20),
          PPDropdown<String>(
            label: 'Gênero musical principal *',
            hint: 'Selecione o gênero',
            value: _selectedGenre,
            enabled: !ro,
            items: [
              const DropdownMenuItem(value: null, child: Text('Selecione...')),
              ...AppConstants.musicGenres.map(
                (g) => DropdownMenuItem(value: g, child: Text(g)),
              ),
            ],
            onChanged: (v) => setState(() => _selectedGenre = v),
            validator: (v) => v == null || v.isEmpty ? 'Selecione o gênero' : null,
          ),
          const SizedBox(height: 20),
          PPInput(
            label: 'Instagram *',
            hint: '@seuusername',
            controller: _instagramController,
            enabled: !ro,
            validator: (v) => Validators.required(v, 'Instagram'),
          ),
          const SizedBox(height: 20),
          PPInput(
            label: 'Contato principal *',
            hint: 'Email ou telefone',
            controller: _contactController,
            enabled: !ro,
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
            enabled: !ro,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'YouTube',
            hint: 'Link do canal',
            controller: _youtubeController,
            enabled: !ro,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'TikTok',
            hint: '@usuario',
            controller: _tiktokController,
            enabled: !ro,
          ),
          const SizedBox(height: 16),
          PPInput(
            label: 'Breve descrição / bio',
            hint: 'Conte um pouco sobre seu projeto',
            controller: _bioController,
            enabled: !ro,
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
                onSelected: ro ? null : (_) => _toggleInterest(opt),
                backgroundColor: AppColors.surfaceSecondary,
                selectedColor: AppColors.secondary.withOpacity(0.3),
                checkmarkColor: AppColors.secondary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.secondary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          if (widget.initialProfile == null) ...[
            const SizedBox(height: 24),
            _buildDeclarationCheckbox(context),
          ],
          const SizedBox(height: 40),
          if (!ro)
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

  Widget _buildDeclarationCheckbox(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _declarationAccepted = !_declarationAccepted),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _declarationAccepted ? AppColors.primary : AppColors.border,
            width: _declarationAccepted ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _declarationAccepted,
                onChanged: (v) => setState(() => _declarationAccepted = v ?? false),
                fillColor: WidgetStateProperty.resolveWith((_) =>
                    _declarationAccepted ? AppColors.primary : AppColors.border),
                checkColor: AppColors.backgroundPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppConstants.representationDeclaration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
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
