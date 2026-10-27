import '../../../core/validation/base_url.dart';
import 'llm_preset.dart';

/// Non-secret LLM settings. The API key itself is never part of this object;
/// only whether one is stored.
class LlmSettings {
  const LlmSettings({
    required this.preset,
    required this.baseUrl,
    required this.model,
    required this.hasApiKey,
  });

  factory LlmSettings.fromPreset(LlmPreset preset, {bool hasApiKey = false}) =>
      LlmSettings(
        preset: preset,
        baseUrl: preset.baseUrl,
        model: preset.defaultModel,
        hasApiKey: hasApiKey,
      );

  static final defaults = LlmSettings.fromPreset(LlmPreset.deepSeek);

  final LlmPreset preset;
  final String baseUrl;
  final String model;
  final bool hasApiKey;

  bool get isComplete =>
      hasApiKey && model.trim().isNotEmpty && validateBaseUrl(baseUrl) == null;

  LlmSettings copyWith({
    LlmPreset? preset,
    String? baseUrl,
    String? model,
    bool? hasApiKey,
  }) => LlmSettings(
    preset: preset ?? this.preset,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    hasApiKey: hasApiKey ?? this.hasApiKey,
  );

  Map<String, Object?> toJson() => {
    'preset': preset.name,
    'baseUrl': baseUrl,
    'model': model,
  };

  static LlmSettings fromJson(
    Map<String, Object?> json, {
    required bool hasApiKey,
  }) {
    final preset = LlmPreset.values.firstWhere(
      (p) => p.name == json['preset'],
      orElse: () => defaults.preset,
    );
    return LlmSettings(
      preset: preset,
      baseUrl: json['baseUrl'] as String? ?? preset.baseUrl,
      model: json['model'] as String? ?? preset.defaultModel,
      hasApiKey: hasApiKey,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LlmSettings &&
      other.preset == preset &&
      other.baseUrl == baseUrl &&
      other.model == model &&
      other.hasApiKey == hasApiKey;

  @override
  int get hashCode => Object.hash(preset, baseUrl, model, hasApiKey);
}
