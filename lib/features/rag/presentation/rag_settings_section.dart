import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/problem_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/grouped_list.dart';
import '../../../core/ui/wavy_progress.dart';
import '../application/rag_providers.dart';
import '../domain/rag_models.dart';
import '../l10n/rag_failure_text.dart';

/// Address, access key and a connection check for the knowledge base, shown
/// at the bottom of the AI screen.
class RagSettingsSection extends ConsumerStatefulWidget {
  const RagSettingsSection({super.key});

  @override
  ConsumerState<RagSettingsSection> createState() => _RagSettingsSectionState();
}

class _RagSettingsSectionState extends ConsumerState<RagSettingsSection> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  String? _syncedUrl;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AppProblemError catch (e) {
      if (mounted) _showMessage(appProblemText(context.l10n, e.problem));
    }
  }

  Future<void> _saveUrl() => _guard(() async {
    await ref
        .read(ragSettingsControllerProvider.notifier)
        .updateBaseUrl(_urlController.text);
    if (mounted) _showMessage(context.l10n.llmSettingsSaved);
  });

  Future<void> _saveKey() => _guard(() async {
    await ref
        .read(ragSettingsControllerProvider.notifier)
        .setApiKey(_keyController.text);
    _keyController.clear();
  });

  Future<void> _confirmClearKey() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ragClearKeyTitle),
        content: Text(l10n.ragClearKeyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(ragSettingsControllerProvider.notifier).clearApiKey();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(ragSettingsControllerProvider).value;
    if (settings == null) return const SizedBox.shrink();
    if (_syncedUrl != settings.baseUrl) {
      _syncedUrl = settings.baseUrl;
      _urlController.text = settings.baseUrl;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupHeader(l10n.ragSectionTitle),
        Text(l10n.ragHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(labelText: l10n.ragAddressLabel),
        ),
        const SizedBox(height: AppSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saveUrl,
            child: Text(l10n.commonSave),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (settings.hasApiKey)
          GroupedList(
            children: [
              GroupedTile(
                leading: TileIcon(
                  Icons.key_rounded,
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
                title: l10n.ragKeySaved,
                trailing: IconButton(
                  tooltip: l10n.ragKeyDeleteTooltip,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _confirmClearKey,
                ),
              ),
            ],
          )
        else ...[
          TextField(
            controller: _keyController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(labelText: l10n.ragKeyLabel),
          ),
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _saveKey,
              child: Text(l10n.ragSaveKey),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        const _RagCheck(),
      ],
    );
  }
}

class _RagCheck extends ConsumerWidget {
  const _RagCheck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final check = ref.watch(ragConnectionCheckProvider);
    final hasKey =
        ref.watch(ragSettingsControllerProvider).value?.hasApiKey ?? false;
    Widget line(IconData icon, String text, Color color) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: check.isLoading || !hasKey
                ? null
                : () => ref.read(ragConnectionCheckProvider.notifier).run(),
            child: Text(l10n.ragCheck),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        switch (check) {
          AsyncLoading() => const WavyProgress(),
          AsyncError(:final error) => line(
            Icons.error_rounded,
            error is RagFailure
                ? describeRagFailure(l10n, error)
                : l10n.ragErrNetwork,
            scheme.error,
          ),
          AsyncData(:final value?) => line(
            Icons.check_circle_rounded,
            l10n.ragCheckOk(value),
            StatusColors.of(context).ok,
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}
