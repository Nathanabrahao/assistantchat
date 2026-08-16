import 'package:flutter/material.dart';

import '../../domain/assistant_state.dart';

class AssistantStatusCard extends StatelessWidget {
  const AssistantStatusCard({
    required this.state,
    super.key,
  });

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
      child: Row(
        children: [
          Icon(
            _iconForStatus(),
            color: _colorForStatus(colors),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleForStatus(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleForStatus() {
    return switch (state.status) {
      AssistantStatus.inactive => 'Assistente desativado',
      AssistantStatus.requestingPermission => 'Preparando assistente',
      AssistantStatus.active => 'Assistente ativo',
      AssistantStatus.permissionDenied => 'Microfone necessário',
      AssistantStatus.permissionPermanentlyDenied =>
        'Permissão bloqueada',
      AssistantStatus.error => 'Erro',
    };
  }

  IconData _iconForStatus() {
    return switch (state.status) {
      AssistantStatus.inactive => Icons.power_settings_new_rounded,
      AssistantStatus.requestingPermission => Icons.hourglass_top_rounded,
      AssistantStatus.active => Icons.check_circle_rounded,
      AssistantStatus.permissionDenied => Icons.mic_off_rounded,
      AssistantStatus.permissionPermanentlyDenied =>
        Icons.settings_rounded,
      AssistantStatus.error => Icons.error_outline_rounded,
    };
  }

  Color _colorForStatus(ColorScheme colors) {
    return switch (state.status) {
      AssistantStatus.active => colors.primary,
      AssistantStatus.error => colors.error,
      AssistantStatus.permissionDenied => colors.error,
      AssistantStatus.permissionPermanentlyDenied => colors.error,
      _ => colors.onSurfaceVariant,
    };
  }
}