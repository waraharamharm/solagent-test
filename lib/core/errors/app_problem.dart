/// A user-facing problem raised below the UI. Logic code throws or returns
/// the code; only the UI turns it into text (see `appProblemText`), so no
/// layer below the UI knows a language.
enum AppProblem {
  serverNotConfigured,
  serverOsUnknown,
  aiNotConfigured,
  emptyKey,
  emptyPassword,
  baseUrlNotAbsolute,
  baseUrlInsecureHttp,
  baseUrlUnsupportedScheme,
  serverBadHost,
  serverBadPort,
  serverBadLogin,
}

class AppProblemError implements Exception {
  const AppProblemError(this.problem);

  final AppProblem problem;

  @override
  String toString() => 'AppProblemError(${problem.name})';
}
