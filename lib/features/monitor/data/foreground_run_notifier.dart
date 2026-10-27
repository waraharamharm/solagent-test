import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/diagnostics.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../l10n/app_localizations.dart';
import '../../deploy/domain/deploy_models.dart';
import '../application/run_follower.dart';
import '../application/run_monitor.dart';

part 'foreground_run_notifier.g.dart';

@riverpod
IRunNotifier runNotifications(Ref ref) => ForegroundRunNotifier(ref);

/// Android foreground service of type `dataSync` with one notification that
/// shows the current install step. The monitor itself runs in the app
/// isolate; the service only keeps the process alive and visible.
class ForegroundRunNotifier implements IRunNotifier {
  ForegroundRunNotifier(this._ref);

  final Ref _ref;

  static const _serviceId = 4200;
  static var _initialised = false;

  AppLocalizations get _l10n => _ref.read(appL10nProvider);

  @override
  Future<bool> start() async {
    try {
      if (await FlutterForegroundTask.checkNotificationPermission() !=
          NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      _init();
      final result = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: _l10n.monitorTitle,
        notificationText: _l10n.monitorStarting,
      );
      return result is ServiceRequestSuccess;
    } on Object catch (e) {
      debugLogError('foreground service start', e);
      return false;
    }
  }

  void _init() {
    if (_initialised) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'solagent_run',
        channelName: _l10n.monitorChannelName,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowAutoRestart: false,
      ),
    );
    _initialised = true;
  }

  @override
  Future<void> update(RunSnapshot snapshot) =>
      showText(notificationText(_l10n, snapshot));

  @override
  Future<void> showText(String text) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: _l10n.monitorTitle,
        notificationText: text,
      );
    } on Object catch (e) {
      debugLogError('foreground service update', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await FlutterForegroundTask.stopService();
    } on Object catch (e) {
      debugLogError('foreground service stop', e);
    }
  }
}

/// Only the step name and the state, never log text.
String notificationText(AppLocalizations l10n, RunSnapshot s) {
  if (s.connectionLost) return l10n.monitorWaiting;
  return switch (s.state) {
    DeployState.finished =>
      s.exitCode == 0 ? l10n.monitorFinishedOk : l10n.monitorFinishedFailed,
    DeployState.lost || DeployState.unknown => l10n.monitorLost,
    DeployState.cancelled => l10n.monitorFinishedFailed,
    DeployState.running =>
      s.latest == null
          ? l10n.monitorStarting
          : l10n.monitorStep(s.latest!.step),
  };
}
