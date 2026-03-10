import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_input.dart';
import '../../../shared/widgets/pp_logo.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _declarationAccepted = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Widget _buildLegalLinks(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Ao criar conta você concorda com os ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        GestureDetector(
          onTap: () => context.go('/terms'),
          child: const Text(
            'Termos de Uso',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          ' e ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        GestureDetector(
          onTap: () => context.go('/privacy'),
          child: const Text(
            'Política de Privacidade',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text(
          '.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String? _confirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return Validators.password(value);
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final atLimit = await ref.read(profileServiceProvider).isAtEarlyAccessLimit();
      if (atLimit) {
        setState(() {
          _errorMessage = 'As vagas do pré-lançamento foram esgotadas. Em breve teremos novidades!';
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Continua se falhar ao verificar limite
    }

    if (!(_formKey.currentState?.validate() ?? false) || !_declarationAccepted) {
      setState(() => _isLoading = false);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    try {
      final auth = ref.read(authServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final cred = await auth.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (cred.user != null) {
        await profileService.createUserRecord(
          cred.user!.uid,
          cred.user!.email ?? '',
          accountType: 'band',
          representationDeclarationAcceptedAt: DateTime.now().toIso8601String(),
        );
      }
      if (mounted) context.go('/complete-profile');
    } on Exception catch (e) {
      final auth = ref.read(authServiceProvider);
      final code = e.toString().contains(']')
          ? e.toString().split(']').last.trim().split('.').first
          : '';
      setState(() {
        _errorMessage = auth.getAuthErrorMessage(code);
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      final atLimit = await ref.read(profileServiceProvider).isAtEarlyAccessLimit();
      if (atLimit) {
        setState(() {
          _errorMessage = 'As vagas do pré-lançamento foram esgotadas. Em breve teremos novidades!';
          _isGoogleLoading = false;
        });
        return;
      }
      final auth = ref.read(authServiceProvider);
      final profileService = ref.read(profileServiceProvider);
      final cred = await auth.signInWithGoogle();
      if (cred == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      if (cred.additionalUserInfo?.isNewUser == true && cred.user != null) {
        await profileService.createUserRecord(
          cred.user!.uid,
          cred.user!.email ?? '',
          accountType: 'band',
          // Declaração será coletada no complete-profile
        );
      }
      if (mounted) context.go('/dashboard');
    } on Exception catch (e) {
      final auth = ref.read(authServiceProvider);
      final code = e.toString().contains(']')
          ? e.toString().split(']').last.trim().split('.').first
          : '';
      setState(() {
        _errorMessage = auth.getAuthErrorMessage(code);
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: PageContainer(
            maxWidth: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: PPLogo(showTagline: true, fontSize: 36)),
                const SizedBox(height: 48),
                Text(
                  'Criar conta',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use o email para criar sua conta no mapa.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      PPInput(
                        label: 'Email',
                        hint: 'seu@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        onChanged: (_) => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 20),
                      PPInput(
                        label: 'Senha',
                        hint: 'Mínimo 6 caracteres',
                        controller: _passwordController,
                        obscureText: true,
                        validator: Validators.password,
                        onChanged: (_) => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 20),
                      PPInput(
                        label: 'Confirmar senha',
                        hint: 'Repita a senha',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        validator: _confirmPassword,
                        onChanged: (_) => setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 24),
                      _buildDeclarationCheckbox(context),
                      const SizedBox(height: 16),
                      _buildLegalLinks(context),
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
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      PPButton(
                        label: 'Criar conta',
                        onPressed: _submit,
                        isLoading: _isLoading,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('ou', style: Theme.of(context).textTheme.bodySmall),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PPButton(
                        label: 'Continuar com Google',
                        icon: Icons.g_mobiledata_rounded,
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        isLoading: _isGoogleLoading,
                        fullWidth: true,
                        variant: PPButtonVariant.outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem conta? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
