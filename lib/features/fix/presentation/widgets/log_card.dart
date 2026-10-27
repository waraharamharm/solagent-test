import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';

class LogCard extends StatefulWidget {
  const LogCard({super.key, required this.lines});

  final List<String> lines;

  @override
  State<LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = widget.lines;
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.5,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.xs,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.fixDemoLogTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _open = !_open),
                child: Text(
                  _open
                      ? context.l10n.fixDemoLogCollapse
                      : context.l10n.fixDemoLogShowAll,
                ),
              ),
            ],
          ),
          if (_open)
            SizedBox(
              height: 320,
              child: ListView.builder(
                reverse: true,
                itemCount: lines.length,
                itemBuilder: (context, i) =>
                    _line(lines[lines.length - 1 - i], style, scheme),
              ),
            )
          else
            Text(
              _tail(lines),
              style: style,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Lines like `── Запуск скрипта ──` that the controller puts between jobs.
  static String? _marker(String line) =>
      line.startsWith('── ') && line.endsWith(' ──') && line.length > 6
      ? line.substring(3, line.length - 3)
      : null;

  static String _tail(List<String> lines) {
    final output = [
      for (final l in lines)
        if (_marker(l) == null) l,
    ];
    return output.skip(output.length > 4 ? output.length - 4 : 0).join('\n');
  }

  static Widget _line(String line, TextStyle style, ColorScheme scheme) {
    final marker = _marker(line);
    if (marker == null) return Text(line, style: style);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
      child: Text(
        marker,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}
