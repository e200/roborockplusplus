import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

import 'components.dart';

/// Roborock++'s own components. Nothing here uses Material's ListTile, Switch, Slider, SegmentedButton or AppBar:
/// look and touch feel are defined here, the same on Android and iOS.

/// Page background: a very light gradient instead of a flat colour.
class PageBackground extends StatelessWidget {
  final Widget child;

  const PageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = s.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [Color.lerp(s.surface, s.primary, 0.10)!, s.surface]
              : [Color.lerp(Colors.white, s.primary, 0.07)!, Colors.white],
        ),
      ),
      child: child,
    );
  }
}

/// Large page header (replaces the AppBar).
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const PageHeader({super.key, required this.title, this.subtitle, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme, s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                if (subtitle != null) Text(subtitle!, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Round back button for pushed pages.
class BackPill extends StatelessWidget {
  const BackPill({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Pressable(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: s.primary.withValues(alpha: 0.10), shape: BoxShape.circle),
        child: Icon(Icons.arrow_back_rounded, color: s.primary),
      ),
    );
  }
}

/// Press with a soft sink, instead of Material's ripple.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: Tokens.fast,
          curve: Tokens.curve,
          child: AnimatedOpacity(opacity: enabled ? 1 : 0.45, duration: Tokens.fast, child: widget.child),
        ),
      ),
    );
  }
}

/// Section title.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Grouped card: the rows inside are separated by thin lines.
class Group extends StatelessWidget {
  final List<Widget> children;

  const Group({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = s.brightness == Brightness.dark;
    final rows = <Widget>[];
    for (final (i, c) in children.indexed) {
      if (i > 0) {
        rows.add(Divider(height: 1, thickness: 1, indent: 60, color: s.outlineVariant.withValues(alpha: 0.35)));
      }
      rows.add(c);
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: dark ? s.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(Tokens.radius),
        boxShadow: dark
            ? null
            : [BoxShadow(color: s.primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(children: rows),
    );
  }
}

/// Icon inside a coloured rounded square (identifies each row).
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const IconBadge(this.icon, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, size: 19, color: color),
  );
}

/// Setting row: icon, title, description and a control on the right or below.
class Row2 extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  const Row2({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme, s = Theme.of(context).colorScheme;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (below != null) Padding(padding: const EdgeInsets.only(left: 46, top: 10), child: below),
        ],
      ),
    );
    return onTap == null ? body : Pressable(onTap: onTap, child: body);
  }
}

/// Custom switch: a capsule with a sliding knob.
class Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const Toggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: Tokens.fast,
          curve: Tokens.curve,
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? s.primary : s.onSurface.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: AnimatedAlign(
            duration: Tokens.fast,
            curve: Tokens.curve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pick one option out of several: pills, the chosen one filled.
class PillChoice<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T>? onChanged;

  const PillChoice({super.key, required this.options, required this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in options.entries)
          Pressable(
            onTap: onChanged == null ? null : () => onChanged!(e.key),
            semanticLabel: e.value,
            child: AnimatedContainer(
              duration: Tokens.fast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: e.key == selected ? s.primary : s.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                e.value,
                style: TextStyle(fontWeight: FontWeight.w600, color: e.key == selected ? s.onPrimary : s.primary),
              ),
            ),
          ),
      ],
    );
  }
}

/// Draggable level bar (volume): thick track with fill, without Material's thumb.
class LevelBar extends StatefulWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChangeEnd;

  const LevelBar({super.key, required this.value, this.max = 100, required this.onChangeEnd});

  @override
  State<LevelBar> createState() => _LevelBarState();
}

class _LevelBarState extends State<LevelBar> {
  late double _v = widget.value.toDouble();

  void _update(double dx, double width) =>
      setState(() => _v = (dx / width * widget.max).clamp(0, widget.max.toDouble()));

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, c.maxWidth),
        onHorizontalDragEnd: (_) => widget.onChangeEnd(_v.round()),
        onTapUp: (d) {
          _update(d.localPosition.dx, c.maxWidth);
          widget.onChangeEnd(_v.round());
        },
        child: Container(
          height: 28,
          decoration: BoxDecoration(color: s.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: math.max(28, c.maxWidth * _v / widget.max),
            decoration: BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              '${_v.round()}',
              style: TextStyle(color: s.onPrimary, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular gauge (consumables): ring with the percentage in the middle and the name below.
class Gauge extends StatelessWidget {
  final double fraction;
  final String label;
  final String detail;
  final VoidCallback? onTap;

  const Gauge({super.key, required this.fraction, required this.label, required this.detail, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme, t = Theme.of(context).textTheme;
    final color = fraction < 0.15 ? s.error : (fraction < 0.35 ? Colors.orange : s.primary);
    return Pressable(
      onTap: onTap,
      child: Column(
        children: [
          ProgressRing(
            value: fraction,
            size: 72,
            color: color,
            child: Text(
              '${(fraction * 100).round()}%',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: t.labelSmall?.copyWith(color: s.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Large tile button (dock actions).
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const ActionTile({super.key, required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(Tokens.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom bottom sheet (replaces the Material-looking showModalBottomSheet).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget Function(BuildContext, StateSetter) builder,
  String? action,
  VoidCallback? onAction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final s = Theme.of(ctx).colorScheme, t = Theme.of(ctx).textTheme;
        return Container(
          margin: const EdgeInsets.all(8),
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.of(ctx).viewPadding.bottom),
          decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: s.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (subtitle != null) Text(subtitle, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
              Flexible(child: SingleChildScrollView(child: builder(ctx, set))),
              if (action != null) ...[const SizedBox(height: 18), BigButton(label: action, onTap: onAction)],
            ],
          ),
        );
      },
    ),
  );
}

/// Full-width primary button.
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const BigButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [s.primary, Color.lerp(s.primary, s.tertiary, 0.45)!]),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [BoxShadow(color: s.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: s.onPrimary), const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(color: s.onPrimary, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom list row (queue, plan, history): a light card with rounded corners.
/// Takes the same parameter names as ListTile to make swapping easy.
class ItemRow extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  // Ignored: only kept for compatibility with older call sites.
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  const ItemRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme, t = Theme.of(context).textTheme;
    final dark = s.brightness == Brightness.dark;
    final row = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? s.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(Tokens.radiusSmall + 4),
        border: Border.all(color: s.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(color: s.primary),
              child: leading!,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: t.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
                  child: title,
                ),
                if (subtitle != null)
                  DefaultTextStyle(
                    style: t.bodySmall!.copyWith(color: s.onSurfaceVariant),
                    child: subtitle!,
                  ),
              ],
            ),
          ),
          if (trailing != null)
            IconTheme(
              data: IconThemeData(color: s.onSurfaceVariant),
              child: trailing!,
            ),
        ],
      ),
    );
    return onTap == null ? row : Pressable(onTap: onTap, child: row);
  }
}

/// Custom loading indicator: three pulsing dots.
class Dots extends StatefulWidget {
  const Dots({super.key});

  @override
  State<Dots> createState() => _DotsState();
}

class _DotsState extends State<Dots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l.loading,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: s.primary.withValues(
                    alpha: 0.25 + 0.75 * (0.5 + 0.5 * math.sin((_c.value - i / 3) * 2 * math.pi)),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom text field: filled rounded box, without Material's outline or floating label.
class Field extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const Field({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  State<Field> createState() => _FieldState();
}

class _FieldState extends State<Field> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: s.primary.withValues(alpha: widget.enabled ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: s.primary),
            const SizedBox(width: 12),
            Expanded(
              child: EditableText(
                controller: widget.controller,
                focusNode: _focus,
                readOnly: !widget.enabled,
                autofocus: widget.autofocus,
                keyboardType: widget.keyboardType,
                autofillHints: widget.autofillHints,
                onSubmitted: widget.onSubmitted,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: s.onSurface.withValues(alpha: widget.enabled ? 1 : 0.6),
                ),
                cursorColor: s.primary,
                backgroundCursorColor: s.outline,
                selectionColor: s.primary.withValues(alpha: 0.25),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: widget.controller,
              builder: (_, v, _) => v.text.isEmpty
                  ? Text(widget.hint, style: TextStyle(color: s.onSurfaceVariant.withValues(alpha: 0.7)))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom time picker: two wheels (hours, and minutes in steps of 5) in a bottom sheet.
Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial, {String? title}) {
  var h = initial.hour, m = (initial.minute ~/ 5) * 5;
  return showAppSheet<TimeOfDay>(
    context,
    title: title ?? context.l.time,
    builder: (ctx, set) {
      final s = Theme.of(ctx).colorScheme;
      Widget wheel(int count, int value, int step, ValueChanged<int> on) => SizedBox(
        width: 90,
        height: 180,
        child: ListWheelScrollView.useDelegate(
          controller: FixedExtentScrollController(initialItem: value ~/ step),
          itemExtent: 44,
          perspective: 0.004,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) => on(i * step),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (_, i) => Center(
              child: Text(
                (i * step).toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: s.onSurface),
              ),
            ),
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            wheel(24, h, 1, (v) => h = v),
            Text(
              ':',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: s.primary),
            ),
            wheel(12, m, 5, (v) => m = v),
          ],
        ),
      );
    },
    action: context.l.choose,
    onAction: () => Navigator.of(context).pop(TimeOfDay(hour: h, minute: m)),
  );
}
