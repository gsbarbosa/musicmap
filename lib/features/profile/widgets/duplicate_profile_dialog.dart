import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pp_button.dart';

/// Dialog exibido quando nome + instagram já estão cadastrados
/// Oferece: reivindicar propriedade (moderação) ou solicitar acesso para gerenciar junto
class DuplicateProfileDialog extends StatelessWidget {
  final String artistName;
  final String instagram;
  final VoidCallback onClaimOwnership;
  final VoidCallback onRequestCoAdmin;

  const DuplicateProfileDialog({
    super.key,
    required this.artistName,
    required this.instagram,
    required this.onClaimOwnership,
    required this.onRequestCoAdmin,
  });

  static Future<String?> show(
    BuildContext context, {
    required String artistName,
    required String instagram,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DuplicateProfileDialog(
        artistName: artistName,
        instagram: instagram,
        onClaimOwnership: () => Navigator.of(context).pop('claim'),
        onRequestCoAdmin: () => Navigator.of(context).pop('coadmin'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Banda já cadastrada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Já existe um perfil para "$artistName" com o Instagram $instagram.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Escolha uma opção:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          _OptionTile(
            icon: Icons.gavel_rounded,
            title: 'Reivindicar propriedade da banda',
            subtitle: 'Acredita que é o dono da marca? Envie à moderação para análise.',
            onTap: onClaimOwnership,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.group_add_rounded,
            title: 'Solicitar acesso para gerenciar junto',
            subtitle: 'É membro da banda? Solicite para editar o perfil junto com quem cadastrou.',
            onTap: onRequestCoAdmin,
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
