import '../errors/app_problem.dart';
import 'l10n.dart';

/// For form validators: null means valid.
String? problemTextOrNull(AppLocalizations l10n, AppProblem? problem) =>
    problem == null ? null : appProblemText(l10n, problem);

String appProblemText(AppLocalizations l10n, AppProblem problem) =>
    switch (problem) {
      AppProblem.serverNotConfigured => l10n.problemServerNotConfigured,
      AppProblem.serverOsUnknown => l10n.problemServerOsUnknown,
      AppProblem.aiNotConfigured => l10n.problemAiNotConfigured,
      AppProblem.emptyKey => l10n.problemEmptyKey,
      AppProblem.emptyPassword => l10n.problemEmptyPassword,
      AppProblem.baseUrlNotAbsolute => l10n.problemBaseUrlNotAbsolute,
      AppProblem.baseUrlInsecureHttp => l10n.problemBaseUrlInsecureHttp,
      AppProblem.baseUrlUnsupportedScheme =>
        l10n.problemBaseUrlUnsupportedScheme,
      AppProblem.serverBadHost => l10n.problemServerBadHost,
      AppProblem.serverBadPort => l10n.problemServerBadPort,
      AppProblem.serverBadLogin => l10n.problemServerBadLogin,
    };
