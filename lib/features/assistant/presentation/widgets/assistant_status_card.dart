import 'package:flutter/material.dart';

import '../../domain/assistant_state.dart';

class AssistantStatusCard extends StatelessWidget {
  const AssistantStatusCard({required this.state, super.key});

  final AssistantState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_iconForStatus(), color: _colorForStatus(colors)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleForStatus(),
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (state.isActive) ...[
            const SizedBox(height: 18),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              // child: LinearProgressIndicator(
              //   value: state.audioLevel,
              //   minHeight: 8,
              // ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Microfone ${(state.audioLevel * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _titleForStatus() {
    return switch (state.status) {
      AssistantStatus.inactive => 'Assistente desativado',

      AssistantStatus.requestingPermission => 'Preparando assistente',

      AssistantStatus.connecting => 'Conectando',

      AssistantStatus.ready => 'Assistente ativo',

      AssistantStatus.listening => 'Ouvindo você',

      AssistantStatus.thinking => 'Pensando',

      AssistantStatus.speaking => 'Respondendo',

      AssistantStatus.permissionDenied => 'Microfone necessário',

      AssistantStatus.permissionPermanentlyDenied => 'Permissão bloqueada',

      AssistantStatus.error => 'Erro',
    };
  }

  IconData _iconForStatus() {
    return switch (state.status) {
      AssistantStatus.inactive => Icons.power_settings_new_rounded,

      AssistantStatus.requestingPermission => Icons.hourglass_top_rounded,

      AssistantStatus.connecting => Icons.cloud_sync_rounded,

      AssistantStatus.ready => Icons.hearing_rounded,

      AssistantStatus.listening => Icons.mic_rounded,

      AssistantStatus.thinking => Icons.psychology_rounded,

      AssistantStatus.speaking => Icons.graphic_eq_rounded,

      AssistantStatus.permissionDenied => Icons.mic_off_rounded,

      AssistantStatus.permissionPermanentlyDenied => Icons.settings_rounded,

      AssistantStatus.error => Icons.error_outline_rounded,
    };
  }

  Color _colorForStatus(ColorScheme colors) {
    return switch (state.status) {
      AssistantStatus.ready => colors.primary,

      AssistantStatus.listening => colors.primary,

      AssistantStatus.error => colors.error,

      AssistantStatus.permissionDenied => colors.error,

      AssistantStatus.permissionPermanentlyDenied => colors.error,

      _ => colors.onSurfaceVariant,
    };
  }
}
