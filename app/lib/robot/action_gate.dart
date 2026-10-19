/// Stops the same action from being sent several times while the first one is still on its way
/// (repeated taps on a button that seems unresponsive).
class ActionGate {
  final _inFlight = <String>{};

  bool isPending(String key) => _inFlight.contains(key);

  bool get anyPending => _inFlight.isNotEmpty;

  /// Runs [action] unless another one with the same key is in flight. Returns false if it was ignored.
  Future<bool> run(String key, Future<void> Function() action, {void Function()? onChange}) async {
    if (!_inFlight.add(key)) return false;
    onChange?.call();
    try {
      await action();
      return true;
    } finally {
      _inFlight.remove(key);
      onChange?.call();
    }
  }
}

/// Status polling pace: fast right after a command (so the screen keeps up with the robot),
/// normal the rest of the time.
class PollSchedule {
  static const fast = Duration(seconds: 1);
  static const burst = Duration(seconds: 12);

  /// Pace outside the bursts that follow a command.
  final Duration normal;

  PollSchedule({this.normal = const Duration(seconds: 3)});

  DateTime? _lastCommand;
  DateTime _nextPoll = DateTime.fromMillisecondsSinceEpoch(0);

  void commandSent(DateTime now) {
    _lastCommand = now;
    _nextPoll = now; // read now
  }

  Duration intervalAt(DateTime now) {
    final last = _lastCommand;
    return last != null && now.difference(last) < burst ? fast : normal;
  }

  /// Whether it is time to read; if so, schedules the next reading.
  bool due(DateTime now) {
    if (now.isBefore(_nextPoll)) return false;
    _nextPoll = now.add(intervalAt(now));
    return true;
  }
}
