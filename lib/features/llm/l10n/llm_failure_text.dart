import '../../../core/l10n/l10n.dart';
import '../domain/llm_failure.dart';

/// Plain localized line, then the technical text with the HTTP code and the
/// provider's own message, so the user can search it or send it to support.
String describeLlmFailure(AppLocalizations l10n, LlmFailure f) {
  final plain = switch (f) {
    LlmUnauthorized(statusCode: 403) => l10n.llmErrForbidden,
    LlmUnauthorized() => l10n.llmErrUnauthorized,
    LlmRateLimited() => l10n.llmErrRateLimited,
    LlmNetworkFailure() => l10n.llmErrNetwork,
    LlmServerFailure() => l10n.llmErrServer,
    LlmBadResponse() => l10n.llmErrBadResponse,
  };
  return '$plain\n${f.message}';
}
