import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/problem_text.dart';
import '../../ssh/domain/ssh_failure.dart';

/// Plain localized line, then the technical text of the failure.
String serverErrorText(AppLocalizations l10n, Object e) {
  final plain = switch (e) {
    SshHostKeyMismatch() => l10n.serverErrHostKeyMismatch,
    SshHostKeyRejected() => l10n.serverErrRejected,
    SshAuthFailed() => l10n.serverErrAuth,
    SshInvalidKey() => l10n.serverErrInvalidKey,
    SshNetworkFailure() => l10n.serverErrNetwork,
    SshTimeout() => l10n.serverErrTimeout,
    SshFailure() => l10n.serverErrSsh,
    AppProblemError(:final problem) => appProblemText(l10n, problem),
    _ => l10n.serverErrCheckFailed,
  };
  final detail = switch (e) {
    SshFailure(:final message) => message,
    AppProblemError() => null,
    _ => '$e',
  };
  return detail == null ? plain : '$plain\n$detail';
}
