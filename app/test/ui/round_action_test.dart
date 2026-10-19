import 'package:aspira/l10n/l10n.dart';
import 'package:aspira/ui/design/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int> tapsWhile(WidgetTester tester, {required bool pending, Locale locale = const Locale('en')}) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Center(
            child: RoundAction(icon: Icons.pause, label: 'Pause', pending: pending, onTap: () => taps++),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(RoundAction));
      await tester.pump(const Duration(milliseconds: 50));
    }
    return taps;
  }

  testWidgets('a button with a command in flight shows "Sending…" and ignores taps', (tester) async {
    expect(await tapsWhile(tester, pending: true), 0);
    expect(find.text('Sending…'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
  });

  testWidgets('the pending label follows the language', (tester) async {
    await tapsWhile(tester, pending: true, locale: const Locale('pt'));
    expect(find.text('A enviar…'), findsOneWidget);
  });

  testWidgets('an idle button takes taps and shows its name', (tester) async {
    expect(await tapsWhile(tester, pending: false), 3);
    expect(find.text('Pause'), findsOneWidget);
  });
}
