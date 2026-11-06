import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/error_view.dart';
import '../bloc/auth_bloc.dart';

/// P0. Sin T&C va a Términos; sin token, al login; con token pregunta a
/// GET /api/family: 200 va a Inicio y 404 a Vincular.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        final route = routeForAuthState(state);
        if (route != null) Navigator.pushReplacementNamed(context, route);
      },
      builder: (context, state) {
        return Scaffold(
          body: state is AuthFailure
              ? ErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<AuthBloc>().add(const AuthCheckRequested()),
                )
              : const _Brand(),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text('HelpMom', style: theme.textTheme.headlineMedium),
          Text('Modo Compañero', style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          const CircularProgressIndicator.adaptive(),
        ],
      ),
    );
  }
}
