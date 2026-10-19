import 'dart:async';

import 'package:flutter/material.dart';

import 'cloud/roborock_cloud.dart';
import 'l10n/strings.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'platform/background_service.dart';
import 'platform/notifier.dart';
import 'robot/robot_controller.dart';
import 'session_store.dart';
import 'ui/design/components.dart';
import 'ui/design/robot_icon.dart';
import 'ui/history_screen.dart';
import 'ui/login_screen.dart';
import 'ui/now_screen.dart';
import 'ui/plan_screen.dart';
import 'ui/robot_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  final notifier = Notifier(serviceEntry: backgroundServiceEntry);
  runApp(AspiraApp(store: await SessionStore.open(), notifier: notifier));
  // Permissions and channels can take a while (or wait for the user): they never delay the first frame.
  unawaited(notifier.init());
}

class AspiraApp extends StatefulWidget {
  final SessionStore store;
  final Notifier notifier;

  const AspiraApp({super.key, required this.store, required this.notifier});

  @override
  State<AspiraApp> createState() => _AspiraAppState();
}

class _AspiraAppState extends State<AspiraApp> with WidgetsBindingObserver {
  RobotController? _controller;

  /// Taking control back from the service (app reopened after being closed): no controller yet, but logged in.
  bool _claiming = false;
  Timer? _alive;
  late ThemeMode _themeMode = ThemeMode.values.byName((widget.store.readJson('theme') as String?) ?? 'system');

  void _setTheme(ThemeMode m) {
    setState(() => _themeMode = m);
    widget.store.writeJson('theme', m.name);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Heartbeat for the service: while it keeps coming, the app runs the queue (also in the background).
    _alive = Timer.periodic(const Duration(seconds: 3), (_) => widget.store.markUiAlive());
    final session = widget.store.session, device = widget.store.device;
    if (session != null && device != null) {
      _claiming = true;
      claimFromService(widget.store).whenComplete(() {
        if (!mounted) return;
        _claiming = false;
        // Reloaded from disk: the service may have advanced the queue while the app was closed.
        final s = widget.store.session, d = widget.store.device;
        if (s != null && d != null) _open(s, d);
        setState(() {});
      });
    }
  }

  /// Swiped away from recents: tell the service to take over now instead of waiting for the heartbeat to expire.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) unawaited(widget.store.markUiGone());
  }

  void _open(CloudSession session, CloudDevice device) {
    _controller?.dispose();
    _controller = RobotController(session, device, widget.store, widget.notifier)..start();
    setState(() {});
  }

  Future<void> _logout() async {
    await widget.store.clear();
    _controller?.dispose();
    await widget.notifier.stop();
    setState(() => _controller = null);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return MaterialApp(
      title: 'Roborock++',
      // English and Portuguese for now; the phone's language picks one, English otherwise.
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _themeMode,
      home: _claiming
          ? const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()))
          : controller == null
          ? LoginScreen(store: widget.store, onLoggedIn: _open)
          : HomeShell(
              key: ObjectKey(controller),
              controller: controller,
              onLogout: _logout,
              themeMode: _themeMode,
              onThemeChanged: _setTheme,
            ),
    );
  }

  /// A truly white light theme (Material 3 defaults to a tinted white).
  static ThemeData _theme(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4F5BD5), brightness: b);
    final light = b == Brightness.light;
    return ThemeData(
      colorScheme: light ? scheme.copyWith(surface: Colors.white) : scheme,
      scaffoldBackgroundColor: light ? Colors.white : null,
      cardTheme: CardThemeData(
        elevation: 0,
        color: light ? const Color(0xFFF4F5FA) : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(backgroundColor: light ? Colors.white : null, elevation: 0),
      appBarTheme: AppBarTheme(backgroundColor: light ? Colors.white : null, scrolledUnderElevation: 0),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alive?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

Widget _robotNavIcon(Color c) => RobotVacuumIcon(size: 22, color: c);

class HomeShell extends StatefulWidget {
  final RobotController controller;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const HomeShell({
    super.key,
    required this.controller,
    required this.onLogout,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pages = [
      NowScreen(controller: c),
      PlanScreen(controller: c, onQueued: () => setState(() => _tab = 0)),
      HistoryScreen(controller: c),
      RobotScreen(
        controller: c,
        onLogout: widget.onLogout,
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];
    return Scaffold(
      extendBody: true,
      // The bar floats: tabs with lists get bottom padding so nothing hides under it.
      body: IndexedStack(
        index: _tab,
        children: [
          pages.first,
          for (final p in pages.skip(1))
            SafeArea(
              bottom: false,
              child: Padding(padding: const EdgeInsets.only(bottom: 88), child: p),
            ),
        ],
      ),
      bottomNavigationBar: CapsuleNavBar(
        selected: _tab,
        onSelected: (i) => setState(() => _tab = i),
        items: [
          NavItem(Icons.play_circle_outline_rounded, context.l.tabNow),
          NavItem(Icons.checklist_rounded, context.l.tabPlan),
          NavItem(Icons.bar_chart_rounded, context.l.tabHistory),
          NavItem.custom(_robotNavIcon, context.l.tabRobot),
        ],
      ),
    );
  }
}
