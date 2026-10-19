import 'package:flutter/material.dart';

import '../history/clean_record.dart';
import '../l10n/strings.dart';
import '../map/map_geometry.dart';
import '../map/map_parser.dart';
import '../map/map_view.dart';
import '../map/robot_map.dart';
import '../robot/robot_controller.dart';
import 'design/kit.dart';
import 'history_screen.dart';

/// One clean from history: the map at that moment (rooms, path and objects) and the summary.
class RecordMapScreen extends StatefulWidget {
  final CleanRecord record;
  final RobotController controller;

  const RecordMapScreen({super.key, required this.record, required this.controller});

  @override
  State<RecordMapScreen> createState() => _RecordMapScreenState();
}

class _RecordMapScreenState extends State<RecordMapScreen> {
  RobotMap? _map;
  MapGeometry? _geometry;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final map = MapParser.parse(await widget.controller.recordMap(widget.record.begin));
      if (!mounted) return;
      setState(() {
        _map = map;
        _geometry = map.grid == null ? null : MapGeometry.from(map.grid!);
      });
    } on Exception catch (e) {
      // The robot only keeps the most recent cleans' maps; those the app followed are stored on the phone.
      if (mounted) {
        setState(() => _error = context.l.recordMapGone);
      }
      debugPrint('Record map ${widget.record.begin}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = _map, geometry = _geometry, s = Theme.of(context).colorScheme;
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(title: context.l.cleanGeneric, leading: const BackPill()),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, style: TextStyle(color: s.error)),
                        ),
                      )
                    : map == null || geometry == null
                    ? const Center(child: Dots())
                    : MapView(
                        map: map,
                        geometry: geometry,
                        roomNames: widget.controller.roomNames,
                        roomTags: widget.controller.roomTags,
                        showRobot: false,
                        highlightPath: true,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RecordSummaryCard(record: widget.record, controller: widget.controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
