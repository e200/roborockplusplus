import 'package:flutter/material.dart';

import '../l10n/describe.dart';
import '../l10n/strings.dart';

import '../protocol/rpc.dart';
import '../robot/robot_commands.dart';
import '../robot/robot_controller.dart';
import '../robot/robot_settings.dart';
import 'design/kit.dart';
import 'map_edit_screen.dart';

/// Official product photos per model (served by Roborock).
const _productImages = {'roborock.vacuum.a288': 'https://files.roborock.com/iot/product/jbv8whZVTiz3Kk8QWGPXf.png'};

/// Consumable lifetimes (hours), as in the official app.
const _consumables = [
  ('main_brush_work_time', 300),
  ('side_brush_work_time', 200),
  ('filter_work_time', 150),
  ('sensor_dirty_time', 30),
];

String _consumableName(L10n l, String key) => switch (key) {
  'main_brush_work_time' => l.consMainBrush,
  'side_brush_work_time' => l.consSideBrush,
  'filter_work_time' => l.consFilter,
  _ => l.consSensors,
};

const _sectionColors = {
  SettingSection.carpets: Color(0xFFB07A4F),
  SettingSection.dock: Color(0xFF4F8BD5),
  SettingSection.cleaning: Color(0xFF3FA37A),
  SettingSection.robot: Color(0xFFE0A100),
};

const _settingIcons = {
  'carpet_mode': Icons.texture_rounded,
  'carpet_boost': Icons.speed_rounded,
  'carpet_deep': Icons.layers_rounded,
  'auto_empty': Icons.auto_delete_rounded,
  'empty_mode': Icons.air_rounded,
  'dryer': Icons.dry_rounded,
  'wash_mode': Icons.local_laundry_service_rounded,
  'wash_interval': Icons.timer_outlined,
  'corner_mop': Icons.rounded_corner_rounded,
  'furniture': Icons.chair_rounded,
  'led': Icons.lightbulb_outline_rounded,
};

/// Robot: control centre with everything in view (dock, consumables, settings, do not disturb, appearance).
class RobotScreen extends StatefulWidget {
  final RobotController controller;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const RobotScreen({
    super.key,
    required this.controller,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  final _raw = <String, Object?>{};
  final _values = <String, int>{};
  DndSchedule? _dnd;
  int? _volume;
  bool? _childLock;
  bool _loading = false, _loaded = false;
  int _attempts = 0;

  /// Reads with one retry: right after connecting, some requests get lost.
  /// Only "unsupported" hides a setting for good.
  Future<T?> _read<T>(Future<T> Function() f) async {
    for (var i = 0; i < 2; i++) {
      try {
        return await f();
      } on UnsupportedCommand {
        return null;
      } on Exception catch (e) {
        debugPrint('Roborock++: read failed: $e');
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
    }
    return null;
  }

  /// The tab is built at startup, before there is a connection: read everything once the robot answers.
  Future<void> _load() async {
    if (_loading || _loaded || widget.controller.status == null || _attempts >= 3) return;
    _loading = true;
    _attempts++;
    final c = widget.controller.client;
    final settings = robotSettings(context.l);
    for (final s in settings.where((s) => !_values.containsKey(s.id))) {
      final raw = await _read(() => c.call(s.readMethod));
      final v = raw == null ? null : s.read(raw);
      if (v != null) {
        _raw[s.id] = raw;
        _values[s.id] = v;
      }
      if (mounted) setState(() {});
    }
    _dnd ??= await _read<DndSchedule?>(() => DndSchedule.read(c));
    _volume ??= await _read(c.volume);
    _childLock ??= await _read(c.childLock);
    _loading = false;
    _loaded = _values.length == settings.length || _attempts >= 3;
    if (mounted) setState(() {});
  }

  Future<void> _set(RobotSetting s, int v) async {
    final old = _values[s.id];
    setState(() => _values[s.id] = v);
    final cmd = s.write(v, _raw[s.id]);
    if (!await widget.controller.act((c) => c.call(cmd.method, cmd.params), key: 'set_${s.id}') && mounted) {
      setState(() => old == null ? _values.remove(s.id) : _values[s.id] = old);
    }
  }

  Future<void> _setDnd(DndSchedule d) async {
    final old = _dnd;
    setState(() => _dnd = d);
    if (!await widget.controller.act(d.write) && mounted) setState(() => _dnd = old);
  }

  Future<void> _pickTime(bool start) async {
    final d = _dnd!;
    final picked = await pickTime(
      context,
      TimeOfDay(hour: start ? d.startHour : d.endHour, minute: start ? d.startMinute : d.endMinute),
      title: start ? context.l.startsAt : context.l.endsAt,
    );
    if (picked == null) return;
    await _setDnd(
      start
          ? DndSchedule(d.enabled, picked.hour, picked.minute, d.endHour, d.endMinute)
          : DndSchedule(d.enabled, d.startHour, d.startMinute, picked.hour, picked.minute),
    );
  }

  Future<void> _confirmReset(String key, String name) async {
    final ok = await showAppSheet<bool>(
      context,
      title: context.l.resetPart(name),
      subtitle: context.l.resetPartSub,
      builder: (_, _) => const SizedBox(height: 4),
      action: context.l.reset,
      onAction: () => Navigator.of(context).pop(true),
    );
    if (ok == true) {
      await widget.controller.act((r) => r.resetConsumable(key));
      await widget.controller.refreshConsumables();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        if (!_loaded && !_loading) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
        final t = Theme.of(context).textTheme, s = Theme.of(context).colorScheme;
        final st = c.status, cons = c.consumables;
        final busy = st?.busy == true;
        final l = context.l;
        final sections = <SettingSection, List<RobotSetting>>{};
        for (final r in robotSettings(l).where((r) => _values.containsKey(r.id))) {
          sections.putIfAbsent(r.section, () => []).add(r);
        }
        String hm(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        final image = _productImages[c.client.device.productId] ?? _productImages['roborock.vacuum.a288'];

        return PageBackground(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // Header with the robot's photo.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.client.device.name, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            st == null ? l.connectingShort : l.stateBattery(st.stateLabel(l), st.battery),
                            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (image != null)
                      Image.network(
                        image,
                        width: 120,
                        height: 120,
                        errorBuilder: (_, _, _) => const SizedBox(width: 120),
                      ),
                  ],
                ),
              ),
              SectionTitle(l.dock),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ActionTile(
                      icon: Icons.delete_outline_rounded,
                      label: l.emptyBin,
                      color: const Color(0xFF4F8BD5),
                      onTap: busy || c.isPending('dust') ? null : () => c.act((r) => r.collectDust(), key: 'dust'),
                    ),
                    const SizedBox(width: 12),
                    ActionTile(
                      icon: Icons.local_laundry_service_rounded,
                      label: l.washMop,
                      color: const Color(0xFF3FA37A),
                      onTap: busy || c.isPending('wash') ? null : () => c.act((r) => r.washMop(), key: 'wash'),
                    ),
                  ],
                ),
              ),
              SectionTitle(l.map),
              Group(
                children: [
                  Row2(
                    icon: Icons.edit_location_alt_rounded,
                    color: const Color(0xFFD64F4F),
                    title: l.editMap,
                    subtitle: l.editMapSub,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: c.map == null
                        ? null
                        : () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute<void>(builder: (_) => MapEditScreen(controller: c))),
                  ),
                ],
              ),
              SectionTitle(l.maintenance),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: cons == null
                    ? const Center(
                        child: Padding(padding: EdgeInsets.all(16), child: Dots()),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (key, hours) in _consumables)
                            if (cons[key] != null)
                              Builder(
                                builder: (context) {
                                  final left = (hours - cons[key]! / 3600).clamp(0, hours.toDouble());
                                  final name = _consumableName(l, key);
                                  return Gauge(
                                    fraction: left / hours,
                                    label: name,
                                    detail: left < 1 ? l.cleanNowShort : l.hours(left.round()),
                                    onTap: () => _confirmReset(key, name.replaceAll('\n', ' ').toLowerCase()),
                                  );
                                },
                              ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(l.gaugeHint, style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
              ),
              if (_values.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Dots()),
                ),
              for (final MapEntry(key: section, value: items) in sections.entries) ...[
                SectionTitle(sectionLabel(l, section)),
                Group(
                  children: [
                    for (final r in items)
                      Row2(
                        icon: _settingIcons[r.id] ?? Icons.tune_rounded,
                        color: _sectionColors[section] ?? s.primary,
                        title: r.title,
                        subtitle: r.subtitle,
                        trailing: r.isSwitch
                            ? Toggle(value: _values[r.id] == 1, onChanged: (on) => _set(r, on ? 1 : 0))
                            : null,
                        below: r.isSwitch
                            ? null
                            : PillChoice<int>(
                                options: {
                                  ...r.options!,
                                  if (!r.options!.containsKey(_values[r.id]))
                                    _values[r.id]!: l.currentValue(_values[r.id]!),
                                },
                                selected: _values[r.id],
                                onChanged: (v) => _set(r, v),
                              ),
                      ),
                  ],
                ),
              ],
              if (_dnd != null) ...[
                SectionTitle(l.doNotDisturb),
                Group(
                  children: [
                    Row2(
                      icon: Icons.bedtime_rounded,
                      color: const Color(0xFF7C5CD6),
                      title: l.quietAtNight,
                      subtitle: l.quietAtNightSub,
                      trailing: Toggle(
                        value: _dnd!.enabled,
                        onChanged: (on) => _setDnd(
                          DndSchedule(on, _dnd!.startHour, _dnd!.startMinute, _dnd!.endHour, _dnd!.endMinute),
                        ),
                      ),
                      below: !_dnd!.enabled
                          ? null
                          : Row(
                              children: [
                                _TimeChip(
                                  label: l.from,
                                  time: hm(_dnd!.startHour, _dnd!.startMinute),
                                  onTap: () => _pickTime(true),
                                ),
                                const SizedBox(width: 10),
                                _TimeChip(
                                  label: l.to,
                                  time: hm(_dnd!.endHour, _dnd!.endMinute),
                                  onTap: () => _pickTime(false),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
              if (_volume != null || _childLock != null) ...[
                SectionTitle(l.soundSafety),
                Group(
                  children: [
                    if (_volume != null)
                      Row2(
                        icon: Icons.record_voice_over_rounded,
                        color: const Color(0xFFE0703C),
                        title: l.voiceVolume,
                        below: LevelBar(
                          value: _volume!,
                          onChangeEnd: (v) {
                            setState(() => _volume = v);
                            c.act((r) => r.setVolume(v));
                          },
                        ),
                      ),
                    if (_childLock != null)
                      Row2(
                        icon: Icons.child_care_rounded,
                        color: const Color(0xFFD64F7A),
                        title: l.childLock,
                        subtitle: l.childLockSub,
                        trailing: Toggle(
                          value: _childLock!,
                          onChanged: (v) async {
                            if (await c.act((r) => r.setChildLock(v))) setState(() => _childLock = v);
                          },
                        ),
                      ),
                  ],
                ),
              ],
              SectionTitle(l.appearance),
              Group(
                children: [
                  Row2(
                    icon: Icons.palette_rounded,
                    color: s.primary,
                    title: l.theme,
                    below: PillChoice<ThemeMode>(
                      options: {
                        ThemeMode.system: l.themeSystem,
                        ThemeMode.light: l.themeLight,
                        ThemeMode.dark: l.themeDark,
                      },
                      selected: widget.themeMode,
                      onChanged: widget.onThemeChanged,
                    ),
                  ),
                ],
              ),
              if (c.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Text(errorText(l, c.error!), style: TextStyle(color: s.error)),
                ),
              const SizedBox(height: 24),
              Center(
                child: Pressable(
                  onTap: widget.onLogout,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l.logOut,
                      style: TextStyle(color: s.error, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label, time;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: s.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
        child: RichText(
          text: TextSpan(
            style: TextStyle(color: s.onSurface),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                text: time,
                style: TextStyle(fontWeight: FontWeight.w800, color: s.primary, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
