import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/problem_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/grouped_list.dart';
import '../../../core/ui/wavy_progress.dart';
import '../../rag/presentation/rag_settings_section.dart';
import '../application/llm_connection_check.dart';
import '../application/llm_providers.dart';
import '../domain/llm_preset.dart';
import '../domain/llm_settings.dart';
import 'llm_texts.dart';

class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  LlmSettings? _synced;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Copies stored values into the fields when they changed in the store
  /// (first load, preset switch), keeping unsaved edits otherwise.
  void _syncFields(LlmSettings s) {
    final prev = _synced;
    if (prev != null &&
        prev.preset == s.preset &&
        prev.baseUrl == s.baseUrl &&
        prev.model == s.model) {
      _synced = s;
      return;
    }
    _synced = s;
    _baseUrlController.text = s.baseUrl;
    _modelController.text = s.model;
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

  Future<void> _saveEndpoint() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(llmSettingsControllerProvider.notifier);
    await _guard(() async {
      await notifier.updateEndpoint(
        baseUrl: _baseUrlController.text,
        model: _modelController.text,
      );
      if (mounted) _showMessage(context.l10n.llmSettingsSaved);
    });
  }

  Future<void> _saveKey() async {
    final notifier = ref.read(llmSettingsControllerProvider.notifier);
    final key = _apiKeyController.text;
    await _guard(() async {
      await notifier.setApiKey(key);
      _apiKeyController.clear();
    });
  }

  Future<void> _confirmClearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.llmClearKeyTitle),
        content: Text(context.l10n.llmClearKeyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(llmSettingsControllerProvider.notifier).clearApiKey();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(llmSettingsControllerProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (settings) {
          AsyncData(:final value) => _buildForm(context, value),
          AsyncError() => Center(child: Text(context.l10n.llmLoadFailed)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, LlmSettings s) {
    _syncFields(s);
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        kDockClearance + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        PageTitle(l10n.commonAi),
        GroupHeader(l10n.llmSectionProvider),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in LlmPreset.values)
              ChoiceChip(
                label: Text(llmPresetLabel(l10n, preset)),
                selected: preset == s.preset,
                onSelected: (_) => ref
                    .read(llmSettingsControllerProvider.notifier)
                    .selectPreset(preset),
              ),
          ],
        ),
        GroupHeader(l10n.llmSectionEndpoint),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _baseUrlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Base URL'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    problemTextOrNull(l10n, validateBaseUrl(value ?? '')),
              ),
              const SizedBox(height: AppSpace.md),
              TextFormField(
                controller: _modelController,
                autocorrect: false,
                decoration: InputDecoration(labelText: l10n.llmModelLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saveEndpoint,
            child: Text(l10n.commonSave),
          ),
        ),
        GroupHeader(l10n.llmApiKey),
        if (s.hasApiKey)
          GroupedList(
            children: [
              GroupedTile(
                leading: TileIcon(
                  Icons.key_rounded,
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
                title: l10n.llmKeySaved,
                trailing: IconButton(
                  tooltip: l10n.llmKeyDeleteTooltip,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _confirmClearKey,
                ),
              ),
            ],
          )
        else ...[
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(labelText: l10n.llmApiKey),
          ),
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _saveKey,
              child: Text(l10n.llmSaveKey),
            ),
          ),
        ],
        GroupHeader(l10n.llmSectionCheck),
        _ConnectionCheckBlock(ok: status.ok),
        const SizedBox(height: AppSpace.lg),
        const RagSettingsSection(),
      ],
    );
  }
}

class _ConnectionCheckBlock extends ConsumerWidget {
  const _ConnectionCheckBlock({required this.ok});

  final Color ok;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(llmConnectionCheckProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: check.isLoading
                ? null
                : () => ref.read(llmConnectionCheckProvider.notifier).run(),
            child: Text(l10n.llmCheckConnection),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        switch (check) {
          AsyncLoading() => const WavyProgress(),
          AsyncError(:final error) => _line(
            Icons.error_rounded,
            error is LlmCheckError ? error.text : l10n.llmCheckFailed,
            scheme.error,
          ),
          AsyncData(:final value?) => _line(
            Icons.check_circle_rounded,
            l10n.llmModelReply(value),
            ok,
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  static Widget _line(IconData icon, String text, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: AppSpace.md),
      Expanded(child: Text(text)),
    ],
  );
}
