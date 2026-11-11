import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_theme.dart';
import '../../../core/phone_launcher.dart';
import '../../../core/session_store.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../alerts/bloc/alerts_bloc.dart';
import '../../alerts/ui/alert_actions.dart';
import '../../alerts/ui/alert_card.dart';
import '../cubit/summary_cubit.dart';
import '../cubit/tips_cubit.dart';
import '../data/companion_summary.dart';
import 'widgets/mission_list.dart';
import 'widgets/status_card.dart';

/// P3 Inicio: alerta activa, estado de la madre y misión de hoy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<AlertsBloc>().refresh(AlertsView.home),
      context.read<SummaryCubit>().load(),
      context.read<TipsCubit>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final fullName = context.read<SessionStore>().fullName ?? '';
    final firstName = fullName.trim().split(' ').first;

    return Scaffold(
      body: BlocBuilder<SummaryCubit, SummaryState>(
        builder: (context, summaryState) {
          final summary = summaryState is SummaryLoaded
              ? summaryState.summary
              : null;
          final motherName = summary?.motherName ?? 'tu pareja';

          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _HomeAppBar(firstName: firstName, summary: summary),
                SliverToBoxAdapter(
                  child: BlocSelector<AlertsBloc, AlertsState, bool>(
                    selector: (state) => state.isOffline,
                    builder: (context, isOffline) => isOffline
                        ? const OfflineBanner()
                        : const SizedBox.shrink(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  // Con una alerta pendiente, la alerta va primero; si no,
                  // el semáforo queda arriba para que se vea más.
                  sliver: BlocSelector<AlertsBloc, AlertsState, bool>(
                    selector: (state) => state.activeAlert?.isPending ?? false,
                    builder: (context, hasPending) {
                      final alert = _ActiveAlertSection(motherName: motherName);
                      final status = _StatusSection(state: summaryState);
                      return SliverList.list(
                        children: [
                          hasPending ? alert : status,
                          const SizedBox(height: 16),
                          hasPending ? status : alert,
                          const SizedBox(height: 16),
                          const _MissionSection(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Header blanco del Figma: avatar con la inicial, chip "Modo Compañero",
/// "Hola, {nombre}" y a la derecha "{madre} (Sem. X)".
class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.firstName, required this.summary});

  final String firstName;
  final CompanionSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // La altura crece con el tamaño de texto del sistema.
    final scaler = MediaQuery.textScalerOf(context);
    final weeks = summary?.gestationalWeeks;
    final motherLine = summary == null
        ? ''
        : weeks == null
        ? summary!.motherName
        : '${summary!.motherName} (Sem. $weeks)';
    final initial = firstName.isEmpty ? '?' : firstName[0].toUpperCase();

    return SliverAppBar(
      pinned: true,
      toolbarHeight: 24 + scaler.scale(48),
      titleSpacing: 16,
      title: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
              child: Text(
                initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Modo Compañero',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accentText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName.isEmpty ? 'Hola' : 'Hola, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              motherLine,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertSection extends StatelessWidget {
  const _ActiveAlertSection({required this.motherName});

  final String motherName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertsBloc, AlertsState>(
      builder: (context, state) {
        final alert = state.activeAlert;

        if (alert != null) {
          return AlertCard(
            alert: alert,
            motherName: motherName,
            onRespond: (response) =>
                respondToAlert(context, alert.id, response),
            onCallMother: () => callMother(context, motherName),
            onCallEmergency: () => callEmergency(context),
          );
        }

        return Card(
          child: switch (state.homeStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(),
            LoadStatus.failure => ErrorView(
              message:
                  state.errorMessage ?? 'No se pudieron cargar las alertas.',
              onRetry: () => context.read<AlertsBloc>().add(
                const AlertsRefreshRequested(AlertsView.home),
              ),
            ),
            LoadStatus.success => EmptyView(
              icon: Icons.notifications_none,
              message:
                  'Aún no hay alertas, te avisaremos cuando $motherName te '
                  'necesite',
            ),
          },
        );
      },
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.state});

  final SummaryState state;

  @override
  Widget build(BuildContext context) {
    void retry() => context.read<SummaryCubit>().load();

    return switch (state) {
      SummaryLoaded(:final summary) => StatusCard(summary: summary),
      SummaryFailure(:final message, :final isOffline) => Card(
        child: isOffline
            ? ErrorView.offline(onRetry: retry)
            : ErrorView(message: message, onRetry: retry),
      ),
      // El contenedor principal lleva a Vincular.
      SummaryNotLinked() => const SizedBox.shrink(),
      SummaryInitial() || SummaryLoading() => const Card(child: LoadingView()),
    };
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TipsCubit, TipsState>(
      builder: (context, state) {
        final cubit = context.read<TipsCubit>();
        return switch (state) {
          TipsLoaded(:final tips, :final isOffline) => MissionList(
            tips: tips,
            isOffline: isOffline,
            onToggle: cubit.toggle,
          ),
          TipsFailure(:final message, :final isOffline) => Card(
            child: isOffline
                ? ErrorView.offline(onRetry: cubit.load)
                : ErrorView(message: message, onRetry: cubit.load),
          ),
          TipsNotLinked() => const SizedBox.shrink(),
          TipsInitial() || TipsLoading() => const Card(child: LoadingView()),
        };
      },
    );
  }
}
