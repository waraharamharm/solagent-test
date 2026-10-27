import 'package:solagent/features/ssh/domain/i_ssh_client.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

/// Records commands and answers each with the scripted stdout and exit code.
class FakeSshSession implements ISshSession {
  final commands = <String>[];
  String stdout = '';
  int exitCode = 0;

  @override
  SshTarget get target => const SshTarget(host: '203.0.113.7', username: 'u');

  @override
  bool get isClosed => false;

  @override
  Future<SshCommandResult> run(
    String command, {
    Duration timeout = const Duration(minutes: 1),
  }) async {
    commands.add(command);
    return SshCommandResult(exitCode: exitCode, stdout: stdout, stderr: '');
  }

  @override
  Future<void> close() async {}
}
