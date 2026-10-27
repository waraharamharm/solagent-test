import '../../../core/l10n/l10n.dart';
import '../domain/llm_preset.dart';

String llmPresetLabel(AppLocalizations l10n, LlmPreset preset) =>
    preset == LlmPreset.custom ? l10n.llmPresetCustom : preset.label;
