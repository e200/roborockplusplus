import 'package:flutter/material.dart';

import '../l10n/describe.dart';
import '../l10n/strings.dart';

import 'design/kit.dart';
import 'record_map_screen.dart';

import '../history/clean_record.dart';
import 'activity_chart.dart';
import '../robot/robot_controller.dart';

String _duration(L10n l, int seconds) {
  final m = (seconds / 60).round();
  return m < 60 ? l.durationMin(m) : l.durationHourMin(m ~/ 60, m % 60);
}

String _date(L10n l, DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (day == today) return l.todayAt(hm);
  if (day == today.subtract(const Duration(days: 1))) return l.yesterdayAt(hm);
  return l.dateAt(d, hm);
}

/// History, totals and per-room breakdown.
class HistoryScreen extends StatelessWidget {
  final RobotController controller;

  const HistoryScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller, t = Theme.of(context).textTheme;
        final h = c.history;
        final week = h.where((r) => DateTime.now().difference(r.startedAt).inDays < 7).toList();
        final rooms = _roomStats(h);
        return PageBackground(
          child: RefreshIndicator(
            onRefresh: c.syncHistory,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                PageHeader(title: context.l.history, subtitle: context.l.historySub),
                Row(
                  children: [
                    _Stat(label: context.l.last7Days, value: '${week.length}', unit: context.l.cleansUnit),
                    _Stat(
                      label: context.l.timeLabel,
                      value: _duration(context.l, week.fold(0, (a, r) => a + r.durationSeconds)),
                      unit: context.l.in7Days,
                    ),
                    _Stat(
                      label: context.l.areaLabel,
                      value: week.fold(0.0, (a, r) => a + r.areaM2).toStringAsFixed(0),
                      unit: context.l.m2In7Days,
                    ),
                  ],
                ),
                if (c.totals != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l.allTime(
                        c.totals!.count,
                        (c.totals!.seconds / 3600).round(),
                        (c.totals!.areaMm2 / 1e6).round(),
                      ),
                      style: t.bodySmall,
                    ),
                  ),
                if (h.isNotEmpty) ...[const SizedBox(height: 16), ActivityChart(history: h)],
                if (rooms.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(context.l.perRoom, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(context.l.perRoomSub, style: t.bodySmall),
                  const SizedBox(height: 8),
                  for (final e in rooms.entries)
                    ItemRow(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.roomName(e.key)),
                      subtitle: Text(
                        context.l.roomStats(e.value.count, _duration(context.l, e.value.seconds ~/ e.value.count)),
                      ),
                      trailing: Text(_date(context.l, e.value.last)),
                    ),
                ],
                const SizedBox(height: 20),
                Text(context.l.cleans, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (h.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(context.l.noRecordsYet)),
                  ),
                for (final r in h)
                  ItemRow(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      r.complete ? Icons.check_circle_outline : Icons.error_outline,
                      color: r.complete ? null : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(r.rooms.isEmpty ? _date(context.l, r.startedAt) : r.rooms.map(c.roomName).join(' + ')),
                    subtitle: Text(
                      [
                        if (r.rooms.isNotEmpty) _date(context.l, r.startedAt),
                        _duration(context.l, r.durationSeconds),
                        '${r.areaM2.toStringAsFixed(1)} m²',
                        sourceText(context.l, r.source),
                        if (!r.complete) outcomeText(context.l, r.outcome),
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecordMapScreen(record: r, controller: c),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Map<int, ({int count, int seconds, DateTime last})> _roomStats(List<CleanRecord> h) {
    final out = <int, ({int count, int seconds, DateTime last})>{};
    for (final r in h) {
      for (final e in r.roomSeconds.entries) {
        final prev = out[e.key];
        out[e.key] = (
          count: (prev?.count ?? 0) + 1,
          seconds: (prev?.seconds ?? 0) + e.value,
          last: prev == null || r.startedAt.isAfter(prev.last) ? r.startedAt : prev.last,
        );
      }
    }
    return out;
  }
}

class _Stat extends StatelessWidget {
  final String label, value, unit;

  const _Stat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary.withValues(alpha: 0.16), scheme.primary.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.labelSmall),
              Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(unit, style: t.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary of one clean: what was done, how long it took and how it compares with the usual.
class RecordSummaryCard extends StatelessWidget {
  final CleanRecord record;
  final RobotController controller;
  final String? title;
  final VoidCallback? onClose;

  const RecordSummaryCard({super.key, required this.record, required this.controller, this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    final r = record, c = controller, t = Theme.of(context).textTheme;
    final similar = c.history
        .where((o) => o.begin != r.begin && o.complete && r.rooms.isNotEmpty && _sameRooms(o.rooms, r.rooms))
        .toList();
    final avg = similar.isEmpty ? null : similar.fold(0, (a, o) => a + o.durationSeconds) ~/ similar.length;
    final diffMin = avg == null ? null : ((r.durationSeconds - avg) / 60).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? _date(context.l, r.startedAt),
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (onClose != null) IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            if (r.rooms.isNotEmpty) Text(r.rooms.map(c.roomName).join(' + ')),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('⏱ ${_duration(context.l, r.durationSeconds)}'),
                Text('📐 ${r.areaM2.toStringAsFixed(1)} m²'),
                if (r.washCount > 0) Text('🧽 ${context.l.washes(r.washCount)}'),
                if (r.avoidCount > 0) Text('🚧 ${context.l.obstaclesAvoided(r.avoidCount)}'),
                Text('${r.complete ? '✅' : '⚠️'} ${outcomeText(context.l, r.outcome)}'),
              ],
            ),
            if (diffMin != null && diffMin != 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  diffMin < 0 ? context.l.fasterThanAvg(diffMin.abs()) : context.l.slowerThanAvg(diffMin),
                  style: t.bodySmall,
                ),
              ),
            if (r.roomSeconds.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  r.roomSeconds.entries.map((e) => '${c.roomName(e.key)} ${_duration(context.l, e.value)}').join(' · '),
                  style: t.bodySmall,
                ),
              ),
            if (r.hasOmission)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(context.l.omissionNote, style: t.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  static bool _sameRooms(List<int> a, List<int> b) => a.length == b.length && a.toSet().containsAll(b);
}
