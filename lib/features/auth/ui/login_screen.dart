import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre.';
  return null;
}

String? _validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Ingresa tu correo.';
  if (!_emailPattern.hasMatch(value.trim())) return 'Revisa tu correo.';
  return null;
}

String? _validateNewPassword(String? value) {
  final length = value?.length ?? 0;
  if (length < 10 || length > 128) {
    return 'La contraseña debe tener entre 10 y 128 caracteres.';
  }
  return null;
}

String? _validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
  return null;
}

/// P1. Pestañas Ingresar y Crear cuenta. Solo para acompañantes.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HelpMom · Modo Compañero'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ingresar'),
              Tab(text: 'Crear cuenta'),
            ],
          ),
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listenWhen: (_, state) =>
              state is AuthLinked || state is AuthNotLinked,
          listener: (context, state) {
            final route = routeForAuthState(state);
            if (route != null) Navigator.pushReplacementNamed(context, route);
          },
          child: const TabBarView(children: [_LoginForm(), _RegisterForm()]),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(email: _email.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;
        final failure = state is AuthFailure && state.action == AuthAction.login
            ? state
            : null;

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _RoleHeader(),
              const SizedBox(height: 24),
              _EmailField(
                controller: _email,
                errorText: failure?.fieldErrors['email'],
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _password,
                validator: _validateLoginPassword,
                errorText: failure?.fieldErrors['password'],
                onSubmitted: _submit,
              ),
              const SizedBox(height: 16),
              if (failure != null && failure.fieldErrors.isEmpty)
                _FormError(failure.message),
              _SubmitButton(
                label: 'Ingresar',
                loading: loading,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthRegisterSubmitted(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;
        final failure =
            state is AuthFailure && state.action == AuthAction.register
            ? state
            : null;

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _RoleHeader(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: failure?.fieldErrors['fullName'],
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              _EmailField(
                controller: _email,
                errorText: failure?.fieldErrors['email'],
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _password,
                validator: _validateNewPassword,
                errorText: failure?.fieldErrors['password'],
                helperText: 'De 10 a 128 caracteres.',
                onSubmitted: _submit,
              ),
              const SizedBox(height: 16),
              if (failure != null && failure.fieldErrors.isEmpty)
                _FormError(failure.message),
              _SubmitButton(
                label: 'Crear cuenta',
                loading: loading,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.favorite, size: 48, color: theme.colorScheme.secondary),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text('Soy acompañante', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 4),
        Text(
          'Acompaña a tu pareja durante el embarazo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Los errores del backend van en [errorText]; los de la app, en el validator.
class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Correo',
        prefixIcon: const Icon(Icons.email_outlined),
        errorText: errorText,
      ),
      validator: _validateEmail,
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.validator,
    required this.onSubmitted,
    this.errorText,
    this.helperText,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback onSubmitted;
  final String? errorText;
  final String? helperText;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => widget.onSubmitted(),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        helperText: widget.helperText,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
