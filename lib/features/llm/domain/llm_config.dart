class LlmConfig {
  const LlmConfig({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  /// OpenAI v1 compatible root, e.g. `https://api.deepseek.com/v1`.
  /// `/chat/completions` is appended by the adapter.
  final String baseUrl;
  final String model;
  final String apiKey;

  @override
  String toString() =>
      'LlmConfig(baseUrl: $baseUrl, model: $model, apiKey: ***)';
}
