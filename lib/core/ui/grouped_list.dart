import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rows joined into one rounded block with thin gaps, as in Material 3
/// Expressive lists: outer corners large, inner corners small.
class GroupedList extends StatelessWidget {
  const GroupedList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const outer = Radius.circular(AppRadius.card);
    const inner = Radius.circular(6);
    final color = Theme.of(context).colorScheme.surfaceContainer;
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 3),
            child: Material(
              color: color,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? outer : inner,
                  bottom: i == children.length - 1 ? outer : inner,
                ),
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class GroupedTile extends StatelessWidget {
  const GroupedTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;

  /// Extra content under the subtitle, such as a progress line.
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpace.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (below != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    below!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpace.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon on a tonal tile, the leading element of [GroupedTile].
class TileIcon extends StatelessWidget {
  const TileIcon(this.icon, {super.key, this.background, this.foreground});

  final IconData icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background ?? scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: foreground ?? scheme.onSecondaryContainer),
    );
  }
}

/// A coloured dot and a short word: "на связи", "готов".
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// Heading above a group on a settings page.
class GroupHeader extends StatelessWidget {
  const GroupHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.sm,
      AppSpace.xl,
      AppSpace.sm,
      AppSpace.sm,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// Large page title of a tab.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.sm,
      AppSpace.lg,
      0,
      AppSpace.sm,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
        ),
        ?trailing,
      ],
    ),
  );
}
