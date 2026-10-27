import '../../../core/l10n/l10n.dart';
import '../../llm/application/llm_connection_check.dart';
import '../application/fix_loop.dart';

/// Localized sentence for a run that ended with [FixOutcome.error]; the
/// technical detail from [FixFinished.message] follows it.
String fixFinishedErrorText(AppLocalizations l10n, FixFinished r) {
  final detail = r.message ?? '';
  return switch (r.errorKind) {
    FixErrorKind.ai => l10n.fixErrAi(
      r.llmFailure == null ? detail : describeLlmFailure(l10n, r.llmFailure!),
    ),
    FixErrorKind.aiFormat => l10n.fixErrAiFormat(detail),
    FixErrorKind.connection => l10n.fixErrConnection(detail),
    FixErrorKind.server => l10n.fixErrServer(detail),
    null => detail.isEmpty ? l10n.fixDemoErrorFallback : detail,
  };
}
