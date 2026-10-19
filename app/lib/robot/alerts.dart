import '../l10n/strings.dart';
import 'robot_status.dart';

/// Localized text for a robot error code (`error_code`).
String robotErrorText(L10n l, int code) => l.robotErrorText('c$code').replaceAll('c$code', '$code');

/// Localized text for a dock error code (`dock_error_status`).
String dockErrorText(L10n l, int code) => l.dockErrorText('c$code').replaceAll('c$code', '$code');

enum AlertKind { robotError, dockError, waterShortage }

class RobotAlert {
  final AlertKind kind;
  final int code;
  final String title;
  final String body;

  const RobotAlert(this.kind, this.code, this.title, this.body);

  /// Stable id per kind: a new notification of the same kind replaces the previous one.
  int get notificationId => 1000 + kind.index;
}

RobotAlert _robot(L10n l, int code) =>
    RobotAlert(AlertKind.robotError, code, l.alertRobotTitle, robotErrorText(l, code));

RobotAlert _dock(L10n l, int code) => RobotAlert(AlertKind.dockError, code, l.alertDockTitle, dockErrorText(l, code));

RobotAlert _water(L10n l) => RobotAlert(AlertKind.waterShortage, 0, l.alertWaterTitle, l.alertWaterBody);

/// Problems present right now (shown in the app, besides the notification).
List<RobotAlert> activeProblems(RobotStatus s, L10n l) => [
  if (s.errorCode != 0) _robot(l, s.errorCode),
  if (s.dockError != 0) _dock(l, s.dockError),
  // 38 already says the clean water tank is empty.
  if (s.waterShortage && s.dockError != 38) _water(l),
];

/// Compares consecutive readings and only alerts when something changes, not on every reading. The last state
/// seen is persisted ([toJson]/[AlertDetector.restore]) so handing over between the app and the background
/// service does not repeat alerts already sent.
class AlertDetector {
  ({int errorCode, int dockError, bool waterShortage})? _last;

  AlertDetector();

  AlertDetector.restore(Object? json) {
    if (json is Map) {
      _last = (
        errorCode: json['error'] as int? ?? 0,
        dockError: json['dock'] as int? ?? 0,
        waterShortage: json['water'] == true,
      );
    }
  }

  Object? toJson() {
    final l = _last;
    return l == null ? null : {'error': l.errorCode, 'dock': l.dockError, 'water': l.waterShortage};
  }

  List<RobotAlert> update(RobotStatus s, L10n l) {
    final prev = _last;
    _last = (errorCode: s.errorCode, dockError: s.dockError, waterShortage: s.waterShortage);
    return [
      if (s.errorCode != 0 && s.errorCode != prev?.errorCode) _robot(l, s.errorCode),
      if (s.dockError != 0 && s.dockError != prev?.dockError) _dock(l, s.dockError),
      if (s.waterShortage && prev?.waterShortage != true && s.dockError != 38) _water(l),
    ];
  }
}
