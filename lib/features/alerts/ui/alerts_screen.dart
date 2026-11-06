import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/phone_launcher.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../companion/cubit/summary_cubit.dart';
import '../bloc/alerts_bloc.dart';
import '../data/alert_model.dart';
import 'alert_actions.dart';
import 'alert_card.dart';
import 'alert_tile.dart';

/// P4 Alertas: pendientes arriba y luego el historial. El polling cada 15 s
/// lo maneja el AlertsBloc mientras esta pestaña está visible.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final motherName = context.select<SummaryCubit, String>((cubit) {
      final state = cubit.state;
      return state is SummaryLoaded ? state.summary.motherName : 'tu pareja';
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: BlocBuilder<AlertsBloc, AlertsState>(
        builder: (context, state) {
          final bloc = context.read<AlertsBloc>();
          Future<void> refresh() => bloc.refresh(AlertsView.inbox);

          switch (state.inboxStatus) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const LoadingView(message: 'Cargando alertas…');
            case LoadStatus.failure:
              return ErrorView(
                message:
                    state.errorMessage ?? 'No se pudieron cargar las alertas.',
                onRetry: refresh,
              );
            case LoadStatus.success:
              break;
          }

          if (state.all.isEmpty) {
            if (state.isOffline) return ErrorView.offline(onRetry: refresh);
            // ListView para que el pull-to-refresh funcione aunque esté vacía.
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 96),
                  EmptyView(
                    icon: Icons.notifications_none,
                    message:
                        'Aún no hay alertas, te avisaremos cuando $motherName '
                        'te necesite',
                  ),
                ],
              ),
            );
          }

          final pending = state.all.where((alert) => alert.isPending);
          final history = state.all.where((alert) => !alert.isPending);
          // Lista plana: un String es un título de sección; un QuickAlert,
          // una fila.
          final items = <Object>[
            if (pending.isNotEmpty) 'Pendientes',
            ...pending,
            if (history.isNotEmpty) 'Historial',
            ...history,
          ];

          return Column(
            children: [
              if (state.isOffline) const OfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is String) return _SectionHeader(item);

                      final alert = item as QuickAlert;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AlertTile(
                          alert: alert,
                          onTap: () => _openAlert(context, alert, motherName),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Abre la alerta pendiente en una hoja inferior con la misma tarjeta de
  /// Inicio, para responderla desde la bandeja.
  void _openAlert(BuildContext context, QuickAlert alert, String motherName) {
    final bloc = context.read<AlertsBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // La hoja vive fuera de los providers de la pestaña: le pasamos el bloc.
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<AlertsBloc, AlertsState>(
          builder: (context, state) {
            final current =
                state.all.where((a) => a.id == alert.id).firstOrNull ?? alert;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AlertCard(
                  alert: current,
                  motherName: motherName,
                  onRespond: (response) =>
                      respondToAlert(context, current.id, response),
                  onCallMother: () => callMother(context, motherName),
                  onCallEmergency: () => callEmergency(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
