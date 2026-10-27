import '../../../core/l10n/l10n.dart';
import '../domain/command_policy.dart';

String blockReasonText(AppLocalizations l10n, BlockReason reason) =>
    switch (reason) {
      BlockReason.curlPipeShell => l10n.blockCurlPipeShell,
      BlockReason.pipeToShell => l10n.blockPipeToShell,
      BlockReason.pipeToInterpreter => l10n.blockPipeToInterpreter,
      BlockReason.runDownloaded => l10n.blockRunDownloaded,
      BlockReason.processSubstitution => l10n.blockProcessSubstitution,
      BlockReason.eval => l10n.blockEval,
      BlockReason.decodeHidden => l10n.blockDecodeHidden,
      BlockReason.escapedBytes => l10n.blockEscapedBytes,
      BlockReason.noPreserveRoot => l10n.blockNoPreserveRoot,
      BlockReason.findDelete => l10n.blockFindDelete,
      BlockReason.diskPartitioning => l10n.blockDiskPartitioning,
      BlockReason.writeToDevice => l10n.blockWriteToDevice,
      BlockReason.forkBomb => l10n.blockForkBomb,
      BlockReason.rebootShutdown => l10n.blockRebootShutdown,
      BlockReason.accountChanges => l10n.blockAccountChanges,
      BlockReason.credentialsAccess => l10n.blockCredentialsAccess,
      BlockReason.stopSsh => l10n.blockStopSsh,
      BlockReason.firewallReset => l10n.blockFirewallReset,
      BlockReason.rawNetwork => l10n.blockRawNetwork,
      BlockReason.killAll => l10n.blockKillAll,
      BlockReason.cronRemoval => l10n.blockCronRemoval,
      BlockReason.historyHiding => l10n.blockHistoryHiding,
      BlockReason.interactiveSu => l10n.blockInteractiveSu,
      BlockReason.solagentDir => l10n.blockSolagentDir,
      BlockReason.downloadAndRun => l10n.blockDownloadAndRun,
      BlockReason.xargsExec => l10n.blockXargsExec,
      BlockReason.empty => l10n.blockEmpty,
      BlockReason.tooLong => l10n.blockTooLong,
      BlockReason.controlChars => l10n.blockControlChars,
      BlockReason.recursiveDelete => l10n.blockRecursiveDelete,
      BlockReason.recursiveChmod => l10n.blockRecursiveChmod,
    };

String commandWarningText(AppLocalizations l10n, CommandWarning warning) =>
    switch (warning) {
      CommandWarning.root => l10n.warnRoot,
      CommandWarning.rm => l10n.warnRm,
      CommandWarning.packages => l10n.warnPackages,
      CommandWarning.service => l10n.warnService,
      CommandWarning.docker => l10n.warnDocker,
      CommandWarning.chmod777 => l10n.warnChmod777,
      CommandWarning.etcOverwrite => l10n.warnEtcOverwrite,
      CommandWarning.kill => l10n.warnKill,
      CommandWarning.download => l10n.warnDownload,
      CommandWarning.firewall => l10n.warnFirewall,
    };
