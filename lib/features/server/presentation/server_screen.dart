import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_problem.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/problem_text.dart';
import '../../../core/security/biometric_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/grouped_list.dart';
import '../../../core/ui/wavy_progress.dart';
import '../../ssh/domain/ssh_target.dart';
import '../../ssh/domain/ssh_failure.dart';
import '../application/server_providers.dart';
import '../domain/server_profile.dart';

class ServerScreen extends StatelessWidget {
  const ServerScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const BiometricGuard(child: _ServerView());
}

class _ServerView extends ConsumerStatefulWidget {
  const _ServerView();

  @override
  ConsumerState<_ServerView> createState() => _ServerViewState();
}

class _ServerViewState extends ConsumerState<_ServerView> {
  final _formKey = GlobalKey<FormState>();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '22');
  final _user = TextEditingController(text: 'root');
  final _secret = TextEditingController();
  ServerAuthKind _kind = ServerAuthKind.password;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = ServerProfile(
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _user.text.trim(),
      authKind: _kind,
    );
    try {
      await ref
          .read(serverControllerProvider.notifier)
          .save(profile, _secret.text);
      _secret.clear();
    } on AppProblemError catch (e) {
      if (mounted) _message(appProblemText(context.l10n, e.problem));
    }
  }

  Future<bool> _confirmFingerprint(HostKeyInfo info) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.serverNewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.serverFingerprintPrompt(
                'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub',
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              info.fingerprint,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.serverFingerprintMatches),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _confirmForget() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.serverForgetTitle),
        content: Text(context.l10n.serverForgetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.invalidate(serverCheckProvider);
    await ref.read(serverControllerProvider.notifier).forget();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serverControllerProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (state) {
          AsyncData(:final value) when value.isConfigured => _configured(
            context,
            value.profile!,
          ),
          AsyncData() => _form(context),
          AsyncError() => Center(child: Text(context.l10n.serverLoadFailed)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  EdgeInsets _padding(BuildContext context) => EdgeInsets.fromLTRB(
    AppSpace.lg,
    AppSpace.sm,
    AppSpace.lg,
    kDockClearance + MediaQuery.viewPaddingOf(context).bottom,
  );

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    final secretLabel = _kind == ServerAuthKind.key
        ? l10n.serverSecretKeyLabel
        : l10n.commonPassword;
    return Form(
      key: _formKey,
      child: ListView(
        padding: _padding(context),
        children: [
          PageTitle(l10n.commonServer),
          GroupHeader(l10n.serverSectionAddress),
          TextFormField(
            controller: _host,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: l10n.serverHostLabel),
            validator: (v) => problemTextOrNull(
              l10n,
              validateServerProfile(
                ServerProfile(host: (v ?? '').trim(), username: 'root'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _user,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.serverUserLabel),
                  validator: (v) => problemTextOrNull(
                    l10n,
                    validateServerProfile(
                      ServerProfile(host: 'x', username: (v ?? '').trim()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _port,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.serverPortLabel),
                  validator: (v) {
                    final port = int.tryParse((v ?? '').trim());
                    if (port == null) return l10n.serverPortNotNumber;
                    return problemTextOrNull(
                      l10n,
                      validateServerProfile(
                        ServerProfile(host: 'x', username: 'root', port: port),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          GroupHeader(l10n.serverSectionLogin),
          SegmentedButton<ServerAuthKind>(
            segments: [
              ButtonSegment(
                value: ServerAuthKind.password,
                label: Text(l10n.commonPassword),
              ),
              ButtonSegment(
                value: ServerAuthKind.key,
                label: Text(l10n.serverAuthKey),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _secret.clear();
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey(_kind),
            controller: _secret,
            obscureText: _kind == ServerAuthKind.password,
            maxLines: _kind == ServerAuthKind.key ? 6 : 1,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(labelText: secretLabel),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? l10n.serverFieldRequired : null,
          ),
          const SizedBox(height: AppSpace.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
          ),
        ],
      ),
    );
  }

  Widget _configured(BuildContext context, ServerProfile p) {
    final check = ref.watch(serverCheckProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return ListView(
      padding: _padding(context),
      children: [
        PageTitle(l10n.commonServer),
        const SizedBox(height: AppSpace.sm),
        GroupedList(
          children: [
            GroupedTile(
              leading: TileIcon(
                Icons.dns_rounded,
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
              ),
              title: p.host,
              subtitle: l10n.serverProfileSubtitle(
                p.username,
                p.port,
                p.authKind == ServerAuthKind.key
                    ? l10n.serverAuthByKey
                    : l10n.serverAuthByPassword,
              ),
              trailing: IconButton(
                tooltip: l10n.serverForgetTooltip,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _confirmForget,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: check.isLoading
                ? null
                : () => ref
                      .read(serverCheckProvider.notifier)
                      .run(_confirmFingerprint),
            child: Text(l10n.serverCheck),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        switch (check) {
          AsyncLoading() => const WavyProgress(),
          AsyncError(:final error) => GroupedList(
            children: [
              _fact(
                Icons.error_rounded,
                scheme.error,
                serverErrorText(l10n, error),
              ),
            ],
          ),
          AsyncData(:final value?) => _info(value, scheme),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  Widget _info(ServerInfo i, ColorScheme scheme) {
    final status = StatusColors.of(context);
    final l10n = context.l10n;
    return GroupedList(
      children: [
        _fact(
          i.isSupportedOs ? Icons.check_circle_rounded : Icons.error_rounded,
          i.isSupportedOs ? status.ok : scheme.error,
          i.isSupportedOs
              ? '${i.prettyName}, ${i.arch}'
              : l10n.serverOsUnsupported(i.prettyName),
        ),
        _fact(
          i.isRoot ? Icons.check_circle_rounded : Icons.info_rounded,
          i.isRoot ? status.ok : status.warn,
          i.isRoot ? l10n.serverLoginRoot : l10n.serverLoginNotRoot,
        ),
        if (i.fingerprint.isNotEmpty)
          _fact(
            Icons.verified_user_rounded,
            status.ok,
            l10n.serverFingerprintPinned,
            i.fingerprint,
          ),
      ],
    );
  }

  Widget _fact(IconData icon, Color color, String text, [String? detail]) =>
      Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: Theme.of(context).textTheme.bodyLarge),
                  if (detail != null)
                    SelectableText(
                      detail,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Plain localized line, then the technical text of the failure.
String serverErrorText(AppLocalizations l10n, Object e) {
  final plain = switch (e) {
    SshHostKeyMismatch() => l10n.serverErrHostKeyMismatch,
    SshHostKeyRejected() => l10n.serverErrRejected,
    SshAuthFailed() => l10n.serverErrAuth,
    SshInvalidKey() => l10n.serverErrInvalidKey,
    SshNetworkFailure() => l10n.serverErrNetwork,
    SshTimeout() => l10n.serverErrTimeout,
    SshFailure() => l10n.serverErrSsh,
    AppProblemError(:final problem) => appProblemText(l10n, problem),
    _ => l10n.serverErrCheckFailed,
  };
  final detail = switch (e) {
    SshFailure(:final message) => message,
    AppProblemError() => null,
    _ => '$e',
  };
  return detail == null ? plain : '$plain\n$detail';
}
