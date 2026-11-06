import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Aviso flotante "Conectando con el servidor…" mientras Render despierta.
/// Se pinta encima de todas las pantallas desde MaterialApp.builder.
class WakingServerBanner extends StatelessWidget {
  const WakingServerBanner({super.key, required this.isWaking});

  final ValueListenable<bool> isWaking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: isWaking,
      builder: (context, waking, _) {
        if (!waking) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: scheme.inverseSurface,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              scheme.onInverseSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Conectando con el servidor…',
                          style: TextStyle(color: scheme.onInverseSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
