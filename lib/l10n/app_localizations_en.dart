// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SolAgent';

  @override
  String get commonServer => 'Server';

  @override
  String get commonAi => 'AI';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonDecisionNeeded => 'Your decision needed';

  @override
  String get commonWorking => 'In progress';

  @override
  String get commonSelfHealing => 'Self-healing';

  @override
  String get shellTabOverview => 'Overview';

  @override
  String get shellTabDeploy => 'Deployment';

  @override
  String get shellJobRun => 'Run';

  @override
  String get homeServerNotConnected => 'Not connected';

  @override
  String get homeServerSaved => 'saved';

  @override
  String get homeAiNoKey => 'No key';

  @override
  String get homeAiReady => 'ready';

  @override
  String get homeRunWaiting => 'Waiting for your decision';

  @override
  String get homeRunLastSucceeded => 'Last run passed';

  @override
  String get homeRunDemo => 'Demo on your server';

  @override
  String get homeRunLastFailed => 'Last run failed';

  @override
  String get homeHeroReviewCommand => 'Review the command';

  @override
  String get homeHeroServerBusy => 'The server is running a task';

  @override
  String get homeHeroOpen => 'Open';

  @override
  String get homeHeroConnectServerTitle => 'Connect a server';

  @override
  String get homeHeroConnectServerBody =>
      'Your VDS address and a password or key. We’ll check the system and remember the server’s fingerprint.';

  @override
  String get homeHeroAddServer => 'Add server';

  @override
  String get homeHeroConnectAiTitle => 'Connect AI';

  @override
  String get homeHeroConnectAiBody =>
      'You’ll need your own API key: DeepSeek, Grok, OpenRouter, OpenAI, or a custom address.';

  @override
  String get homeHeroAddKey => 'Add key';

  @override
  String get homeHeroAllSetTitle => 'Everything is connected';

  @override
  String get homeHeroAllSetBody =>
      'Server and AI are ready. Try self-healing on the demo script.';

  @override
  String get homeHeroOpenDemo => 'Open demo';

  @override
  String get homeThemeTooltip => 'Theme';

  @override
  String get homeThemeSystem => 'Match system';

  @override
  String get homeThemeLight => 'Light';

  @override
  String get homeThemeDark => 'Dark';

  @override
  String get homeLanguageTooltip => 'Language';

  @override
  String get homeLanguageAuto => 'Match device';

  @override
  String get homeSupportTitle => 'Support the project';

  @override
  String get homeSupportSubtitle => 'Donation for development';

  @override
  String get supportTitle => 'Support the project';

  @override
  String get supportIntro =>
      'SolAgent is free. A donation is a voluntary gift for the development of the project, not payment for access or features.';

  @override
  String get supportGroupOnline => 'Online';

  @override
  String get supportGroupTransfer => 'Direct transfer';

  @override
  String get supportOpensInBrowser => 'Opens in your browser';

  @override
  String get supportTapToCopy => 'Tap to copy';

  @override
  String get supportCopied => 'Copied';

  @override
  String get supportOpenFailed => 'Could not open the link';

  @override
  String get serverNewTitle => 'New server';

  @override
  String serverFingerprintPrompt(String command) {
    return 'Compare this fingerprint with the one on your server. Run this on the server:\n$command';
  }

  @override
  String get serverFingerprintMatches => 'It matches';

  @override
  String get serverForgetTitle => 'Remove the server?';

  @override
  String get serverForgetBody =>
      'The address and the password or key will be deleted from this device.';

  @override
  String get serverForgetTooltip => 'Remove server';

  @override
  String get serverLoadFailed => 'Couldn’t load the server';

  @override
  String get serverSecretKeyLabel => 'Private key (PEM / OpenSSH)';

  @override
  String get serverSectionAddress => 'Address';

  @override
  String get serverHostLabel => 'IP or domain';

  @override
  String get serverUserLabel => 'Username';

  @override
  String get serverPortLabel => 'Port';

  @override
  String get serverPortNotNumber => 'Enter a number';

  @override
  String get serverSectionLogin => 'Sign-in';

  @override
  String get serverAuthKey => 'Key';

  @override
  String get serverFieldRequired => 'Fill in this field';

  @override
  String serverProfileSubtitle(String username, int port, String auth) {
    return '$username · port $port · $auth';
  }

  @override
  String get serverAuthByKey => 'key';

  @override
  String get serverAuthByPassword => 'password';

  @override
  String get serverCheck => 'Check server';

  @override
  String serverOsUnsupported(String os) {
    return '$os: only Ubuntu and Debian are supported';
  }

  @override
  String get serverLoginRoot => 'Signed in as root';

  @override
  String get serverLoginNotRoot =>
      'Not signed in as root: installation needs sudo';

  @override
  String get serverFingerprintPinned => 'Fingerprint saved';

  @override
  String get serverErrHostKeyMismatch =>
      'The server’s fingerprint has changed. Either the server was reinstalled or the connection is being intercepted. The connection was refused.';

  @override
  String get serverErrRejected => 'Connection cancelled';

  @override
  String get serverErrAuth => 'The server rejected the password or key';

  @override
  String get serverErrInvalidKey =>
      'The key can’t be read or needs a passphrase';

  @override
  String get serverErrNetwork =>
      'Server unreachable: check the address and port';

  @override
  String get serverErrTimeout => 'The server didn’t respond in time';

  @override
  String get serverErrSsh => 'SSH error';

  @override
  String get serverErrCheckFailed => 'Couldn’t check the server';

  @override
  String get fixDemoStop => 'Stop';

  @override
  String get fixDemoStart => 'Run demo';

  @override
  String get fixDemoProposalSubtitle => 'The AI suggests one command';

  @override
  String get fixDemoWorkingTitle => 'Working on it';

  @override
  String get fixDemoConnecting => 'Connecting…';

  @override
  String get fixDemoDoneTitle => 'Done';

  @override
  String get fixDemoDoneSubtitle => 'The script passed after the fix';

  @override
  String get fixDemoStoppedTitle => 'Stopped';

  @override
  String get fixDemoDeclinedSubtitle => 'You declined the command';

  @override
  String get fixDemoCancelledSubtitle => 'The run was interrupted';

  @override
  String get fixDemoNotFixedTitle => 'Not fixed';

  @override
  String fixDemoNoFixSubtitle(String message) {
    return 'The AI found no safe command: $message';
  }

  @override
  String get fixDemoGaveUpSubtitle => 'Couldn’t fix it after several attempts';

  @override
  String get fixDemoLostTitle => 'Task interrupted';

  @override
  String get fixDemoLostSubtitle => 'The server rebooted or ran out of memory';

  @override
  String get fixDemoErrorTitle => 'Error';

  @override
  String get fixDemoErrorFallback => 'Something went wrong';

  @override
  String fixDemoIdleSubtitle(String path) {
    return 'The demo script fails without the file $path. The AI will find the cause and suggest a command.';
  }

  @override
  String get fixDemoErrHostNotChecked =>
      'The server hasn’t been checked yet. Open the Server tab and tap “Check server”.';

  @override
  String fixDemoErrStartFailed(String error) {
    return 'Couldn’t start the run\n$error';
  }

  @override
  String get fixDemoDecline => 'Decline';

  @override
  String get fixDemoApprove => 'Run';

  @override
  String get fixDemoLogTitle => 'Server log';

  @override
  String get fixDemoLogCollapse => 'Collapse';

  @override
  String get fixDemoLogShowAll => 'Full log';

  @override
  String get llmLoadFailed => 'Couldn’t load the settings';

  @override
  String get llmSettingsSaved => 'Settings saved';

  @override
  String get llmClearKeyTitle => 'Delete the key?';

  @override
  String get llmClearKeyBody => 'The key will be removed from this device.';

  @override
  String get llmSectionProvider => 'Provider';

  @override
  String get llmSectionEndpoint => 'Address and model';

  @override
  String get llmModelLabel => 'Model';

  @override
  String get llmApiKey => 'API key';

  @override
  String get llmKeySaved => 'Key saved';

  @override
  String get llmKeyDeleteTooltip => 'Delete key';

  @override
  String get llmSaveKey => 'Save key';

  @override
  String get llmSectionCheck => 'Check';

  @override
  String get llmCheckConnection => 'Test connection';

  @override
  String get llmCheckFailed => 'Couldn’t run the check';

  @override
  String llmModelReply(String reply) {
    return 'Model reply: $reply';
  }

  @override
  String get problemServerNotConfigured => 'The server isn’t set up yet';

  @override
  String get problemServerOsUnknown =>
      'Couldn’t detect the server’s operating system';

  @override
  String get problemAiNotConfigured => 'Set up the AI and its key first';

  @override
  String get problemEmptyKey => 'The key is empty';

  @override
  String get problemEmptyPassword => 'The password is empty';

  @override
  String get problemBaseUrlNotAbsolute =>
      'Enter a full address, for example https://api.example.com/v1';

  @override
  String get problemBaseUrlInsecureHttp =>
      'Without https your key would travel as plain text. Use http only on a local network';

  @override
  String get problemBaseUrlUnsupportedScheme =>
      'Only http and https are supported';

  @override
  String get problemServerBadHost => 'Invalid server address';

  @override
  String get problemServerBadPort => 'Port must be from 1 to 65535';

  @override
  String get problemServerBadLogin => 'Invalid login';

  @override
  String get llmPresetCustom => 'Custom endpoint';

  @override
  String get llmCheckNeedSettings => 'Fill in the settings and the key first';

  @override
  String llmCheckFailedWithError(String error) {
    return 'Couldn’t run the check\n$error';
  }

  @override
  String get llmErrForbidden =>
      'Access denied. A common cause is your region: turn on a VPN';

  @override
  String get llmErrUnauthorized =>
      'The key was not accepted: make sure you pasted all of it';

  @override
  String get llmErrRateLimited =>
      'Rate limit reached or the balance has run out';

  @override
  String get llmErrNetwork => 'Can’t reach the provider';

  @override
  String get llmErrServer => 'Provider error';

  @override
  String get llmErrBadResponse => 'The provider sent a response we can’t read';

  @override
  String get fixStatusConnecting => 'Connecting to the server…';

  @override
  String get fixStatusWaitingDecision => 'Waiting for your decision';

  @override
  String get fixStepYourDecision => 'Your decision';

  @override
  String get fixStepRunScript => 'Starting the script';

  @override
  String fixStepRerun(int round) {
    return 'Re-run $round';
  }

  @override
  String fixStepFix(int round) {
    return 'Fix $round';
  }

  @override
  String fixLogExitCode(int code) {
    return '── exit code $code ──';
  }

  @override
  String get fixDetailJobInterrupted => 'The job was interrupted';

  @override
  String fixDetailJobFailedCode(int code) {
    return 'Failed, code $code';
  }

  @override
  String fixStatusDiagnosing(int round) {
    return 'The AI is analyzing the error (attempt $round)…';
  }

  @override
  String get fixStepDiagnosing => 'The AI is looking for the cause';

  @override
  String fixLogBlockedCommand(String reason) {
    return '── The AI proposed a forbidden command, rejected: $reason ──';
  }

  @override
  String get fixDetailCommandForbidden =>
      'The command is forbidden by the rules; the AI was asked for another one';

  @override
  String get fixDetailAllowed => 'Allowed';

  @override
  String get fixDetailDeclined => 'Declined';

  @override
  String fixErrAi(String detail) {
    return 'AI: $detail';
  }

  @override
  String fixErrAiFormat(String detail) {
    return 'The AI answered in an unexpected format\n$detail';
  }

  @override
  String fixErrConnection(String detail) {
    return 'Connection to the server was lost\n$detail';
  }

  @override
  String fixErrServer(String detail) {
    return 'Server: $detail';
  }

  @override
  String get blockCurlPipeShell =>
      'Downloading a script from the internet and running it (curl | bash)';

  @override
  String get blockPipeToShell => 'Piping text into a shell to run it';

  @override
  String get blockPipeToInterpreter =>
      'Piping text into an interpreter to run it';

  @override
  String get blockRunDownloaded =>
      'Running something that was downloaded from the internet';

  @override
  String get blockProcessSubstitution =>
      'Running a script through process substitution';

  @override
  String get blockEval => 'eval hides what will be run';

  @override
  String get blockDecodeHidden => 'Decoding hidden content';

  @override
  String get blockEscapedBytes => 'Escaped bytes inside the command';

  @override
  String get blockNoPreserveRoot => 'Deleting the filesystem root';

  @override
  String get blockFindDelete => 'Mass deletion with find';

  @override
  String get blockDiskPartitioning => 'Working with disk partitions';

  @override
  String get blockWriteToDevice => 'Writing straight to a device';

  @override
  String get blockForkBomb => 'Fork bomb';

  @override
  String get blockRebootShutdown => 'Rebooting or shutting down the server';

  @override
  String get blockAccountChanges => 'Changing user accounts';

  @override
  String get blockCredentialsAccess =>
      'Access to keys, passwords or login settings';

  @override
  String get blockStopSsh =>
      'Stopping SSH: you would lose access to the server';

  @override
  String get blockFirewallReset => 'Resetting the firewall';

  @override
  String get blockRawNetwork => 'Raw network connection (data could leak)';

  @override
  String get blockKillAll => 'Terminating all processes';

  @override
  String get blockCronRemoval => 'Deleting all cron jobs';

  @override
  String get blockHistoryHiding => 'Hiding the command history';

  @override
  String get blockInteractiveSu => 'Interactive login as another user';

  @override
  String get blockSolagentDir => 'SolAgent’s own working directory';

  @override
  String get blockDownloadAndRun =>
      'Downloading a file from the internet and running it';

  @override
  String get blockXargsExec => 'Running text through xargs';

  @override
  String get blockEmpty => 'Empty command';

  @override
  String get blockTooLong => 'The command is too long';

  @override
  String get blockControlChars => 'Invisible control characters';

  @override
  String get blockRecursiveDelete =>
      'Recursive deletion of the root, home or a system directory';

  @override
  String get blockRecursiveChmod =>
      'Recursive permission change on a system directory';

  @override
  String get warnRoot => 'Runs with root rights';

  @override
  String get warnRm => 'Deletes files without asking';

  @override
  String get warnPackages => 'Removes packages';

  @override
  String get warnService => 'Stops or restarts a service';

  @override
  String get warnDocker => 'Deletes Docker containers or data';

  @override
  String get warnChmod777 => 'Makes a file writable by everyone';

  @override
  String get warnEtcOverwrite => 'Overwrites a system file';

  @override
  String get warnKill => 'Terminates processes';

  @override
  String get warnDownload => 'Downloads from the internet';

  @override
  String get warnFirewall => 'Changes the firewall';

  @override
  String get guardReason => 'Confirm it’s you to access the server';

  @override
  String get guardUnavailable =>
      'No screen lock or fingerprint is set up on this device. Turn one on in the phone settings: without it, access to the server stays closed.';

  @override
  String get guardDenied => 'Access closed';

  @override
  String get guardChecking => 'Checking…';

  @override
  String get guardUnlock => 'Unlock';

  @override
  String get ragSectionTitle => 'Knowledge base';

  @override
  String get ragHint =>
      'Documentation and approved solutions help the AI with typical errors. Only a scrubbed excerpt of the error is sent.';

  @override
  String get ragAddressLabel => 'Server address';

  @override
  String get ragKeyLabel => 'Access key';

  @override
  String get ragSaveKey => 'Save access key';

  @override
  String get ragKeySaved => 'Access key saved';

  @override
  String get ragKeyDeleteTooltip => 'Delete access key';

  @override
  String get ragClearKeyTitle => 'Delete the access key?';

  @override
  String get ragClearKeyBody =>
      'The AI will repair without the knowledge base.';

  @override
  String get ragCheck => 'Check knowledge base';

  @override
  String ragCheckOk(int count) {
    return 'Connected. Passages found: $count';
  }

  @override
  String get ragErrUnauthorized => 'The server rejected the key.';

  @override
  String ragErrRateLimited(int seconds) {
    return 'Too many requests. Try again in $seconds s.';
  }

  @override
  String get ragErrNetwork => 'Could not reach the knowledge base.';

  @override
  String ragErrServer(int status) {
    return 'The knowledge base failed (HTTP $status).';
  }

  @override
  String get ragErrBadResponse => 'Unexpected reply from the knowledge base.';

  @override
  String get ragNoKey => 'Save an access key first.';

  @override
  String get monitorChannelName => 'Install progress';

  @override
  String get monitorTitle => 'SolAgent: install in progress';

  @override
  String get monitorStarting => 'Starting…';

  @override
  String monitorStep(String step) {
    return 'Step: $step';
  }

  @override
  String get monitorWaiting =>
      'No connection to the server, retrying. The install keeps running.';

  @override
  String get monitorFinishedOk => 'Install finished';

  @override
  String get monitorFinishedFailed => 'Install finished with an error';

  @override
  String get monitorLost => 'The install process was stopped on the server';

  @override
  String get fixStatusStopping => 'Stopping the install…';

  @override
  String get fixDemoStopping => 'Stopping…';
}
