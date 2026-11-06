import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_exception.dart';
import '../../../core/app_routes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../family/data/family_models.dart';
import '../../family/data/family_repository.dart';
import '../cubit/profile_cubit.dart';

/// P6 Perfil: datos, pareja, teléfono, preferencias, T&C y cerrar sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Carga de solo lectura: GET /api/family con FutureBuilder.
  late Future<FamilyGroup?> _family;

  @override
  void initState() {
    super.initState();
    _family = context.read<FamilyRepository>().getFamily();
  }

  void _reloadFamily() {
    // Con llaves: setState no acepta un callback que devuelva un Future.
    setState(() {
      _family = context.read<FamilyRepository>().getFamily();
    });
  }

  Future<void> _editPhone(String motherName, String? current) async {
    final cubit = context.read<ProfileCubit>();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _PhoneDialog(motherName: motherName, initial: current),
    );
    // null = canceló; '' = borró el número.
    if (result != null) await cubit.setMotherPhone(result);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Se borrará lo guardado en este teléfono: tu sesión, el teléfono de '
          'tu pareja y la copia de alertas y tips.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, state) => state is AuthUnauthenticated,
        listener: (context, _) => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        ),
        child: FutureBuilder<FamilyGroup?>(
          future: _family,
          builder: (context, snapshot) {
            final motherName = snapshot.data?.motherName ?? 'tu pareja';
            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profile) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _UserHeader(profile: profile),
                  const SizedBox(height: 16),
                  _PartnerCard(snapshot: snapshot, onRetry: _reloadFamily),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: Text('Teléfono de $motherName'),
                      subtitle: Text(
                        profile.motherPhone ??
                            'Sin guardar. Sirve para llamarla con un toque.',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editPhone(motherName, profile.motherPhone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Notificaciones'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          secondary: const Icon(Icons.lightbulb_outline),
                          title: const Text('Tip del día'),
                          subtitle: const Text(
                            'Guardamos tu preferencia para los recordatorios.',
                          ),
                          value: profile.dailyTipNotifications,
                          onChanged: context
                              .read<ProfileCubit>()
                              .setDailyTipNotifications,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          secondary: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: const Text('Alertas'),
                          subtitle: Text(
                            'Revisar cada 15 s si $motherName te necesita, '
                            'mientras la app está abierta.',
                          ),
                          value: profile.alertNotifications,
                          onChanged: context
                              .read<ProfileCubit>()
                              .setAlertNotifications,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Términos y condiciones'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.terms,
                            arguments: true,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onTap: _confirmLogout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.profile});

  final ProfileState profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile.fullName.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Semantics(
      container: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            child: ExcludeSemantics(
              child: Text(initial, style: theme.textTheme.headlineSmall),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleLarge),
                Text(profile.email, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.snapshot, required this.onRetry});

  final AsyncSnapshot<FamilyGroup?> snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget title;
    Widget? trailing;

    if (snapshot.connectionState != ConnectionState.done) {
      title = const Text('Buscando a tu pareja…');
      trailing = const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
      );
    } else if (snapshot.hasError) {
      title = Text(
        snapshot.error is NoConnectionException
            ? 'Sin conexión: no pudimos ver a quién acompañas.'
            : 'No pudimos ver a quién acompañas.',
      );
      trailing = TextButton(
        onPressed: onRetry,
        child: const Text('Reintentar'),
      );
    } else {
      final motherName = snapshot.data?.motherName;
      title = Text(
        motherName == null
            ? 'Aún no estás vinculado a una gestante.'
            : 'Acompañando a $motherName',
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.favorite,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: title,
        trailing: trailing,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

/// Diálogo para guardar el teléfono. Devuelve el número, '' para borrarlo o
/// null si se cancela.
class _PhoneDialog extends StatefulWidget {
  const _PhoneDialog({required this.motherName, this.initial});

  final String motherName;
  final String? initial;

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  static final _phonePattern = RegExp(r'^\+?[0-9 ]{6,15}$');

  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Teléfono de ${widget.motherName}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Número',
            hintText: '987 654 321',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Ingresa un número.';
            if (!_phonePattern.hasMatch(text)) return 'Revisa el número.';
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Borrar'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
