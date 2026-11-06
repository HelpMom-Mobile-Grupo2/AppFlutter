import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/phone_launcher.dart';
import '../../../core/session_store.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../alerts/bloc/alerts_bloc.dart';
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
    context.read<AlertsBloc>().add(
      const AlertsRefreshRequested(AlertsView.home),
    );
    await Future.wait([
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
                  sliver: SliverList.list(
                    children: [
                      _ActiveAlertSection(motherName: motherName),
                      const SizedBox(height: 16),
                      _StatusSection(state: summaryState),
                      const SizedBox(height: 16),
                      const _MissionSection(),
                    ],
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

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.firstName, required this.summary});

  final String firstName;
  final CompanionSummary? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // La altura crece con el tamaño de texto del sistema.
    final scaler = MediaQuery.textScalerOf(context);
    final weeks = summary?.gestationalWeeks;
    final motherLine = summary == null
        ? ''
        : weeks == null
        ? summary!.motherName
        : '${summary!.motherName} (Sem. $weeks)';

    return SliverAppBar(
      pinned: true,
      expandedHeight: kToolbarHeight + scaler.scale(44),
      title: Text(
        firstName.isEmpty
            ? 'Modo Compañero'
            : 'Modo Compañero · Hola, $firstName',
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              motherLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
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
            onRespond: (response) => context.read<AlertsBloc>().add(
              AlertResponded(alert.id, response),
            ),
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
            onDone: cubit.markDone,
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
