import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/grouped_list.dart';
import '../../domain/server_profile.dart';

/// What the check found out about the server: OS, login, pinned fingerprint.
class ServerInfoCard extends StatelessWidget {
  const ServerInfoCard(this.info, {super.key});

  final ServerInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final l10n = context.l10n;
    final i = info;
    return GroupedList(
      children: [
        ServerFact(
          i.isSupportedOs ? Icons.check_circle_rounded : Icons.error_rounded,
          i.isSupportedOs ? status.ok : scheme.error,
          i.isSupportedOs
              ? '${i.prettyName}, ${i.arch}'
              : l10n.serverOsUnsupported(i.prettyName),
        ),
        ServerFact(
          i.isRoot ? Icons.check_circle_rounded : Icons.info_rounded,
          i.isRoot ? status.ok : status.warn,
          i.isRoot ? l10n.serverLoginRoot : l10n.serverLoginNotRoot,
        ),
        if (i.fingerprint.isNotEmpty)
          ServerFact(
            Icons.verified_user_rounded,
            status.ok,
            l10n.serverFingerprintPinned,
            detail: i.fingerprint,
          ),
      ],
    );
  }
}

/// One row of a result list: icon, sentence and an optional monospace detail.
class ServerFact extends StatelessWidget {
  const ServerFact(this.icon, this.color, this.text, {this.detail, super.key});

  final IconData icon;
  final Color color;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
                Text(text, style: theme.textTheme.bodyLarge),
                if (detail != null)
                  SelectableText(
                    detail!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
