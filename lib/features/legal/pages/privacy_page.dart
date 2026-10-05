import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_logo.dart';

/// Página de Política de Privacidade
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Center(child: PPLogo(showTagline: true, fontSize: 32)),
            const SizedBox(height: 32),
            Text(
              'Política de Privacidade',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Última atualização: Março de 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 40),
            PageContainer(
              maxWidth: 680,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(context, '1. Coleta de Dados', '''
O ${AppConstants.appName} coleta as informações que você fornece ao criar sua conta e perfil, incluindo:
• E-mail e dados de autenticação (incluindo login com Google);
• Nome da banda ou artista, tipo, estado, cidade, gênero musical;
• Redes sociais (Instagram, Spotify, YouTube, TikTok) e contato;
• Breve descrição (bio) e interesses.
'''),
                  _section(context, '2. Finalidade do Uso', '''
Utilizamos seus dados para:
• Operar e melhorar a plataforma;
• Exibir seu perfil publicamente na plataforma quando aplicável;
• Comunicar atualizações e novidades sobre o ${AppConstants.appName};
• Garantir segurança e cumprimento dos Termos de Uso.
'''),
                  _section(context, '3. Compartilhamento', '''
Seus dados de perfil (nome, cidade, estado, gênero, links) podem ser exibidos publicamente na página do artista e em funcionalidades da plataforma. Não vendemos seus dados a terceiros para fins de marketing.
'''),
                  _section(context, '4. Armazenamento e Segurança', '''
Utilizamos Firebase (Google) para armazenamento e autenticação, em conformidade com práticas de segurança e políticas de privacidade do Google.
'''),
                  _section(context, '5. Seus Direitos', '''
Você pode acessar, editar e excluir seus dados a qualquer momento pela plataforma. Para solicitações adicionais relacionadas à LGPD, entre em contato conosco.
'''),
                  _section(context, '6. Cookies e Tecnologias', '''
A plataforma pode utilizar cookies e tecnologias semelhantes para funcionamento técnico e melhoria da experiência.
'''),
                  _section(context, '7. Alterações', '''
Podemos atualizar esta Política de Privacidade. Alterações relevantes serão comunicadas por e-mail ou aviso na plataforma.
'''),
                  _section(context, '8. Contato', '''
Para dúvidas sobre privacidade, entre em contato conosco pelo e-mail disponível na plataforma.
'''),
                  const SizedBox(height: 48),
                  PPButton(
                    label: 'Voltar',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.go('/'),
                    variant: PPButtonVariant.outline,
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

  Widget _section(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
