import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/grouped_list.dart';
import '../application/donate_providers.dart';
import '../domain/donate_option.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final options = ref.watch(donateOptionsProvider);
    final links = options.whereType<DonateLink>().toList();
    final transfers = options.whereType<DonateTransfer>().toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            Text(
              l10n.supportIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (links.isNotEmpty) ...[
              GroupHeader(l10n.supportGroupOnline),
              GroupedList(
                children: [
                  for (final o in links)
                    GroupedTile(
                      leading: const TileIcon(Icons.open_in_new_rounded),
                      title: o.label,
                      subtitle: l10n.supportOpensInBrowser,
                      onTap: () => _open(context, ref, o.url),
                    ),
                ],
              ),
            ],
            if (transfers.isNotEmpty) ...[
              GroupHeader(l10n.supportGroupTransfer),
              GroupedList(
                children: [
                  for (final o in transfers)
                    GroupedTile(
                      leading: const TileIcon(Icons.content_copy_rounded),
                      title: o.label,
                      subtitle: '${o.value} · ${l10n.supportTapToCopy}',
                      onTap: () => _copy(context, o.value),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, String url) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null && uri.scheme == 'https') {
      try {
        opened = await ref.read(urlOpenerProvider)(uri);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportOpenFailed)));
    }
  }

  Future<void> _copy(BuildContext context, String value) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(l10n.supportCopied)));
  }
}
