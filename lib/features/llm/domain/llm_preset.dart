enum LlmPreset {
  deepSeek('DeepSeek', 'https://api.deepseek.com/v1', 'deepseek-chat'),
  grok('Grok', 'https://api.x.ai/v1', 'grok-4'),
  openRouter(
    'OpenRouter',
    'https://openrouter.ai/api/v1',
    'deepseek/deepseek-chat',
  ),
  openAi('OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini'),
  custom('Custom endpoint', '', '');

  const LlmPreset(this.label, this.baseUrl, this.defaultModel);

  /// Brand name. Not translated; [LlmPreset.custom] has a localized name in
  /// the UI (`llmPresetLabel`).
  final String label;
  final String baseUrl;
  final String defaultModel;
}
