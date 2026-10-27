import '../../../core/l10n/l10n.dart';
import '../domain/rag_models.dart';

String describeRagFailure(AppLocalizations l10n, RagFailure failure) =>
    switch (failure) {
      RagUnauthorized() => l10n.ragErrUnauthorized,
      RagRateLimited(:final retryAfterSeconds) => l10n.ragErrRateLimited(
        retryAfterSeconds ?? 60,
      ),
      RagNetworkFailure() => l10n.ragErrNetwork,
      RagServerFailure(:final statusCode) => l10n.ragErrServer(statusCode ?? 0),
      RagBadResponse() => l10n.ragErrBadResponse,
    };
