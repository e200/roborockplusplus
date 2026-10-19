import '../cloud/roborock_cloud.dart';
import '../history/clean_record.dart';
import '../protocol/rpc.dart';
import '../queue/queue_engine.dart';
import '../robot/alerts.dart';
import 'l10n.dart';

/// User-facing text for an error from the robot or the cloud. Unknown errors get a generic line; their English
/// detail stays in the logs.
String errorText(L10n l, Object e) => switch (e) {
  RobotException(kind: RobotErrorKind.noLink || RobotErrorKind.closed || RobotErrorKind.refused) => l.errNoLink,
  RobotException(kind: RobotErrorKind.timeout) => l.errTimeout,
  RobotException(kind: RobotErrorKind.unsupported) => l.errUnsupported,
  RobotException() => l.errRobot,
  CloudException(kind: CloudErrorKind.accountNotFound) => l.errAccountNotFound,
  CloudException(kind: CloudErrorKind.tooManyCodes) => l.errTooManyCodes,
  CloudException(kind: CloudErrorKind.invalidCode) => l.errInvalidCode,
  CloudException(kind: CloudErrorKind.acceptTerms) => l.errAcceptTerms,
  CloudException(kind: CloudErrorKind.sessionExpired) => l.errSessionExpired,
  CloudException(kind: CloudErrorKind.noHome) => l.errNoHome,
  CloudException(kind: CloudErrorKind.noRobots) => l.errNoRobots,
  CloudException(kind: CloudErrorKind.network) => l.errNoInternet,
  CloudException(:final message) => message,
  _ => l.errUnexpected,
};

String pauseText(L10n l, PauseReason r) => switch (r.kind) {
  PauseKind.notStarted => l.pauseNotStarted,
  PauseKind.robotError => l.pauseRobotError(robotErrorText(l, r.code)),
  PauseKind.startFailed => l.pauseStartFailed,
  PauseKind.interrupted => l.pauseInterrupted,
};

String outcomeText(L10n l, RecordOutcome o) => switch (o) {
  RecordOutcome.finished => l.outcomeFinished,
  RecordOutcome.unreachable => l.outcomeUnreachable,
  RecordOutcome.lostLocation => l.outcomeLostLocation,
  RecordOutcome.washError => l.outcomeWashError,
  RecordOutcome.interrupted => l.outcomeInterrupted,
};

String sourceText(L10n l, RecordSource s) => switch (s) {
  RecordSource.button => l.sourceButton,
  RecordSource.app => l.sourceApp,
  RecordSource.schedule => l.sourceSchedule,
  RecordSource.routine => l.sourceRoutine,
  RecordSource.voice => l.sourceVoice,
  RecordSource.other => l.sourceOther,
};
