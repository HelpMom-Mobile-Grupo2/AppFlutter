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
      appBar: AppBar(
        title: const Text('Vincular con tu pareja'),
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
    final loading = state is LinkLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.qr_code_2, size: 72, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            'Pídele a tu pareja que abra HelpMom y genere su código de '
            'invitación. Escanea el QR o escribe la clave que aparece debajo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: loading ? null : _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear código QR'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o', style: theme.textTheme.bodyMedium),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Ingresar clave',
              hintText: 'HM-1234',
              prefixIcon: const Icon(Icons.key_outlined),
              errorText: state is LinkFailure ? state.message : null,
              errorMaxLines: 3,
            ),
            validator: _validateCode,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: loading ? null : _submit,
            child: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Text('Vincular'),
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
