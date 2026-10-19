import 'dart:io';
import 'dart:ui' as ui;

import 'package:aspira/map/map_geometry.dart';
import 'package:aspira/map/map_parser.dart';
import 'package:aspira/map/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws the real map on a phone-sized screen and saves build/map_preview_*.png for visual review.
void main() {
  // The real home map is private and not in the repository: without it these tests are skipped.
  if (!File('test/fixtures/map_a288.bin').existsSync()) {
    test('mapa real', () {}, skip: 'missing test/fixtures/map_a288.bin (private map, not in the repository)');
    return;
  }
  const names = {
    1: 'Quarto',
    2: 'Casa de banho',
    3: 'Quarto1',
    4: 'Quarto2',
    5: 'Sala de jantar',
    6: 'Casa de banho1',
    7: 'Kitchen',
    8: 'Quarto3',
  };

  setUpAll(() async {
    final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
    if (font.existsSync()) {
      await (FontLoader('Preview')..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())))).load();
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('preview ${brightness.name}', (tester) async {
      final map = MapParser.parse(File('test/fixtures/map_a288.bin').readAsBytesSync());
      final geometry = MapGeometry.from(map.grid!);
      expect(geometry.rooms, hasLength(8));

      tester.view.physicalSize = const Size(1080, 1500);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: brightness, fontFamily: 'Preview', colorSchemeSeed: Colors.indigo),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: MapView(map: map, geometry: geometry, roomNames: names, currentRoom: 7, doneRooms: const {5}),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.6);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/map_preview_${brightness.name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}
