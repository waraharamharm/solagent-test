/// Why a command is refused. Language-neutral: the UI shows a localized text,
/// and [english] is what the AI is told when it proposes something forbidden.
enum BlockReason {
  curlPipeShell('Downloading a script from the internet and running it'),
  pipeToShell('Piping text into a shell to run it'),
  pipeToInterpreter('Piping text into an interpreter to run it'),
  runDownloaded('Running something that was downloaded from the internet'),
  processSubstitution('Running a script through process substitution'),
  eval('eval hides what will be run'),
  decodeHidden('Decoding hidden content'),
  escapedBytes('Escaped bytes inside the command'),
  noPreserveRoot('Deleting the filesystem root'),
  findDelete('Mass deletion with find'),
  diskPartitioning('Working with disk partitions'),
  writeToDevice('Writing straight to a device'),
  forkBomb('Fork bomb'),
  rebootShutdown('Rebooting or shutting down the server'),
  accountChanges('Changing user accounts'),
  credentialsAccess('Access to keys, passwords or login settings'),
  stopSsh('Stopping SSH: access to the server would be lost'),
  firewallReset('Resetting the firewall'),
  rawNetwork('Raw network connection (data could leak)'),
  killAll('Terminating all processes'),
  cronRemoval('Deleting all cron jobs'),
  historyHiding('Hiding the command history'),
  interactiveSu('Interactive login as another user'),
  solagentDir("SolAgent's own working directory"),
  downloadAndRun('Downloading a file from the internet and running it'),
  xargsExec('Running text through xargs'),
  empty('Empty command'),
  tooLong('The command is too long'),
  controlChars('Invisible control characters'),
  recursiveDelete('Recursive deletion of the root, home or a system directory'),
  recursiveChmod('Recursive permission change on a system directory');

  const BlockReason(this.english);

  final String english;
}

/// A risk that does not block the command but is shown next to it.
enum CommandWarning {
  root,
  rm,
  packages,
  service,
  docker,
  chmod777,
  etcOverwrite,
  kill,
  download,
  firewall,
}

/// Static screen for AI-proposed shell commands. It is a second line of
/// defence: the first is that the user sees and approves every command.
/// A denylist cannot catch every obfuscation, so anything that hides what it
/// runs (eval, decoding into a shell) is refused outright.
class CommandVerdict {
  const CommandVerdict._(this.blockedReason, this.warnings);

  /// Null when the command may be offered to the user.
  final BlockReason? blockedReason;

  /// Shown next to the command in the confirmation dialog.
  final List<CommandWarning> warnings;

  bool get isBlocked => blockedReason != null;
}

class _Rule<T> {
  const _Rule(this.pattern, this.result);

  final String pattern;
  final T result;
}

abstract final class CommandPolicy {
  static const maxLength = 4000;

  /// Order does not matter; the first match is reported.
  static const _blocked = <_Rule<BlockReason>>[
    _Rule(
      r'(curl|wget|fetch)\b[^\n]*\|\s*(sudo\s+(-\S+\s+)*)?(env\s+)?(ba|da|z|k|c|tc|fi)?sh\b',
      BlockReason.curlPipeShell,
    ),
    _Rule(
      r'\|&?\s*(sudo\s+(-\S+\s+)*)?(env\s+)?(ba|da|z|k|c|tc|fi)?sh\b',
      BlockReason.pipeToShell,
    ),
    _Rule(
      r'\|\s*(sudo\s+)?(python[0-9.]*|perl|ruby|node|php)\b',
      BlockReason.pipeToInterpreter,
    ),
    _Rule(r'(\$\(|`|<\()\s*(curl|wget)\b', BlockReason.runDownloaded),
    _Rule(r'\b(ba|da|z)?sh\s+<\(', BlockReason.processSubstitution),
    _Rule(r'(^|[;&|(\s])eval\b', BlockReason.eval),
    _Rule(
      r'base64\s+(-d|--decode)|xxd\s+-r|openssl\s+(enc|base64)\s[^\n]*-d',
      BlockReason.decodeHidden,
    ),
    _Rule(r"\$'[^']*\\(x[0-9a-f]{2}|[0-7]{3})", BlockReason.escapedBytes),
    _Rule(r'--no-preserve-root', BlockReason.noPreserveRoot),
    _Rule(
      r'\bfind\s+(\S+\s+)*?(/|~|\$HOME|/[A-Za-z0-9_.-]+)/?\s[^\n]*-delete\b',
      BlockReason.findDelete,
    ),
    _Rule(
      r'\b(mkfs(\.\w+)?|wipefs|fdisk|sfdisk|parted|mkswap)\b',
      BlockReason.diskPartitioning,
    ),
    _Rule(r'\bdd\b[^\n]*\bof=/dev/', BlockReason.writeToDevice),
    _Rule(r'>\s*/dev/(sd|vd|xvd|nvme|hd|mmcblk)', BlockReason.writeToDevice),
    _Rule(r':\s*\(\s*\)\s*\{', BlockReason.forkBomb),
    _Rule(
      r'(^|[;&|(\s])(sudo\s+)?(shutdown|reboot|poweroff|halt|telinit)\b|\binit\s+[06]\b|systemctl\s+(reboot|poweroff|halt|kexec|emergency|rescue)',
      BlockReason.rebootShutdown,
    ),
    _Rule(
      r'\b(userdel|deluser|usermod|passwd|chpasswd|chsh|visudo|adduser|useradd)\b',
      BlockReason.accountChanges,
    ),
    _Rule(
      r'authorized_keys|\.ssh\b|/etc/ssh\b|/etc/sudoers|/etc/shadow|/etc/passwd|/etc/gshadow|/etc/pam\.d',
      BlockReason.credentialsAccess,
    ),
    _Rule(
      r'systemctl\s+(stop|disable|mask|kill)\s+(\S+\s+)*ssh(d)?(\.service)?\b|\b(pkill|killall)\s+(-\S+\s+)*sshd?\b',
      BlockReason.stopSsh,
    ),
    _Rule(
      r'\biptables\s+(-\S+\s+)*-(F|X|P)\b|\bip6tables\s+(-\S+\s+)*-(F|X|P)\b|\bufw\s+(disable|reset)\b|\bnft\s+flush\b',
      BlockReason.firewallReset,
    ),
    _Rule(
      r'\b(nc|ncat|netcat|socat|telnet)\b|/dev/(tcp|udp)/',
      BlockReason.rawNetwork,
    ),
    _Rule(r'\bkill\s+(-\S+\s+)*-1\b', BlockReason.killAll),
    _Rule(r'\bcrontab\s+(-\S+\s+)*-r\b', BlockReason.cronRemoval),
    _Rule(r'\bhistory\s+-c\b|unset\s+HISTFILE', BlockReason.historyHiding),
    _Rule(
      r'(^|[;&|(\s])(sudo\s+)?su(\s|$)|sudo\s+-[is]\b',
      BlockReason.interactiveSu,
    ),
    _Rule(r'\.solagent\b', BlockReason.solagentDir),
    _Rule(
      r'(curl|wget)\b[\s\S]*(\b(ba|da|z)?sh\s+[^-\s]|chmod\s+(\S+\s+)*\+?[0-7]*[+x]|(^|[\s;&|])\./)',
      BlockReason.downloadAndRun,
    ),
    _Rule(
      r'\bxargs\b[^\n|;]*\b((ba|da|z)?sh|python[0-9.]*|perl)\b',
      BlockReason.xargsExec,
    ),
  ];

  static const _warned = <_Rule<CommandWarning>>[
    _Rule(r'(^|[;&|(\s])sudo\b', CommandWarning.root),
    _Rule(r'\brm\s+(-\S+\s+)*-\S*[rRf]', CommandWarning.rm),
    _Rule(
      r'\b(apt|apt-get|dpkg)\s+(-\S+\s+)*(remove|purge|autoremove|-r|-P)\b',
      CommandWarning.packages,
    ),
    _Rule(
      r'\bsystemctl\s+(stop|disable|mask|restart)\b|\bservice\s+\S+\s+(stop|restart)\b',
      CommandWarning.service,
    ),
    _Rule(
      r'\bdocker\s+(rm|rmi|system\s+prune|volume\s+(rm|prune))\b',
      CommandWarning.docker,
    ),
    _Rule(r'\bchmod\s+(-\S+\s+)*[0-7]?777\b', CommandWarning.chmod777),
    _Rule(r'>\s*/etc/', CommandWarning.etcOverwrite),
    _Rule(r'\bkill(all)?\b|\bpkill\b', CommandWarning.kill),
    _Rule(r'\b(curl|wget)\b', CommandWarning.download),
    _Rule(r'\b(ufw|iptables|ip6tables|nft)\b', CommandWarning.firewall),
  ];

  static final _blockedRe = [
    for (final r in _blocked)
      (RegExp(r.pattern, caseSensitive: false, multiLine: true), r.result),
  ];
  static final _warnedRe = [
    for (final r in _warned)
      (RegExp(r.pattern, caseSensitive: false, multiLine: true), r.result),
  ];

  static final _controlChars = RegExp(r'[\x00-\x08\x0B-\x1F\x7F]');

  static CommandVerdict check(String command) {
    final c = command.trim();
    if (c.isEmpty) return const CommandVerdict._(BlockReason.empty, []);
    if (c.length > maxLength) {
      return const CommandVerdict._(BlockReason.tooLong, []);
    }
    if (_controlChars.hasMatch(c)) {
      return const CommandVerdict._(BlockReason.controlChars, []);
    }
    for (final (re, reason) in _blockedRe) {
      if (re.hasMatch(c)) return CommandVerdict._(reason, const []);
    }
    final recursive = _recursiveOnProtectedPath(c);
    if (recursive != null) return CommandVerdict._(recursive, const []);
    final warnings = <CommandWarning>{
      for (final (re, warning) in _warnedRe)
        if (re.hasMatch(c)) warning,
    }.toList();
    return CommandVerdict._(null, warnings);
  }

  static final _segmentSplit = RegExp(r'&&|\|\||[;&|\n()`{}]|\$\(');
  static const _recursiveTools = {'rm', 'chmod', 'chown', 'chgrp'};

  /// `rm`, `chmod`, `chown`, `chgrp` with a recursive flag and any argument
  /// that is `/`, a top-level directory, home, a glob of those, or an
  /// unexpanded variable (empty `$X` turns `rm -rf $X/` into `rm -rf /`).
  static BlockReason? _recursiveOnProtectedPath(String command) {
    for (final segment in command.split(_segmentSplit)) {
      final tokens = segment
          .split(RegExp(r'\s+'))
          .map((t) => t.replaceAll(RegExp('["\']'), ''))
          .where((t) => t.isNotEmpty)
          .toList();
      final i = tokens.indexWhere(
        (t) => _recursiveTools.contains(t.split('/').last),
      );
      if (i < 0) continue;
      final isRm = tokens[i].split('/').last == 'rm';
      final args = tokens.sublist(i + 1);
      final recursiveFlag = args.any(
        (a) =>
            a == '--recursive' ||
            (a.startsWith('-') &&
                !a.startsWith('--') &&
                a.contains(isRm ? RegExp('[rR]') : RegExp('R'))),
      );
      if (!recursiveFlag) continue;
      for (final a in args.where((a) => !a.startsWith('-'))) {
        if (_isProtectedPath(a)) {
          return isRm
              ? BlockReason.recursiveDelete
              : BlockReason.recursiveChmod;
        }
      }
    }
    return null;
  }

  static final _topLevel = RegExp(r'^/[^/]*/?\*?$');
  static final _homeChild = RegExp(r'^(~|\$HOME|\$\{HOME\})/[^/*?]+');

  static bool _isProtectedPath(String p) {
    if (_topLevel.hasMatch(p)) return true;
    if (const {
      '~',
      '~/',
      '~/*',
      '*',
      '.',
      '..',
      './',
      '../',
      '.*',
      './*',
    }.contains(p)) {
      return true;
    }
    if (p.startsWith('..') || p.contains('/..')) return true;
    if (p.contains(r'$') || p.startsWith('~')) return !_homeChild.hasMatch(p);
    return false;
  }
}
