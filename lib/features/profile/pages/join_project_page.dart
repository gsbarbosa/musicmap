import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/share_url.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/pp_button.dart';
import '../../../shared/widgets/pp_input.dart';
import '../../../shared/widgets/pp_logo.dart';

/// Aceita convite por link (`/join/:token`) ou por código colado.
class JoinProjectPage extends ConsumerStatefulWidget {
  const JoinProjectPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<JoinProjectPage> createState() => _JoinProjectPageState();
}

class _JoinProjectPageState extends ConsumerState<JoinProjectPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _started = false;
  String? _error;

  bool get _fromLink => widget.token != null && widget.token!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_fromLink) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _acceptIfSignedIn());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String? get _joinPath => _fromLink ? safeJoinPath('/join/${widget.token}') : null;

  Future<void> _acceptIfSignedIn() async {
    if (_started || FirebaseAuth.instance.currentUser == null) return;
    await _accept(widget.token!);
  }

  Future<void> _submitCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Cole o código ou abra o link enviado pela banda.');
      return;
    }
    await _accept(code);
  }

  Future<void> _accept(String raw) async {
    final code = raw.trim();
    if (_started) return;
    _started = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(profileServiceProvider).acceptInviteWithCallable(code);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      ref.invalidate(userProfilesProvider(uid));
      final profileId = result['profileId']?.toString();
      if (profileId != null && profileId.isNotEmpty) {
        ref.read(dashboardWorkspaceProfileIdProvider.notifier).state = profileId;
      }
      if (!mounted) return;
      context.go('/dashboard');
    } on FirebaseFunctionsException catch (e) {
      _started = false;
      setState(() {
        _loading = false;
        _error = _messageForFunctionsException(e);
      });
    } catch (e) {
      _started = false;
      setState(() {
        _loading = false;
        _error = 'Não foi possível entrar no projeto. Tente de novo.';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final cred = await auth.signInWithGoogle();
      if (cred == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (cred.additionalUserInfo?.isNewUser == true && cred.user != null) {
        await ref.read(profileServiceProvider).createUserRecord(
              cred.user!.uid,
              cred.user!.email ?? '',
              accountType: 'person',
              referralSource: 'invite',
            );
      }
      _started = false;
      await _accept(widget.token!);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível entrar com Google. Tente de novo.';
      });
    }
  }

  static String _messageForFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return 'Convite inválido ou removido.';
      case 'failed-precondition':
        return 'Convite expirado ou projeto indisponível.';
      case 'resource-exhausted':
        return 'Este convite já atingiu o número máximo de usos.';
      case 'unauthenticated':
        return 'Faça login e tente de novo.';
      default:
        return e.message ?? 'Não foi possível aceitar o convite.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fromLink && FirebaseAuth.instance.currentUser == null) {
      return _buildInviteLanding(context);
    }

    if (_fromLink && _error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_fromLink && _error != null) {
      return _buildAcceptError(context);
    }

    return _buildCodeForm(context);
  }

  Widget _buildInviteLanding(BuildContext context) {
    final next = _joinPath ?? '/dashboard';
    final loginHref = '/login?next=${Uri.encodeQueryComponent(next)}';
    final registerHref = '/register?next=${Uri.encodeQueryComponent(next)}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.landingAura),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: PageContainer(
              maxWidth: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PPLogo(showTagline: true, fontSize: 36)),
                  const SizedBox(height: 40),
                  Text(
                    'Você foi convidado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre com sua conta para participar da banda. '
                    'Não precisa cadastrar um perfil de artista — o projeto já existe.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 28),
                  PPButton(
                    label: 'Continuar com Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: _loading ? null : _signInWithGoogle,
                    isLoading: _loading,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  PPButton(
                    label: 'Entrar com email',
                    onPressed: _loading ? null : () => context.go(loginHref),
                    variant: PPButtonVariant.outline,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem conta? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _loading ? null : () => context.go(registerHref),
                        child: const Text(
                          'Criar em um passo',
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
      ),
    );
  }

  Widget _buildAcceptError(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PageContainer(
          maxWidth: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              PPButton(
                label: 'Tentar de novo',
                onPressed: _loading ? null : () => _accept(widget.token!),
                isLoading: _loading,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar em um projeto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: PageContainer(
        maxWidth: 440,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cole o código ou peça o link da banda. '
                'Sua conta entra no projeto sem criar outro perfil.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PPInput(
                label: 'Código do convite',
                controller: _codeCtrl,
                hint: 'Cole aqui',
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PPButton(
                label: 'Entrar no projeto',
                icon: Icons.group_add_rounded,
                onPressed: _loading ? null : _submitCode,
                isLoading: _loading,
                fullWidth: true,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  final t = _codeCtrl.text.trim();
                  if (t.isEmpty) return;
                  Clipboard.setData(ClipboardData(text: t));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar campo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
