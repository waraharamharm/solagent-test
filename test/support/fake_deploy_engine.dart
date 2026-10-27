import 'package:solagent/features/deploy/data/deploy_engine.dart';
import 'package:solagent/features/deploy/domain/deploy_models.dart';

/// Each started job finishes on the first poll with the scripted result.
class FakeEngine implements DeployEngine {
  FakeEngine(this.results);

  /// job id -> (exit code, log lines). Missing ids exit 0 with no output.
  final Map<String, (int, List<String>)> results;
  final started = <DeployScript>[];
  final cancelled = <String>[];

  @override
  Future<void> start(DeployScript script) async => started.add(script);

  @override
  Future<DeployProgress> poll(String jobId, {int fromLine = 0}) async {
    final (code, lines) = results[jobId] ?? (0, const <String>[]);
    final rest = lines.skip(fromLine).toList();
    return DeployProgress(
      state: DeployState.finished,
      newLines: rest,
      nextLine: fromLine + rest.length,
      exitCode: code,
    );
  }

  @override
  Future<void> cancel(String jobId) async => cancelled.add(jobId);

  @override
  Future<void> remove(String jobId) async {}
}
