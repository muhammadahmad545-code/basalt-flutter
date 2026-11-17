import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Flat surface with a hairline border. Tappable when [onTap] is set.
class BCard extends StatelessWidget {
  const BCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.lg),
      side: BorderSide(color: borderColor ?? p.border),
    );
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null || onLongPress != null) {
      body = InkWell(onTap: onTap, onLongPress: onLongPress, customBorder: shape, child: body);
    }
    final card = Material(color: color ?? p.surface, shape: shape, clipBehavior: Clip.antiAlias, child: body);
    return semanticLabel == null ? card : Semantics(label: semanticLabel, button: onTap != null, child: card);
  }
}

/// A small rounded square holding an icon, tinted with [color].
class BIconTile extends StatelessWidget {
  const BIconTile(this.icon, {super.key, this.color, this.size = 38});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final c = color ?? p.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: p.soft(c), borderRadius: BorderRadius.circular(Radii.md)),
      child: Icon(icon, size: size * 0.5, color: c),
    );
  }
}

/// A list row: optional leading icon tile, title, subtitle and trailing widget.
class BListRow extends StatelessWidget {
  const BListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.chevron = false,
    this.danger = false,
    this.dense = false,
    this.maxSubtitleLines = 2,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool chevron;
  final bool danger;
  final bool dense;
  final int maxSubtitleLines;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final lead = leading ?? (icon != null ? BIconTile(icon!, color: danger ? p.danger : iconColor, size: dense ? 32 : 38) : null);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Gap.lg, vertical: dense ? Gap.sm + 2 : Gap.md),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: Gap.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BasaltType.bodyStrong.copyWith(color: danger ? p.danger : p.text),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: maxSubtitleLines,
                      overflow: TextOverflow.ellipsis,
                      style: BasaltType.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
            if (chevron) ...[
              const SizedBox(width: Gap.xs),
              Icon(Icons.chevron_right_rounded, size: 20, color: p.textFaint),
            ],
          ],
        ),
      ),
    );
  }
}

/// A card that groups rows with hairline dividers between them.
class BGroup extends StatelessWidget {
  const BGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, indent: Gap.lg, endIndent: Gap.lg, color: p.border));
      rows.add(children[i]);
    }
    final card = Material(
      color: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: p.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
    if (title == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [BSectionTitle(title!), card],
    );
  }
}

/// Small uppercase label above a section.
class BSectionTitle extends StatelessWidget {
  const BSectionTitle(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.lg, Gap.xs, Gap.sm),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: BasaltType.overline.copyWith(color: p.textFaint))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: BasaltType.label.copyWith(color: p.accent)),
            ),
        ],
      ),
    );
  }
}

/// Large page title with optional subtitle and trailing actions, used at the top of tab screens.
class BHeader extends StatelessWidget {
  const BHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl - 4, Gap.lg, Gap.md, Gap.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(subtitle!, style: BasaltType.label.copyWith(color: p.textMuted)),
                  const SizedBox(height: 2),
                ],
                Text(title, style: BasaltType.display.copyWith(color: p.text)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

enum BButtonVariant { primary, secondary, ghost, danger }

/// Solid primary, outlined secondary, text-only ghost, or red danger button.
class BButton extends StatelessWidget {
  const BButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = BButtonVariant.primary,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BButtonVariant variant;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final onTap = busy ? null : onPressed;
    final fg = switch (variant) {
      BButtonVariant.primary => p.onAccent,
      BButtonVariant.danger => Colors.white,
      BButtonVariant.secondary => p.text,
      BButtonVariant.ghost => p.accent,
    };
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: 18),
        if (busy || icon != null) const SizedBox(width: Gap.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final Widget button = switch (variant) {
      BButtonVariant.primary => FilledButton(onPressed: onTap, child: child),
      BButtonVariant.danger => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(backgroundColor: p.danger, foregroundColor: Colors.white),
          child: child,
        ),
      BButtonVariant.secondary => OutlinedButton(onPressed: onTap, child: child),
      BButtonVariant.ghost => TextButton(onPressed: onTap, child: child),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Selectable pill.
class BChip extends StatelessWidget {
  const BChip({super.key, required this.label, this.selected = false, this.onTap, this.icon, this.color});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final tone = color ?? p.accent;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.soft(tone) : p.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? tone.withValues(alpha: 0.5) : p.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 15, color: selected ? tone : p.textMuted), const SizedBox(width: 6)],
                Text(label, style: BasaltType.label.copyWith(color: selected ? tone : p.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small status label.
class BBadge extends StatelessWidget {
  const BBadge(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final c = color ?? p.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: p.soft(c), borderRadius: BorderRadius.circular(Radii.pill)),
      child: Text(label, style: BasaltType.caption.copyWith(color: c, fontWeight: FontWeight.w600, fontSize: 11.5)),
    );
  }
}

/// A number with a label, for dashboards.
class BStatTile extends StatelessWidget {
  const BStatTile({super.key, required this.label, required this.value, this.icon, this.color, this.hint, this.onTap});

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return BCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      semanticLabel: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: color ?? p.textMuted), const SizedBox(width: 6)],
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: BasaltType.label.copyWith(color: p.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: BasaltType.title.copyWith(color: p.text, fontSize: 22)),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, maxLines: 1, overflow: TextOverflow.ellipsis, style: BasaltType.caption.copyWith(color: p.textFaint)),
          ],
        ],
      ),
    );
  }
}

/// Friendly empty state with an optional action.
class BEmptyState extends StatelessWidget {
  const BEmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xxl, vertical: Gap.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BIconTile(icon, size: 56, color: p.textMuted),
          const SizedBox(height: Gap.lg),
          Text(title, textAlign: TextAlign.center, style: BasaltType.heading.copyWith(color: p.text)),
          if (message != null) ...[
            const SizedBox(height: Gap.xs + 2),
            Text(message!, textAlign: TextAlign.center, style: BasaltType.body.copyWith(color: p.textMuted, fontSize: 14)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Gap.lg),
            BButton(label: actionLabel!, onPressed: onAction, variant: BButtonVariant.secondary),
          ],
        ],
      ),
    );
  }
}

/// Thin rounded progress bar.
class BProgressBar extends StatelessWidget {
  const BProgressBar({super.key, required this.value, this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.isNaN ? 0 : value.clamp(0, 1),
        minHeight: height,
        color: color ?? p.accent,
        backgroundColor: p.fill,
      ),
    );
  }
}

/// Circular progress ring with a centred child.
class BRing extends StatelessWidget {
  const BRing({super.key, required this.value, this.size = 96, this.stroke = 9, this.color, this.child});

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.isNaN ? 0 : value.clamp(0, 1),
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              color: color ?? p.accent,
              backgroundColor: p.fill,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// Minimal vertical bar chart (labels under bars). Values are relative.
class BBars extends StatelessWidget {
  const BBars({super.key, required this.values, this.labels, this.height = 120, this.highlight, this.color});

  final List<double> values;
  final List<String>? labels;
  final double height;
  final int? highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.basalt;
    final max = values.fold<double>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: height + (labels != null ? 26 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: max <= 0 ? 3 : (values[i] / max * height).clamp(3, height),
                      decoration: BoxDecoration(
                        color: (highlight == null || highlight == i) ? (color ?? p.accent) : p.fill,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    if (labels != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        labels![i],
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: BasaltType.caption.copyWith(color: p.textFaint, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Search field styled like the rest of the inputs.
class BSearchField extends StatelessWidget {
  const BSearchField({super.key, required this.onChanged, this.hint = 'Search', this.controller, this.autofocus = false});

  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

/// Toast helpers with consistent styling.
abstract final class BToast {
  static void show(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
        ),
      );
  }

  static Future<void> copy(BuildContext context, String text, {String message = 'Copied'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) show(context, message);
  }
}

/// A confirm dialog. Returns true when the user confirms.
Future<bool> bConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final p = context.basalt;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(foregroundColor: p.textMuted),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: danger ? p.danger : p.accent),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
