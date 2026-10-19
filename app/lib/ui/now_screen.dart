import 'package:flutter/material.dart';

import '../l10n/describe.dart';
import '../l10n/strings.dart';

import '../map/map_view.dart';
import '../queue/clean_job.dart';
import '../queue/queue_engine.dart';
import '../robot/robot_client.dart';
import '../robot/robot_commands.dart';
import '../robot/robot_controller.dart';
import '../robot/robot_status.dart';
import '../robot/alerts.dart';
import 'design/components.dart';
import 'design/kit.dart';
import 'design/robot_icon.dart';
import 'history_screen.dart';
import 'settings_picker.dart';

/// "Now" screen: what the robot is doing, the live map and what comes next.
class NowScreen extends StatefulWidget {
  final RobotController controller;

  const NowScreen({super.key, required this.controller});

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  RobotController get controller => widget.controller;

  /// Drawing extra zones: one-finger panning on the map is disabled.
  bool _drawing = false;
  final _draft = <CleanZone>[];

  Future<void> _confirmZones() async {
    var settings = CleanSettings.vacuumOnly;
    final busy = controller.status?.busy == true;
    final ok = await showAppSheet<bool>(
      context,
      title: context.l.cleanZonesTitle(_draft.length),
      subtitle: busy ? context.l.zonesQueueNote : null,
      builder: (ctx, set) => SettingsPicker(value: settings, onChanged: (v) => set(() => settings = v)),
      action: busy ? context.l.addToQueue : context.l.clean,
      onAction: () => Navigator.of(context).pop(true),
    );
    if (ok != true) return;
    controller.enqueueZones(List.of(_draft), settings);
    setState(() {
      _draft.clear();
      _drawing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final map = c.map, geometry = c.geometry, status = c.status;
        final finished = c.justFinished;
        final scheme = Theme.of(context).colorScheme;
        final hasSheetContent =
            finished != null || c.queue.pending.isNotEmpty || c.queue.current != null || c.queue.pauseReason != null;
        return Stack(
          children: [
            // The map fills the screen; everything else floats on top.
            Positioned.fill(
              child: map == null || geometry == null
                  ? const Center(child: Dots())
                  : MapView(
                      map: map,
                      geometry: geometry,
                      roomNames: c.roomNames,
                      currentRoom: status?.busy == true ? (status!.currentRoom ?? map.robotRoom) : null,
                      active: status?.busy == true,
                      // Zones drawn now + those already queued, to show what comes next.
                      zones: [
                        ..._draft,
                        for (final j in [?c.queue.current, ...c.queue.pending]) ...j.zones,
                      ],
                      onZoneDrawn: _drawing ? (z) => setState(() => _draft.add(z)) : null,
                    ),
            ),
            if (_drawing)
              Positioned(
                left: 12,
                right: 12,
                bottom: 100,
                child: Glass(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _draft.isEmpty
                              ? context.l.drawZoneHint
                              : context.l.zonesArea(
                                  _draft.length,
                                  _draft.fold(0.0, (a, z) => a + z.areaM2).toStringAsFixed(1),
                                ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Pressable(
                        onTap: () => setState(() {
                          _draft.clear();
                          _drawing = false;
                        }),
                        child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.close_rounded)),
                      ),
                      if (_draft.isNotEmpty) ...[
                        Pressable(
                          onTap: () => setState(_draft.removeLast),
                          child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.undo_rounded)),
                        ),
                        SizedBox(
                          width: 120,
                          child: BigButton(label: context.l.next, onTap: _confirmZones),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (!_drawing && map != null)
              Positioned(
                right: 16,
                bottom: hasSheetContent ? MediaQuery.of(context).size.height * 0.28 + 12 : 104,
                child: Pressable(
                  onTap: () => setState(() => _drawing = true),
                  semanticLabel: context.l.addZone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.highlight_alt_rounded, color: Theme.of(context).colorScheme.onPrimary),
                        const SizedBox(width: 6),
                        Text(
                          context.l.zone,
                          style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Column(
                children: [
                  _StatusCard(controller: c),
                  if (c.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(errorText(context.l, c.error!), style: TextStyle(color: scheme.error), maxLines: 2),
                    ),
                ],
              ),
            ),
            if (hasSheetContent && !_drawing)
              DraggableScrollableSheet(
                initialChildSize: 0.28,
                minChildSize: 0.12,
                maxChildSize: 0.75,
                builder: (context, scroll) => Material(
                  elevation: 8,
                  color: scheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (finished != null)
                        RecordSummaryCard(
                          record: finished,
                          controller: c,
                          title: context.l.cleanFinished,
                          onClose: c.dismissFinished,
                        ),
                      _UpNext(controller: c),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final RobotController controller;

  const _StatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme, scheme = Theme.of(context).colorScheme;
    final c = controller, s = c.status;
    if (s == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Glass(child: Row(children: [const Dots(), const SizedBox(width: 16), Text(context.l.connecting)])),
        ),
      );
    }
    final room = s.currentRoom == null ? null : c.roomName(s.currentRoom!);
    final l = context.l;
    final title = s.state == 18 && room != null ? room : s.stateLabel(l);
    final est = c.estimate;
    final error = s.errorCode != 0;
    final paused = s.state == 10;
    final details = [
      if (s.state == 18 && room != null) l.cleaning,
      if (est != null) l.minutesLeft((est.remainingSeconds / 60).ceil()),
      if (s.busy) l.suctionLevel(s.fanLabel(l)),
      if (s.busy && (s.activeWaterMode ?? s.waterMode) != 200) l.waterLevelLine(s.waterLabel(l)),
      if (!s.busy) l.batteryPercent(s.battery),
    ].join(' · ');
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Glass(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            children: [
              Row(
                children: [
                  ProgressRing(
                    value: s.busy ? (est?.percent ?? 0) / 100 : s.battery / 100,
                    color: error ? scheme.error : null,
                    child: error
                        ? Icon(Icons.warning_amber_rounded, color: scheme.error)
                        : RobotVacuumIcon(size: 28, color: scheme.primary, charging: s.docked && !s.busy),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.client.device.name.toUpperCase(),
                          style: t.labelSmall?.copyWith(letterSpacing: 1.2, color: scheme.onSurfaceVariant),
                        ),
                        Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          error ? robotErrorText(l, s.errorCode) : details,
                          style: t.bodySmall?.copyWith(color: error ? scheme.error : null),
                        ),
                      ],
                    ),
                  ),
                  _Bell(controller: c),
                  const SizedBox(width: 6),
                  _LinkIcon(c.link),
                ],
              ),
              // Active problems (dock, water, errors) stay visible while they last.
              for (final p in c.problems.where((p) => p.kind != AlertKind.robotError))
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.body,
                          style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!s.busy)
                    // While the job is starting (the robot is not "busy" yet) the button shows as pending.
                    RoundAction(
                      primary: true,
                      icon: Icons.play_arrow_rounded,
                      label: l.clean,
                      pending: c.queue.current != null,
                      onTap: () => _confirmWholeHome(context),
                    ),
                  if (s.busy && !paused)
                    RoundAction(
                      primary: true,
                      icon: Icons.pause_rounded,
                      label: l.pause,
                      pending: c.isPending('pause'),
                      onTap: () => c.act((r) => r.pause(), key: 'pause'),
                    ),
                  if (paused)
                    RoundAction(
                      primary: true,
                      icon: Icons.play_arrow_rounded,
                      label: l.resume,
                      pending: c.isPending('resume'),
                      onTap: () => c.act((r) => r.resume(), key: 'resume'),
                    ),
                  if (s.busy)
                    RoundAction(icon: Icons.tune_rounded, label: l.adjust, onTap: () => _settingsSheet(context, s)),
                  RoundAction(
                    icon: Icons.home_rounded,
                    label: l.dock,
                    pending: c.isPending('dock'),
                    onTap: s.docked ? null : () => c.act((r) => r.dock(), key: 'dock'),
                  ),
                  RoundAction(
                    icon: Icons.record_voice_over_rounded,
                    label: l.findMe,
                    pending: c.isPending('find'),
                    onTap: () => c.act((r) => r.findMe(), key: 'find'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmWholeHome(BuildContext context) async {
    var settings = const CleanSettings();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => _Sheet(
          title: context.l.cleanWholeHome,
          action: context.l.addToQueueLong,
          onAction: () => Navigator.pop(ctx, true),
          child: SettingsPicker(value: settings, onChanged: (v) => set(() => settings = v)),
        ),
      ),
    );
    if (ok == true) controller.enqueueWholeHome(settings);
  }

  /// Changes suction and water of the running clean without cancelling it (the firmware applies them right away).
  Future<void> _settingsSheet(BuildContext context, RobotStatus s) async {
    var settings = CleanSettings(fan: s.activeFanPower ?? s.fanPower, water: s.activeWaterMode ?? s.waterMode);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => _Sheet(
          title: context.l.adjustRunning,
          subtitle: context.l.adjustRunningSub,
          child: SettingsPicker(
            live: true,
            value: settings,
            onChanged: (v) {
              final old = settings;
              set(() => settings = v);
              if (v.fan != old.fan) controller.act((r) => r.setFan(v.fan));
              if (v.water != old.water) controller.act((r) => r.setWater(v.water));
            },
          ),
        ),
      ),
    );
  }
}

class _UpNext extends StatelessWidget {
  final RobotController controller;

  const _UpNext({required this.controller});

  @override
  Widget build(BuildContext context) {
    final q = controller.queue, t = Theme.of(context).textTheme, scheme = Theme.of(context).colorScheme;
    final current = q.current;
    if (q.pending.isEmpty && current == null && q.state != QueueState.paused) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(context.l.upNextTitle, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (q.state == QueueState.paused)
                Pressable(
                  onTap: q.resume,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 18, color: scheme.onPrimary),
                        const SizedBox(width: 4),
                        Text(
                          context.l.resumeQueue,
                          style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (q.pauseReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(pauseText(context.l, q.pauseReason!), style: t.bodySmall?.copyWith(color: scheme.error)),
            ),
          if (current != null)
            ItemRow(
              leading: const RobotVacuumIcon(size: 24),
              title: Text(context.l.nowJob(_jobTitle(current))),
              subtitle: Text(settingsSummary(context.l, current.settings)),
              trailing: Pressable(
                semanticLabel: q.pending.isEmpty ? context.l.cancel : context.l.skipToNext,
                onTap: controller.isPending('skip') ? null : controller.skipCurrent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        q.pending.isEmpty ? Icons.stop_rounded : Icons.skip_next_rounded,
                        size: 18,
                        color: scheme.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.isPending('skip')
                            ? context.l.stopping
                            : (q.pending.isEmpty ? context.l.cancel : context.l.skip),
                        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Flexible(
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: q.reorder,
              children: [
                for (final (i, job) in q.pending.indexed)
                  ItemRow(
                    key: ValueKey(job.id),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                    title: Text(_jobTitle(job)),
                    subtitle: Text(settingsSummary(context.l, job.settings)),
                    trailing: IconButton(
                      tooltip: context.l.removeFromQueue,
                      icon: const Icon(Icons.close),
                      onPressed: () => q.remove(job.id),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _jobTitle(CleanJob j) => controller.jobTitle(j);
}

/// Bell with the number of active problems; opens the notification centre.
class _Bell extends StatelessWidget {
  final RobotController controller;

  const _Bell({required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final n = controller.problems.length;
    return Pressable(
      semanticLabel: context.l.notifications,
      onTap: () => _open(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, color: s.onSurfaceVariant),
          if (n > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: s.error, shape: BoxShape.circle),
                child: Text(
                  '$n',
                  style: TextStyle(color: s.onError, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    final c = controller;
    String when(DateTime d) {
      final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      final today = DateTime.now();
      return d.year == today.year && d.month == today.month && d.day == today.day ? hm : '${d.day}/${d.month} $hm';
    }

    showAppSheet<void>(
      context,
      title: context.l.notifications,
      builder: (ctx, _) {
        final s = Theme.of(ctx).colorScheme, t = Theme.of(ctx).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (c.problems.isNotEmpty) ...[
              Text(context.l.now, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              for (final p in c.problems)
                ItemRow(
                  leading: Icon(Icons.warning_amber_rounded, color: s.error),
                  title: Text(p.title),
                  subtitle: Text(p.body),
                ),
              const SizedBox(height: 12),
            ],
            Text(context.l.recent, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (c.alertLog.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(context.l.noAlertsYet, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
              ),
            for (final a in c.alertLog.take(30))
              ItemRow(
                leading: const Icon(Icons.notifications_rounded),
                title: Text(a.title),
                subtitle: Text(a.body),
                trailing: Text(when(a.at), style: t.labelSmall),
              ),
          ],
        );
      },
    );
  }
}

class _LinkIcon extends StatelessWidget {
  final LinkState link;

  const _LinkIcon(this.link);

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (link) {
      LinkState.local => (Icons.wifi, context.l.linkLocal),
      LinkState.cloud => (Icons.cloud_outlined, context.l.linkCloud),
      LinkState.offline => (Icons.cloud_off, context.l.linkOffline),
    };
    return Tooltip(message: label, child: Icon(icon, size: 20));
  }
}

/// Bottom sheet with title, content and an optional action.
class _Sheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  const _Sheet({required this.title, this.subtitle, required this.child, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) Text(subtitle!),
          child,
          if (action != null) ...[const SizedBox(height: 20), BigButton(label: action!, onTap: onAction)],
        ],
      ),
    ),
  );
}
