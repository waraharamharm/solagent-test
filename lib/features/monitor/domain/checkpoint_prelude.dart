final _relayUrl = RegExp(r'^https://[A-Za-z0-9.-]+(:\d{1,5})?$');
final _runId = RegExp(r'^[0-9a-f]{16}$');
final _runToken = RegExp(r'^run_[A-Za-z0-9_-]{43}$');

/// Shell snippet for the top of an install script. It defines
/// `solagent_checkpoint STEP STATE`, which prints the marker the app reads
/// from the log and tells the relay (best effort: a failed request never
/// stops the install). All values are checked against strict patterns first,
/// so nothing here can break out of the single quotes.
String checkpointPrelude({
  required String relayUrl,
  required String runId,
  required String runToken,
}) {
  final url = relayUrl.replaceAll(RegExp(r'/+$'), '');
  if (!_relayUrl.hasMatch(url) ||
      !_runId.hasMatch(runId) ||
      !_runToken.hasMatch(runToken)) {
    throw ArgumentError('Relay address, run id or token has an invalid shape');
  }
  return '''
SOLAGENT_RELAY='$url'
SOLAGENT_RUN='$runId'
SOLAGENT_TOKEN='$runToken'
solagent_checkpoint() {
  printf '@@SOLAGENT {"step":"%s","state":"%s"}\\n' "\$1" "\$2"
  printf 'header = "Authorization: Bearer %s"\\n' "\$SOLAGENT_TOKEN" |
    curl -fsS -m 10 -K - -X POST \\
      -H 'Content-Type: application/json' \\
      -d "{\\"step\\":\\"\$1\\",\\"state\\":\\"\$2\\"}" \\
      "\$SOLAGENT_RELAY/v1/runs/\$SOLAGENT_RUN/checkpoints" >/dev/null 2>&1 || true
}
''';
}

/// Same helper without the relay: it only prints the marker. Used when the
/// phone has no access key or push address, so scripts never break.
const localCheckpointPrelude = r'''
solagent_checkpoint() {
  printf '@@SOLAGENT {"step":"%s","state":"%s"}\n' "$1" "$2"
}
''';
