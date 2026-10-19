import 'package:flutter/material.dart';

import '../history/clean_record.dart';
import '../l10n/strings.dart';
import '../history/stats.dart';
import 'design/components.dart';
import 'design/kit.dart';

/// Cleaning time per day (last 14) or per week (last 8). Tapping a bar shows its details.
class ActivityChart extends StatefulWidget {
  final List<CleanRecord> history;

  const ActivityChart({super.key, required this.history});

  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  bool _weeks = false;
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme, t = Theme.of(context).textTheme;
    final buckets = activity(widget.history, DateTime.now(), count: _weeks ? 8 : 14, weeks: _weeks);
    final top = buckets.map((b) => b.seconds).fold(0, (a, b) => a > b ? a : b);
    final picked = _picked == null || _picked! >= buckets.length ? buckets.length - 1 : _picked!;
    final p = buckets[picked];
    final l = context.l;
    final weekdays = l.weekdaysNarrow.split(' ');
    String label(DateTime d) => _weeks ? l.weekOf(d) : l.shortDate(d);
    final when = label(p.start);
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.activity, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              PillChoice<bool>(
                options: {false: l.days14, true: l.weeks8},
                selected: _weeks,
                onChanged: (w) => setState(() {
                  _weeks = w;
                  _picked = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.count == 0
                ? '$when · ${l.noCleans}'
                : '$when · ${l.activityDetail(p.count, (p.seconds / 60).round(), p.areaM2.toStringAsFixed(0))}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, b) in buckets.indexed)
                  Expanded(
                    child: Pressable(
                      semanticLabel: _weeks ? l.weekOf(b.start) : l.shortDate(b.start),
                      onTap: () => setState(() => _picked = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: Tokens.fast,
                              height: top == 0 ? 3 : 3 + 92 * b.seconds / top,
                              decoration: BoxDecoration(
                                color: i == picked
                                    ? s.primary
                                    : s.primary.withValues(alpha: b.seconds == 0 ? 0.12 : 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _weeks ? '${b.start.day}' : weekdays[b.start.weekday - 1],
                              style: t.labelSmall?.copyWith(
                                fontWeight: i == picked ? FontWeight.w800 : FontWeight.w500,
                                color: i == picked ? s.primary : s.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
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
