import 'package:flutter/material.dart';

class AssistantOrb extends StatelessWidget {
  const AssistantOrb({
    required this.active,
    required this.audioLevel,
    required this.listening,
    super.key,
  });

  final bool active;
  final bool listening;
  final double audioLevel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final level = audioLevel.clamp(0.0, 1.0);

    final scale = active ? 1.0 + (level * 0.28) : 1.0;

    final glowBlur = active ? 25.0 + (level * 45) : 0.0;

    final glowSpread = active ? 4.0 + (level * 12) : 0.0;

    return SizedBox(
      width: 210,
      height: 210,
      child: Center(
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(
                          alpha: 0.30 + (level * 0.25),
                        ),
                        blurRadius: glowBlur,
                        spreadRadius: glowSpread,
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: 105 + (level * 20),
                    height: 105 + (level * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                  ),

                Icon(
                  listening
                      ? Icons.graphic_eq_rounded
                      : active
                      ? Icons.hearing_rounded
                      : Icons.mic_none_rounded,
                  size: 64,
                  color: active ? colors.primary : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
