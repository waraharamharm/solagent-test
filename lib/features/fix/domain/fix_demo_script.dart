import '../../deploy/domain/deploy_models.dart';

/// Script for trying the repair loop without a real deployment: it fails
/// until `~/solagent-fixdemo/app.conf` has a `port=` line, and removes that
/// directory once it passes, so the demo can be repeated. It reports progress
/// with `solagent_checkpoint`, which the run controller defines in front of it.
DeployScript fixDemoScript() => DeployScript(
  jobId: 'fixdemo-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
  body: r'''
set -e
trap 'solagent_checkpoint config failed' ERR
solagent_checkpoint config started
echo "Checking the config"
grep -q '^port=' "$HOME/solagent-fixdemo/app.conf"
solagent_checkpoint config done
echo "Config is fine, demo passed"
rm -rf "$HOME/solagent-fixdemo"
solagent_checkpoint demo finished
''',
);
