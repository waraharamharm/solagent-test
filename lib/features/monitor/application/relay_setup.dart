import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/diagnostics.dart';
import '../../../core/l10n/app_locale.dart';
import '../../rag/data/rag_settings_repository.dart';
import '../../rag/domain/rag_models.dart';
import '../data/fcm.dart';
import '../data/http_run_relay.dart';
import '../domain/checkpoint_prelude.dart';
import '../domain/run_relay.dart';

part 'relay_setup.g.dart';

/// Gives a script the shell helper it reports progress with. Never fails: if
/// push is not possible the helper still prints markers for the app.
abstract interface class CheckpointPreludeSource {
  Future<String> create();
}

@Riverpod(keepAlive: true)
CheckpointPreludeSource checkpointPreludeSource(Ref ref) => RelayPreludeSource(
  loadConfig: () => ref.read(ragSettingsRepositoryProvider).loadConfig(),
  language: () => ref.read(appLocaleProvider).languageCode,
  relayFor: (config) => HttpRunRelay(config: config),
);

class RelayPreludeSource implements CheckpointPreludeSource {
  RelayPreludeSource({
    required this._loadConfig,
    required this._language,
    required this._relayFor,
    this._getFcmToken = fcmToken,
  });

  final Future<RagConfig?> Function() _loadConfig;
  final String Function() _language;
  final IRunRelay Function(RagConfig) _relayFor;
  final Future<String?> Function() _getFcmToken;

  @override
  Future<String> create() async {
    try {
      final config = await _loadConfig();
      final token = config == null ? null : await _getFcmToken();
      if (config == null || token == null) return localCheckpointPrelude;
      final run = await _relayFor(config)
          .register(fcmToken: token, language: _language());
      return checkpointPrelude(
        relayUrl: config.baseUrl,
        runId: run.runId,
        runToken: run.token,
      );
    } on Object catch (e) {
      debugLogError('relay setup', e);
      return localCheckpointPrelude;
    }
  }
}
