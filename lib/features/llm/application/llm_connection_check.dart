import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/l10n/app_locale.dart';
import '../domain/chat_message.dart';
import '../domain/llm_failure.dart';
import '../l10n/llm_failure_text.dart';
import 'llm_providers.dart';

part 'llm_connection_check.g.dart';

/// User-facing error of the connection check, already in the user's language.
/// Never carries the key.
class LlmCheckError implements Exception {
  const LlmCheckError(this.text);

  final String text;

  @override
  String toString() => text;
}

/// State: null = not run yet, data = trimmed model reply.
@riverpod
class LlmConnectionCheck extends _$LlmConnectionCheck {
  static const _maxReplyLength = 200;

  @override
  AsyncValue<String?> build() {
    ref.listen(llmSettingsControllerProvider, (previous, next) {
      final before = previous?.value;
      if (before != null && before != next.value) {
        state = const AsyncData(null);
      }
    });
    return const AsyncData(null);
  }

  Future<void> run() async {
    state = const AsyncLoading();
    final l10n = ref.read(appL10nProvider);
    try {
      final service = await ref.read(llmServiceProvider.future);
      if (service == null) {
        _set(
          AsyncError(
            LlmCheckError(l10n.llmCheckNeedSettings),
            StackTrace.empty,
          ),
        );
        return;
      }
      final response = await service.complete(const [
        ChatMessage.user('Reply with the single word: ok'),
      ], temperature: 0);
      final reply = response.content.trim();
      _set(
        AsyncData(
          reply.length > _maxReplyLength
              ? reply.substring(0, _maxReplyLength)
              : reply,
        ),
      );
    } on LlmFailure catch (e, st) {
      _set(AsyncError(LlmCheckError(describeLlmFailure(l10n, e)), st));
    } catch (e, st) {
      _set(AsyncError(LlmCheckError(l10n.llmCheckFailedWithError('$e')), st));
    }
  }

  void _set(AsyncValue<String?> next) {
    if (ref.mounted) state = next;
  }
}
