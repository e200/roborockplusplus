import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../queue/clean_job.dart';
import 'design/components.dart';
import 'design/kit.dart';

/// Suction in increasing order; "mop only" turns the vacuum off.
Map<int, String> fanOptions(L10n l) => {
  105: l.fanMopOnly,
  101: l.fanQuiet,
  102: l.fanBalanced,
  103: l.fanTurbo,
  104: l.fanMax,
  108: l.fanMaxPlus,
};

Map<int, String> waterOptions(L10n l) => {
  200: l.waterOff,
  225: l.waterLow,
  235: l.waterMedium,
  245: l.waterHigh,
  250: l.waterExtreme,
};

Map<int, String> mopRouteOptions(L10n l) => {304: l.routeFast, 300: l.routeStandard, 303: l.routeDeepPlus};

/// The official app's cleaning styles; [custom] shows the individual levels.
enum CleanStyle { smart, vacuum, vacuumAndMop, vacuumThenMop, mop, custom }

const _styleSettings = {
  CleanStyle.smart: CleanSettings.smart,
  CleanStyle.vacuum: CleanSettings.vacuumOnly,
  CleanStyle.vacuumAndMop: CleanSettings.vacuumAndMop,
  CleanStyle.vacuumThenMop: CleanSettings.vacuumThenMop,
  CleanStyle.mop: CleanSettings.mopOnly,
};

String styleLabel(L10n l, CleanStyle s) => switch (s) {
  CleanStyle.smart => l.styleSmart,
  CleanStyle.vacuum => l.styleVacuum,
  CleanStyle.vacuumAndMop => l.styleVacuumMop,
  CleanStyle.vacuumThenMop => l.styleVacuumThenMop,
  CleanStyle.mop => l.styleMop,
  CleanStyle.custom => l.styleCustom,
};

String settingsSummary(L10n l, CleanSettings s) {
  final times = s.repeat > 1 ? ' · ${s.repeat}×' : '';
  if (s.isSmart) return '${l.sumSmart}$times';
  if (s.twoPass) return '${l.sumVacuumThenMop}$times';
  final parts = <String>[
    if (s.fan == 105) l.sumMopOnly else l.sumVacuum(fanOptions(l)[s.fan]?.toLowerCase() ?? '${s.fan}'),
    if (s.water != 200) l.sumMop(waterOptions(l)[s.water]?.toLowerCase() ?? '${s.water}'),
    if (s.water != 200 && s.mopRoute != 300)
      l.sumRoute(mopRouteOptions(l)[s.mopRoute]?.toLowerCase() ?? '${s.mopRoute}'),
    if (s.repeat > 1) '${s.repeat}×',
  ];
  return parts.join(' · ');
}

/// Suction, water, mop route and passes picker.
/// [live]: during a clean the mop route and passes do not change the running task, so they are hidden.
class SettingsPicker extends StatelessWidget {
  final CleanSettings value;
  final ValueChanged<CleanSettings> onChanged;
  final bool live;

  const SettingsPicker({super.key, required this.value, required this.onChanged, this.live = false});

  @override
  Widget build(BuildContext context) {
    // Style: one tap instead of four choices. "Custom" shows the levels.
    final l = context.l;
    final style = _styleSettings.entries
        .firstWhere(
          (e) => e.value.copyWith(repeat: value.repeat) == value,
          orElse: () => const MapEntry(CleanStyle.custom, CleanSettings()),
        )
        .key;
    final custom = style == CleanStyle.custom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!live) ...[
          const SizedBox(height: 14),
          PillChoice<CleanStyle>(
            options: {for (final k in CleanStyle.values) k: styleLabel(l, k)},
            selected: style,
            onChanged: (k) => onChanged(
              k == CleanStyle.custom
                  ? const CleanSettings(fan: 103, water: 235).copyWith(repeat: value.repeat)
                  : _styleSettings[k]!.copyWith(repeat: value.repeat),
            ),
          ),
          if (value.isSmart)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(l.smartHint, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
        if (live || custom) ...[
          LevelPicker(
            label: l.suction,
            options: fanOptions(l),
            selected: value.fan,
            offValue: 105,
            onChanged: (v) => onChanged(value.copyWith(fan: v)),
          ),
          LevelPicker(
            label: l.mop,
            options: waterOptions(l),
            selected: value.water,
            offValue: 200,
            glyph: LevelGlyph.drops,
            onChanged: (v) => onChanged(value.copyWith(water: v)),
          ),
          if (!live && value.water != 200)
            LevelPicker(
              label: l.mopRoute,
              options: mopRouteOptions(l),
              selected: value.mopRoute,
              onChanged: (v) => onChanged(value.copyWith(mopRoute: v)),
            ),
        ],
        if (!live)
          LevelPicker(
            label: l.passes,
            options: {1: l.passOne, 2: l.passTwo, 3: l.passThree},
            selected: value.repeat,
            glyph: LevelGlyph.count,
            onChanged: (v) => onChanged(value.copyWith(repeat: v)),
          ),
      ],
    );
  }
}
