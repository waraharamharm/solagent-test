import '../../deploy/domain/deploy_models.dart';
import 'run_monitor.dart';

/// The persistent "install in progress" notification. On Android it is a
/// foreground service, which keeps the process alive while the phone sleeps.
abstract interface class IRunNotifier {
  /// Asks for the notification permission if needed and starts the service.
  /// Returns false when it could not start; the run is then followed without
  /// the notification.
  Future<bool> start();

  Future<void> update(RunSnapshot snapshot);

  /// Replaces the notification text. Callers pass text without secrets.
  Future<void> showText(String text);

  Future<void> stop();
}

/// Follows [monitor] to the end of the run, mirroring each snapshot into
/// [notifier]. The service is always stopped, even if the watch throws.
Future<RunSnapshot> followRun(RunMonitor monitor, IRunNotifier notifier) async {
  final started = await notifier.start();
  RunSnapshot last = const RunSnapshot(state: DeployState.running);
  try {
    await for (final snapshot in monitor.watch()) {
      last = snapshot;
      if (started) await notifier.update(snapshot);
    }
  } finally {
    if (started) await notifier.stop();
  }
  return last;
}
