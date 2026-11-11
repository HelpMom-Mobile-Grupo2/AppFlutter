import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../cubit/summary_cubit.dart';
import '../cubit/tips_cubit.dart';
import '../data/weekly_guide.dart';
import 'widgets/mission_list.dart';

/// P5 Guía: los tips del día y qué está pasando en la semana de embarazo.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  // El Future se crea una sola vez: si se creara en build, el JSON se
  // volvería a leer en cada redibujo.
  late Future<WeeklyGuide> _guide;

  /// Semana elegida con las flechas; null = la semana actual del embarazo.
  int? _selectedWeek;

  @override
  void initState() {
    super.initState();
    _guide = WeeklyGuide.load(rootBundle);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Guía')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _TipsSection(),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'Qué está pasando esta semana',
              style: textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<WeeklyGuide>(
            future: _guide,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorView(
                  message: 'No se pudo cargar la guía semanal.',
                  // Con llaves: setState no acepta un callback que devuelva
                  // un Future.
                  onRetry: () => setState(() {
                    _guide = WeeklyGuide.load(rootBundle);
                  }),
                );
              }
              if (!snapshot.hasData) return const LoadingView();
              return _buildWeek(context, snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeek(BuildContext context, WeeklyGuide guide) {
    return BlocBuilder<SummaryCubit, SummaryState>(
      builder: (context, state) {
        final summary = state is SummaryLoaded ? state.summary : null;
        final motherName = summary?.motherName ?? 'tu pareja';
        final currentWeek = summary?.gestationalWeeks;
        final week = guide.forWeek(
          _selectedWeek ?? currentWeek ?? guide.firstWeek,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentWeek == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$motherName aún no registró su embarazo. Mientras tanto, '
                  'puedes explorar la guía semana a semana.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            _WeekSelector(
              week: week.week,
              isCurrent: week.week == currentWeek,
              onPrevious: week.week > guide.firstWeek
                  ? () => setState(() => _selectedWeek = week.week - 1)
                  : null,
              onNext: week.week < guide.lastWeek
                  ? () => setState(() => _selectedWeek = week.week + 1)
                  : null,
              onBackToCurrent: currentWeek != null && week.week != currentWeek
                  ? () => setState(() => _selectedWeek = null)
                  : null,
            ),
            const SizedBox(height: 8),
            _WeekGuideCard(guide: week, motherName: motherName),
          ],
        );
      },
    );
  }
}

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TipsCubit, TipsState>(
      builder: (context, state) {
        final cubit = context.read<TipsCubit>();
        return switch (state) {
          TipsLoaded(:final tips, :final isOffline) => MissionList(
            title: '¿Cómo ayudar hoy?',
            tips: tips,
            showBody: true,
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

class _WeekSelector extends StatelessWidget {
  const _WeekSelector({
    required this.week,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.onBackToCurrent,
  });

  final int week;
  final bool isCurrent;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onBackToCurrent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  isCurrent ? 'Semana $week · esta semana' : 'Semana $week',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Semana siguiente',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (onBackToCurrent != null)
          TextButton(
            onPressed: onBackToCurrent,
            child: const Text('Volver a esta semana'),
          ),
      ],
    );
  }
}

class _WeekGuideCard extends StatelessWidget {
  const _WeekGuideCard({required this.guide, required this.motherName});

  final WeekGuide guide;
  final String motherName;

  static const _trimesterNames = ['primer', 'segundo', 'tercer'];

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            guide.imageAsset,
            height: 160,
            fit: BoxFit.cover,
            semanticLabel:
                'Ilustración del ${_trimesterNames[guide.trimester - 1]} '
                'trimestre',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideItem(
                  icon: Icons.child_care,
                  title: 'El bebé',
                  text: guide.baby,
                ),
                _GuideItem(
                  icon: Icons.pregnant_woman,
                  title: 'Cambios en $motherName',
                  text: guide.mother,
                ),
                _GuideItem(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Cómo ayudar',
                  text: guide.howToHelp,
                ),
                _GuideItem(
                  icon: Icons.checklist,
                  title: 'Preparativos',
                  text: guide.preparations,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
