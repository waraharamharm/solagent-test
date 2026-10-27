// Real VDS + real model. Needs SOLAGENT_VDS_HOST/USER/KEY (see the SSH
// integration test) and SOLAGENT_LLM_URL/MODEL/KEY. Writes only to the test
// user's ~/.solagent/jobs/ and ~/solagent-fixdemo-*, and removes both.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solagent/features/deploy/data/deploy_engine.dart';
import 'package:solagent/features/deploy/domain/deploy_models.dart';
import 'package:solagent/features/fix/application/fix_advisor.dart';
import 'package:solagent/features/fix/application/fix_loop.dart';
import 'package:solagent/features/fix/domain/log_redactor.dart';
import 'package:solagent/features/llm/data/openai_compatible_llm_service.dart';
import 'package:solagent/features/llm/domain/llm_config.dart';
import 'package:solagent/features/server/domain/server_profile.dart';
import 'package:solagent/features/ssh/data/dartssh2_connector.dart';
import 'package:solagent/features/ssh/data/known_hosts_store.dart';
import 'package:solagent/features/ssh/domain/ssh_target.dart';

import '../../support/memory_store.dart';

void main() {
  final env = Platform.environment;
  final ready =
      env['SOLAGENT_VDS_HOST'] != null && env['SOLAGENT_LLM_KEY'] != null;

  test(
    'failing script is diagnosed, fixed after approval and re-run',
    () async {
      final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
      final id = 'test-fix-$suffix';
      final demoDir = 'solagent-fixdemo-$suffix';
      final host = env['SOLAGENT_VDS_HOST']!;
      final user = env['SOLAGENT_VDS_USER']!;

      final session = await DartSsh2Connector(KnownHostsStore(MemoryStore()))
          .connect(
            SshTarget(host: host, username: user),
            SshKeyCredential(File(env['SOLAGENT_VDS_KEY']!).readAsBytesSync()),
            confirmNewHostKey: (_) async => true,
          );
      addTearDown(session.close);
      final engine = DeployEngine(session);
      addTearDown(() async {
        for (final j in [id, '$id-f1', '$id-r1', '$id-f2', '$id-r2']) {
          await engine.remove(j).catchError((_) {});
        }
        await session.run('rm -rf -- "\$HOME/$demoDir"');
      });

      final probe = await session.run(ServerInfo.probeCommand);
      final server = ServerInfo.parse(probe.stdout, fingerprint: '')!;

      final loop = FixLoop(
        engine: engine,
        advisor: FixAdvisor(
          OpenAiCompatibleLlmService(
            config: LlmConfig(
              baseUrl: env['SOLAGENT_LLM_URL'] ?? 'https://api.deepseek.com/v1',
              model: env['SOLAGENT_LLM_MODEL'] ?? 'deepseek-chat',
              apiKey: env['SOLAGENT_LLM_KEY']!,
            ),
          ),
          LogRedactor(host: host, user: user),
        ),
        server: server,
        maxRounds: 2,
        pollInterval: const Duration(seconds: 1),
      );

      final script = DeployScript(
        jobId: id,
        body:
            'set -e\n'
            'echo "reading config"\n'
            'grep -q "^port=" "\$HOME/$demoDir/app.conf"\n'
            'echo "config ok"\n',
      );
      final approved = <String>[];
      final events = await loop
          .run(
            script,
            confirm: (p) async {
              // ignore: avoid_print
              print(
                'diagnosis: ${p.diagnosis}\ncommand: ${p.command}\n'
                'warnings: ${p.verdict?.warnings}',
              );
              approved.add(p.command!);
              return true;
            },
          )
          .toList();

      final end = events.last as FixFinished;
      expect(end.outcome, FixOutcome.succeeded, reason: end.message);
      expect(approved, isNotEmpty);
    },
    skip: ready ? null : 'SOLAGENT_VDS_* / SOLAGENT_LLM_KEY not set',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
