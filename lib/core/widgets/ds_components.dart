import 'package:flutter/material.dart';

import '../../app/design/app_typography.dart';
import '../../app/design/design_tokens.dart';

/// Shared building blocks for the Gradient look.
///
/// Screens compose these rather than hand-rolling containers, so padding,
/// radius and elevation stay identical everywhere. If a screen needs a shape
/// that is not here, the shape is probably wrong.

/// A surface panel: white on the canvas, hairline border, the softest shadow.
class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DsSpace.x4),
    this.onTap,
    this.elevated = false,
    this.sunken = false,
    this.background,
    this.borderColor,
    this.radius = DsRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Drops the border for a soft shadow instead.
  final bool elevated;

  /// A recessed panel: no border, no shadow, sunken fill.
  final bool sunken;

  final Color? background;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill =
        background ??
        (sunken ? scheme.surfaceContainerHighest : scheme.surface);

    final decorated = AnimatedContainer(
      duration: DsMotion.fast,
      curve: DsMotion.ease,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: DsRadius.all(radius),
        border: (elevated || sunken)
            ? null
            : Border.all(color: borderColor ?? scheme.outlineVariant),
        boxShadow: sunken ? null : (elevated ? DsShadow.lg : DsShadow.xs),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      borderRadius: DsRadius.all(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: DsRadius.all(radius),
        child: decorated,
      ),
    );
  }
}

/// The eyebrow above a group of content. The only uppercase style in the app.
class DsSectionLabel extends StatelessWidget {
  const DsSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.x2_5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppType.overline.copyWith(
                color: scheme.onSurfaceVariant,
                fontFamily: AppType.family,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The rounded icon chip that fronts a tile or a list row.
class DsIconChip extends StatelessWidget {
  const DsIconChip({
    super.key,
    required this.icon,
    this.size = 40,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer,
        borderRadius: DsRadius.all(size * 0.29),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: foreground ?? scheme.onPrimaryContainer,
      ),
    );
  }
}

/// A tile in the dashboard's two-column grid.
class DsActionTile extends StatelessWidget {
  const DsActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DsSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DsIconChip(icon: icon),
          const SizedBox(height: DsSpace.x3),
          Text(
            title,
            style: AppType.bodySm.copyWith(
              color: scheme.onSurface,
              fontWeight: AppType.semibold,
            ),
          ),
          const SizedBox(height: DsSpace.x0_5),
          Text(
            subtitle,
            style: AppType.caption.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A row inside a grouped list — the settings pattern, with hairline
/// separators supplied by [DsListGroup].
class DsListRow extends StatelessWidget {
  const DsListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = danger ? scheme.error : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpace.x4,
          vertical: DsSpace.x4,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(
                leading,
                size: 20,
                color: danger ? scheme.error : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: DsSpace.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.body.copyWith(
                      color: tint,
                      fontWeight: danger ? AppType.semibold : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: DsSpace.x0_5),
                    Text(
                      subtitle!,
                      style: AppType.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: DsSpace.x3),
              trailing!,
            ] else if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Wraps rows in one card with hairline separators between them.
class DsListGroup extends StatelessWidget {
  const DsListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: DsRadius.all(DsRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: DsShadow.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A calm, bordered notice. Used for privacy notes, errors and empty states.
class DsNotice extends StatelessWidget {
  const DsNotice({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline,
    this.title,
    this.tone = DsNoticeTone.neutral,
  });

  final String text;
  final IconData icon;
  final String? title;
  final DsNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (tone) {
      DsNoticeTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      DsNoticeTone.accent => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      DsNoticeTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpace.x4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DsRadius.all(DsRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: DsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppType.bodySm.copyWith(
                      color: fg,
                      fontWeight: AppType.semibold,
                    ),
                  ),
                  const SizedBox(height: DsSpace.x1),
                ],
                Text(text, style: AppType.bodySm.copyWith(color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum DsNoticeTone { neutral, accent, danger }

/// The brand mark: the app's single gradient moment on most screens.
class DsBrandMark extends StatelessWidget {
  const DsBrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: DsGradient.aurora,
        borderRadius: DsRadius.all(size * 0.29),
        boxShadow: DsShadow.sm,
      ),
      child: Icon(
        Icons.verified_user_outlined,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}
