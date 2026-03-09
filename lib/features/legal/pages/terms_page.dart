import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_logo.dart';

/// Página de Termos de Uso
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
              'Termos de Uso',
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
                  _section(context, '1. Aceitação dos Termos', '''
Ao acessar e utilizar o ${AppConstants.appName} (${AppConstants.appTagline}), você concorda em cumprir e estar vinculado a estes Termos de Uso. Se você não concordar com estes termos, não utilize a plataforma.
'''),
                  _section(context, '2. Descrição do Serviço', '''
O ${AppConstants.appName} é uma plataforma para mapeamento e conexão da cena musical independente. Artistas, bandas e gestores podem criar perfis para garantir acesso antecipado a funcionalidades futuras, fazer parte do mapa da cena e conectar-se a oportunidades.
'''),
                  _section(context, '3. Cadastro e Conta', '''
Você declara ao cadastrar-se que:
• Só cadastra bandas ou artistas dos quais é integrante ou representante oficial;
• Não criará perfis em nome de terceiros sem autorização;
• As informações fornecidas são verdadeiras e atualizadas.

O ${AppConstants.appName} reserva-se o direito de suspender ou excluir contas que violem estes termos ou que contenham informações falsas ou enganosas.
'''),
                  _section(context, '4. Uso Adequado', '''
Você se compromete a utilizar o serviço de forma ética e legal, sem publicar conteúdo difamatório, ofensivo, discriminatório ou que viole direitos de terceiros. Não é permitido o uso da plataforma para spam ou fins comerciais não autorizados.
'''),
                  _section(context, '5. Propriedade Intelectual', '''
O conteúdo que você publica em seu perfil (fotos, textos, links) permanece de sua propriedade. Ao publicar, você concede ao ${AppConstants.appName} uma licença para exibir e utilizar esse conteúdo no âmbito da plataforma e para fins de divulgação da cena musical.
'''),
                  _section(context, '6. Limitação de Responsabilidade', '''
O ${AppConstants.appName} é oferecido "como está". Não garantimos disponibilidade ininterrupta ou ausência de erros. Não nos responsabilizamos por danos indiretos decorrentes do uso ou impossibilidade de uso da plataforma.
'''),
                  _section(context, '7. Alterações', '''
Podemos alterar estes Termos de Uso a qualquer momento. Alterações significativas serão comunicadas por e-mail ou aviso na plataforma. O uso continuado após as alterações constitui aceitação dos novos termos.
'''),
                  _section(context, '8. Contato', '''
Para dúvidas sobre estes termos, entre em contato conosco pelo e-mail disponível na plataforma.
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
