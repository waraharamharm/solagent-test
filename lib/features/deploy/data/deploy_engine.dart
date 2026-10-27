import 'dart:convert';

import '../../ssh/domain/i_ssh_client.dart';
import '../domain/deploy_models.dart';

/// Runs a script on the VDS detached from the SSH session, so a dropped
/// connection does not kill it, and reads progress back by polling.
///
/// Layout on the server: `$HOME/.solagent/jobs/ID/{script.sh, runner.sh,
/// log, pid, exit, cancelled}`. No root needed. The detach uses `setsid nohup`; it
/// survives logout and network loss, but not a server reboot (state `lost`).
class DeployEngine {
  DeployEngine(this._session);

  final ISshSession _session;

  static const _runner = r'''#!/bin/bash
cd "$(dirname "$0")" || exit 1
bash script.sh > log 2>&1 < /dev/null
echo $? > exit.tmp && mv exit.tmp exit
''';

  static const maxLinesPerPoll = 500;

  String _dir(String id) => r'"$HOME"/.solagent/jobs/' + id;

  /// Uploads and starts [script]. Throws [DeployFailure] if the job id is
  /// already used or the server refused to start it.
  Future<void> start(DeployScript script) async {
    final scriptBytes = utf8.encode(script.body);
    if (scriptBytes.length > DeployScript.maxBytes) {
      throw const DeployFailure('Script is too large');
    }
    final dir = _dir(script.jobId);
    final scriptB64 = base64.encode(scriptBytes);
    final runnerB64 = base64.encode(utf8.encode(_runner));

    final result = await _session.run(
      'mkdir -p "\$HOME"/.solagent/jobs && chmod 700 "\$HOME"/.solagent '
      '&& mkdir -m 700 $dir '
      '&& cd $dir '
      '&& echo $scriptB64 | base64 -d > script.sh '
      '&& echo $runnerB64 | base64 -d > runner.sh '
      '&& chmod 700 script.sh runner.sh '
      '&& { setsid nohup bash runner.sh >/dev/null 2>&1 </dev/null & '
      'echo \$! > pid; }',
      timeout: const Duration(seconds: 30),
    );
    if (!result.succeeded) {
      final exists = result.stderr.contains('File exists');
      throw DeployFailure(
        exists ? 'Job "${script.jobId}" already exists' : 'Could not start job',
      );
    }
  }

  /// Returns log lines after [fromLine] (0-based count of lines already
  /// seen) and the current job state. While the job runs, a trailing line
  /// without newline is held back until it is complete.
  Future<DeployProgress> poll(String jobId, {int fromLine = 0}) async {
    if (!isValidJobId(jobId)) throw ArgumentError.value(jobId, 'jobId');
    if (fromLine < 0) throw ArgumentError.value(fromLine, 'fromLine');
    final dir = _dir(jobId);
    final result = await _session.run(
      'cd $dir 2>/dev/null || { echo STATE=unknown; echo EXIT=; echo ---; exit 0; }; '
      'if [ -f cancelled ]; then echo STATE=cancelled; echo EXIT=; '
      'elif [ -f exit ]; then echo STATE=finished; echo EXIT=\$(cat exit); '
      'elif kill -0 "\$(cat pid 2>/dev/null)" 2>/dev/null; then '
      'echo STATE=running; echo EXIT=; '
      'else echo STATE=lost; echo EXIT=; fi; '
      'echo ---; '
      'tail -n +${fromLine + 1} log 2>/dev/null | head -n $maxLinesPerPoll',
      timeout: const Duration(seconds: 20),
    );
    if (!result.succeeded) {
      throw const DeployFailure('Could not read job state');
    }

    final out = result.stdout;
    final sep = out.indexOf('---\n');
    if (sep < 0) throw const DeployFailure('Unexpected poll output');
    final header = {
      for (final line in LineSplitter.split(out.substring(0, sep)))
        if (line.contains('='))
          line.substring(0, line.indexOf('=')): line.substring(
            line.indexOf('=') + 1,
          ),
    };
    final state = switch (header['STATE']) {
      'running' => DeployState.running,
      'finished' => DeployState.finished,
      'cancelled' => DeployState.cancelled,
      'lost' => DeployState.lost,
      _ => DeployState.unknown,
    };
    final exitCode = int.tryParse(header['EXIT'] ?? '');

    final body = out.substring(sep + 4);
    final lines = body.isEmpty ? <String>[] : body.split('\n');
    // split leaves '' after a final newline, or a partial line otherwise.
    final tail = lines.isEmpty ? '' : lines.removeLast();
    if (tail.isNotEmpty && state != DeployState.running) lines.add(tail);

    return DeployProgress(
      state: state,
      newLines: lines,
      nextLine: fromLine + lines.length,
      exitCode: exitCode,
    );
  }

  /// Stops the job's process group. Safe to call on a finished job.
  Future<void> cancel(String jobId) async {
    if (!isValidJobId(jobId)) throw ArgumentError.value(jobId, 'jobId');
    await _session.run(
      'cd ${_dir(jobId)} 2>/dev/null && { [ -f exit ] || touch cancelled; } && p=\$(cat pid 2>/dev/null) '
      '&& [ -n "\$p" ] && kill -TERM -- -"\$p" 2>/dev/null; true',
      timeout: const Duration(seconds: 15),
    );
  }

  /// Deletes the job directory (script, log). Refuses a running job.
  Future<void> remove(String jobId) async {
    final progress = await poll(jobId, fromLine: 1 << 30);
    if (progress.state == DeployState.running) {
      throw const DeployFailure('Job is still running');
    }
    await _session.run(
      'rm -rf -- ${_dir(jobId)}',
      timeout: const Duration(seconds: 15),
    );
  }
}
