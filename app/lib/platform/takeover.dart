/// What the service should do on each check: the queue and the robot link have a single owner.
enum TakeoverAction { start, stop, none }

/// With the UI alive the app is in charge; without it (swiped away) the service takes over until it returns.
TakeoverAction takeover({required bool uiAlive, required bool runnerActive, required bool hasSession}) {
  if (!uiAlive && !runnerActive && hasSession) return TakeoverAction.start;
  if ((uiAlive || !hasSession) && runnerActive) return TakeoverAction.stop;
  return TakeoverAction.none;
}
