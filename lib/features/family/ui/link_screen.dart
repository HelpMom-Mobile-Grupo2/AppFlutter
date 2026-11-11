import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../cubit/link_cubit.dart';
import '../data/family_models.dart';

/// P2. Vincular con la pareja escaneando su QR o escribiendo la clave.
class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa la clave que te compartió tu pareja.';
    }
    if (!InvitationCode.isValid(value)) {
      return 'La clave tiene el formato HM-1234.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LinkCubit>().join(_code.text);
  }

  Future<void> _scan() async {
    // Sin tipo genérico: las rutas de `routes` se crean como
    // MaterialPageRoute<dynamic>.
    final value = await Navigator.pushNamed(context, AppRoutes.scanner);
    if (!mounted || value is! String) return;

    if (!InvitationCode.isValid(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese QR no es un código de HelpMom.')),
      );
      return;
    }
    _code.text = InvitationCode.normalize(value);
    context.read<LinkCubit>().join(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo claro como en el Figma, para que la tarjeta gris de los pasos
      // se distinga.
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Vincular con tu pareja'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            child: const Text('Salir'),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, state) => state is AuthUnauthenticated,
        listener: (context, state) =>
            Navigator.pushReplacementNamed(context, AppRoutes.login),
        child: BlocBuilder<LinkCubit, LinkState>(
          builder: (context, state) {
            if (state is LinkSuccess) {
              return _LinkedView(motherName: state.motherName);
            }
            return _buildForm(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, LinkState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loading = state is LinkLoading;
    // Clave en monoespaciada y grande, como en el Figma.
    final codeStyle = theme.textTheme.headlineSmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'Courier'],
      fontWeight: FontWeight.w700,
      letterSpacing: 4,
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Conecta con tu pareja',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recibirás sus alertas de apoyo y verás su semáforo, sin ver sus '
            'datos clínicos.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: codeStyle,
            decoration: InputDecoration(
              labelText: 'Clave de acceso',
              floatingLabelAlignment: FloatingLabelAlignment.center,
              hintText: 'HM-XXXX',
              hintStyle: codeStyle?.copyWith(color: scheme.outline),
              errorText: state is LinkFailure ? state.message : null,
              errorMaxLines: 3,
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : _submit,
            child: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Text('Vincular'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary),
            ),
            onPressed: loading ? null : _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear código QR'),
          ),
          const SizedBox(height: 32),
          const _Steps(),
        ],
      ),
    );
  }
}

/// Pasos numerados en una tarjeta gris claro.
class _Steps extends StatelessWidget {
  const _Steps();

  static const _steps = [
    'Tu pareja abre HelpMom y genera su código de invitación.',
    'Escanea su código QR o escribe la clave HM-XXXX.',
    '¡Listo! Te avisaremos cuando te necesite.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, step) in _steps.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkedView extends StatelessWidget {
  const _LinkedView({required this.motherName});

  final String motherName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: StatusColors.green),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                '¡Listo! Ahora acompañas a $motherName',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
