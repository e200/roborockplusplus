import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Sizes and animations shared by all components.
abstract final class Tokens {
  static const radius = 24.0;
  static const radiusSmall = 14.0;
  static const gap = 12.0;
  static const fast = Duration(milliseconds: 180);
  static const curve = Curves.easeOutCubic;
}

/// Frosted glass panel: floats over the map without hiding it completely.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = Tokens.radius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: dark ? 0.72 : 0.82),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Progress ring around an icon (robot, battery).
class ProgressRing extends StatelessWidget {
  final double? value;
  final Widget child;
  final double size;
  final Color? color;

  const ProgressRing({super.key, required this.value, required this.child, this.size = 64, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value ?? 0),
        duration: const Duration(milliseconds: 600),
        curve: Tokens.curve,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, color ?? scheme.primary, scheme.primary.withValues(alpha: 0.14), value != null),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color, track;
  final bool show;

  _RingPainter(this.value, this.color, this.track, this.show);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3);
    canvas.drawCircle(rect.center, rect.width / 2, Paint()..color = track);
    if (!show) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.show != show;
}

/// Secondary action: round icon with a caption below.
class RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  /// Command in flight: shows a spinner and ignores further taps.
  final bool pending;

  const RoundAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = primary ? scheme.primary : scheme.primary.withValues(alpha: 0.10);
    final fg = primary ? scheme.onPrimary : scheme.primary;
    final size = primary ? 64.0 : 48.0;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: pending ? null : onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Tokens.fast,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: onTap == null ? scheme.onSurface.withValues(alpha: 0.06) : bg,
                  shape: BoxShape.circle,
                  boxShadow: primary
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: pending
                    ? Padding(
                        padding: EdgeInsets.all(primary ? 20 : 14),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                      )
                    : Icon(
                        icon,
                        color: onTap == null ? scheme.onSurface.withValues(alpha: 0.3) : fg,
                        size: primary ? 30 : 22,
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                pending ? context.l.sending : label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData? icon;
  final String label;

  /// Custom-drawn icon (e.g. the vacuum) instead of an IconData.
  final Widget Function(Color color)? custom;

  const NavItem(this.icon, this.label) : custom = null;

  const NavItem.custom(this.custom, this.label) : icon = null;
}

/// Capsule navigation bar floating over the content.
class CapsuleNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;

  const CapsuleNavBar({super.key, required this.items, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Glass(
        radius: 32,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  label: item.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(i),
                    child: AnimatedContainer(
                      duration: Tokens.fast,
                      curve: Tokens.curve,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: i == selected ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          item.custom?.call(i == selected ? scheme.onPrimary : scheme.onSurfaceVariant) ??
                              Icon(
                                item.icon,
                                size: 22,
                                color: i == selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                              ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: i == selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum LevelGlyph { bars, drops, count }

/// Level picker with custom drawings: growing bars (suction), drops (water), a number (passes).
class LevelPicker extends StatelessWidget {
  final String label;
  final Map<int, String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final LevelGlyph glyph;

  /// Option that turns the function off (e.g. no water); shows a dash instead of the drawing.
  final int? offValue;

  const LevelPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.glyph = LevelGlyph.bars,
    this.offValue,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme, scheme = Theme.of(context).colorScheme;
    final entries = options.entries.toList();
    final levels = entries.where((e) => e.key != offValue).length;
    var level = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Text(label, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(options[selected] ?? '', style: t.labelLarge?.copyWith(color: scheme.primary)),
            ],
          ),
        ),
        Row(
          children: [
            for (final e in entries)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final isOff = e.key == offValue;
                    final lvl = isOff ? 0 : ++level;
                    final on = e.key == selected;
                    return Semantics(
                      button: true,
                      selected: on,
                      label: '$label ${e.value}',
                      child: GestureDetector(
                        onTap: () => onChanged(e.key),
                        child: AnimatedContainer(
                          duration: Tokens.fast,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: on ? scheme.primary : scheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(Tokens.radiusSmall),
                          ),
                          child: Center(
                            child: _Glyph(
                              glyph: isOff ? null : glyph,
                              level: lvl,
                              of: levels,
                              color: on ? scheme.onPrimary : scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Glyph extends StatelessWidget {
  final LevelGlyph? glyph;
  final int level, of;
  final Color color;

  const _Glyph({required this.glyph, required this.level, required this.of, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (glyph) {
      case null:
        return Icon(Icons.block, size: 20, color: color);
      case LevelGlyph.count:
        return Text(
          '$level×',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
        );
      case LevelGlyph.drops:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < level; i++) Icon(Icons.water_drop, size: level > 3 ? 11 : 14, color: color)],
        );
      case LevelGlyph.bars:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 1; i <= of; i++)
              Container(
                width: 4,
                height: 6.0 + 18 * i / of,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: i <= level ? color : color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
    }
  }
}
