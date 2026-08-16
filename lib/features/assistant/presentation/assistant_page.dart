import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../application/assistant_controller.dart';
import '../domain/assistant_state.dart';
import 'widgets/assistant_orb.dart';
import 'widgets/assistant_status_card.dart';

class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assistantControllerProvider);

    final controller = ref.read(assistantControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Text(
                'Olá Nathan Abrahão',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                state.isActive
                    ? 'Estou pronto para ouvir você.'
                    : 'Ative quando quiser começar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 48),

              AssistantOrb(
                active: state.isActive,
                audioLevel: state.audioLevel,
              ),

              const Spacer(),

              AssistantStatusCard(state: state),

              const SizedBox(height: 20),

              _AssistantActionButton(
                state: state,
                onActivate: controller.activate,
                onDeactivate: controller.deactivate,
                onOpenSettings: controller.openSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantActionButton extends StatelessWidget {
  const _AssistantActionButton({
    required this.state,
    required this.onActivate,
    required this.onDeactivate,
    required this.onOpenSettings,
  });

  final AssistantState state;

  final Future<void> Function() onActivate;

  final Future<void> Function() onDeactivate;

  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (state.status == AssistantStatus.requestingPermission) {
      return const FilledButton(
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Ativando...'),
          ],
        ),
      );
    }

    if (state.status == AssistantStatus.permissionPermanentlyDenied) {
      return Column(
        children: [
          FilledButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Abrir configurações'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onActivate,
            child: const Text('Verificar novamente'),
          ),
        ],
      );
    }

    if (state.isActive) {
      return FilledButton.icon(
        onPressed: onDeactivate,
        icon: const Icon(Icons.power_settings_new_rounded),
        label: const Text('Desativar assistente'),
      );
    }

    return FilledButton.icon(
      onPressed: onActivate,
      icon: const Icon(Icons.mic_rounded),
      label: const Text('Ativar assistente'),
    );
  }
}
