import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/app_theme.dart';
import '../../domain/entities/customer_segment.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_validators.dart';

/// Onboarding en 3 pasos: propuesta de valor -> segmento -> datos de acceso.
/// El segmento elegido viaja en `user_metadata` y el backend lo usa para
/// crear el perfil y personalizar el home.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = 3;

  final _pages = PageController();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  int _step = 0;
  CustomerSegment? _segment;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    setState(() => _step = step);
    await _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_step == 0) {
      context.go(AppRoutes.login);
    } else {
      _goTo(_step - 1).ignore();
    }
  }

  void _submit() {
    final segment = _segment;
    if (segment == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            segment: segment,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text('Paso ${_step + 1} de $_steps'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _steps,
              semanticsLabel: 'Progreso del registro',
            ),
          ),
        ),
        body: SafeArea(
          child: PageView(
            controller: _pages,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WelcomeStep(onNext: () => _goTo(1).ignore()),
              _SegmentStep(
                selected: _segment,
                onSelected: (s) => setState(() => _segment = s),
                onNext: _segment == null ? null : () => _goTo(2).ignore(),
              ),
              _CredentialsStep(
                formKey: _formKey,
                name: _name,
                email: _email,
                password: _password,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const items = [
      (Icons.phone_iphone, 'Abre tu cuenta en minutos, sin ir a una agencia'),
      (Icons.auto_awesome, 'Una experiencia que se adapta a ti'),
      (Icons.storefront_outlined, 'Beneficios y servicios de aliados en un solo lugar'),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tu banco, a tu manera', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          for (final (icon, text) in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: theme.colorScheme.primary),
              title: Text(text),
            ),
          const Spacer(),
          FilledButton(
            key: const Key('onboarding_start'),
            onPressed: onNext,
            child: const Text('Empezar'),
          ),
        ],
      ),
    );
  }
}

class _SegmentStep extends StatelessWidget {
  const _SegmentStep({
    required this.selected,
    required this.onSelected,
    required this.onNext,
  });

  final CustomerSegment? selected;
  final ValueChanged<CustomerSegment> onSelected;
  final VoidCallback? onNext;

  static const _icons = {
    CustomerSegment.joven: Icons.school_outlined,
    CustomerSegment.pyme: Icons.store_outlined,
    CustomerSegment.premium: Icons.diamond_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Qué te describe mejor?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          const Text('Personalizaremos tu experiencia según tu perfil.'),
          const SizedBox(height: AppSpacing.lg),
          for (final segment in CustomerSegment.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                color: segment == selected
                    ? theme.colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  key: Key('segment_${segment.name}'),
                  leading: Icon(_icons[segment]),
                  title: Text(segment.label),
                  subtitle: Text(segment.description),
                  selected: segment == selected,
                  trailing: segment == selected
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => onSelected(segment),
                ),
              ),
            ),
          const Spacer(),
          FilledButton(
            key: const Key('onboarding_segment_next'),
            onPressed: onNext,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep({
    required this.formKey,
    required this.name,
    required this.email,
    required this.password,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Crea tu acceso', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  if (state is AuthError) ...[
                    Text(
                      state.failure.message,
                      key: const Key('auth_error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextFormField(
                    key: const Key('signup_name'),
                    controller: name,
                    enabled: !loading,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: AuthValidators.fullName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('signup_email'),
                    controller: email,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('signup_password'),
                    controller: password,
                    enabled: !loading,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      helperText: 'Mínimo 8 caracteres',
                    ),
                    validator: AuthValidators.password,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('signup_password_confirm'),
                    enabled: !loading,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirma tu contraseña'),
                    validator: (v) =>
                        v == password.text ? null : 'Las contraseñas no coinciden',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    key: const Key('signup_submit'),
                    onPressed: loading ? null : onSubmit,
                    child: loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Abrir mi cuenta'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
