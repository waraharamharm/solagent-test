import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/diagnostics.dart';
import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/app_locale.dart';
import '../../deploy/data/deploy_engine.dart';
import '../../journal/data/journal_store.dart';
import '../../journal/domain/i_journal.dart';
import '../../journal/domain/journal_entry.dart';
import '../../llm/application/llm_providers.dart';
import '../../rag/application/rag_providers.dart';
import '../../rag/domain/rag_models.dart';
import '../../server/data/server_repository.dart';
import '../../server/domain/server_profile.dart';
import '../../ssh/data/dartssh2_connector.dart';
import '../../ssh/domain/i_ssh_client.dart';
import '../domain/log_redactor.dart';
import 'fix_advisor.dart';
import 'fix_loop.dart';
import 'fix_session.dart';

part 'ssh_fix_session_factory.g.dart';

@Riverpod(keepAlive: true)
FixSessionFactory fixSessionFactory(Ref ref) => SshFixSessionFactory(ref);

/// Opens the saved server over SSH. The host key must already be pinned (done
/// on the server screen); a new key is refused here.
class SshFixSessionFactory implements FixSessionFactory {
  SshFixSessionFactory(this._ref);

  final Ref _ref;

  /// English name of the language the AI answers in. Add a case with each new
  /// app language; unknown codes fall back to English like the UI does.
  static String aiLanguage(String code) => switch (code) {
    'ru' => 'Russian',
    _ => 'English',
  };

  @override
  Future<FixSession> open() async {
    final llm = await _ref.read(llmServiceProvider.future);
    if (llm == null) throw const AppProblemError(AppProblem.aiNotConfigured);

    final repo = _ref.read(serverRepositoryProvider);
    final target = await repo.loadTarget();
    final credential = await repo.loadCredential();
    if (target == null || credential == null) {
      throw const AppProblemError(AppProblem.serverNotConfigured);
    }

    final session = await _ref
        .read(sshConnectorProvider)
        .connect(target, credential, confirmNewHostKey: (_) async => false);
    try {
      final server = await _probe(session);
      final redactor = LogRedactor(host: target.host, user: target.username);
      final journal = JournalStore(session, redactor);
      return FixSession(
        loop: FixLoop(
          engine: DeployEngine(session),
          advisor: FixAdvisor(
            llm,
            redactor,
            language: aiLanguage(_ref.read(appLocaleProvider).languageCode),
            rag: await _ragOrNull(),
          ),
          server: server,
          history: await _history(journal),
        ),
        journal: journal,
        close: session.close,
      );
    } catch (_) {
      await session.close();
      rethrow;
    }
  }

  Future<ServerInfo> _probe(ISshSession session) async {
    final probe = await session.run(ServerInfo.probeCommand);
    final server = ServerInfo.parse(probe.stdout, fingerprint: '');
    if (!probe.succeeded || server == null) {
      throw const AppProblemError(AppProblem.serverOsUnknown);
    }
    return server;
  }

  /// A missing or unreadable journal must not stop a run: no history.
  Future<List<JournalEntry>> _history(IJournal journal) async {
    try {
      return await journal.readRecent();
    } catch (e) {
      debugLogError('journal read', e);
      return const [];
    }
  }

  /// The knowledge base is optional: without a key or when it fails, the AI
  /// repairs without it.
  Future<IRagService?> _ragOrNull() async {
    try {
      return await _ref.read(ragServiceProvider.future);
    } catch (e) {
      debugLogError('rag setup', e);
      return null;
    }
  }
}
