// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String robotState(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c1': 'Starting',
      'c2': 'Off the dock',
      'c3': 'Idle',
      'c4': 'Remote control',
      'c5': 'Cleaning',
      'c6': 'Returning to dock',
      'c7': 'Manual mode',
      'c8': 'On the dock',
      'c9': 'Charging problem',
      'c10': 'Paused',
      'c11': 'Spot cleaning',
      'c12': 'Error',
      'c13': 'Shutting down',
      'c14': 'Updating',
      'c15': 'Docking',
      'c16': 'Going to target',
      'c17': 'Cleaning zone',
      'c18': 'Cleaning rooms',
      'c22': 'Emptying the bin',
      'c23': 'Washing the mop',
      'c25': 'Washing the mop',
      'c26': 'Going to wash the mop',
      'c29': 'Mapping',
      'c100': 'Fully charged',
      'c101': 'Offline',
      'other': 'State',
    });
    return '$_temp0';
  }

  @override
  String fanLevel(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c101': 'quiet',
      'c102': 'balanced',
      'c103': 'turbo',
      'c104': 'max',
      'c108': 'max+',
      'c105': 'off',
      'c106': 'custom',
      'c110': 'smart',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String waterLevel(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c200': 'no water',
      'c221': 'very low',
      'c225': 'low',
      'c230': 'mild',
      'c235': 'medium',
      'c240': 'moderate',
      'c245': 'high',
      'c250': 'extreme',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String robotErrorText(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c1': 'Laser blocked. Check that nothing covers the sensor on top.',
      'c2': 'Bumper stuck. Tap it to free it.',
      'c3': 'Wheels off the floor. Put the robot down.',
      'c4': 'Cliff sensors dirty or blocked. Clean them.',
      'c5': 'Main brush stuck. Remove hair and strings.',
      'c6': 'Side brush stuck.',
      'c7': 'Wheels stuck.',
      'c8': 'The robot is trapped. Free it.',
      'c9': 'Dustbin missing.',
      'c10': 'Dustbin filter problem.',
      'c12': 'Low battery.',
      'c13': 'Charging error. Clean the dock and robot contacts.',
      'c14': 'Battery error.',
      'c15': 'Wall sensor dirty.',
      'c16': 'Robot tilted. Put it on a flat surface.',
      'c17': 'Side brush error.',
      'c18': 'Fan error.',
      'c19': 'Dock problem.',
      'c20': 'Optical sensor dirty. Clean it.',
      'c21': 'Vertical bumper pressed.',
      'c22': 'Cannot find the dock.',
      'c23': 'Could not return to the dock.',
      'c24': 'Inside a no-go zone.',
      'c25': 'Camera dirty or blocked.',
      'c27': 'Mop lift mechanism stuck.',
      'c28': 'Robot on a carpet with the mop.',
      'c29': 'Filter blocked. Clean or replace it.',
      'c30': 'Virtual wall detected.',
      'c31': 'Cannot cross the carpet.',
      'c32': 'Internal error. Restart the robot.',
      'c34': 'Auto-empty error.',
      'c35': 'Auto-empty error.',
      'c36': 'Mop roller problem.',
      'c37': 'Mop roller problem.',
      'c38': 'Clean water tank empty or not seated.',
      'c39': 'Dirty water tank full or not seated.',
      'c40': 'Wash tray filter clogged.',
      'c41': 'Clean water tank problem.',
      'c42': 'Dock cleaning brush problem.',
      'c43': 'Dock cleaning brush problem.',
      'c44': 'Dock filter problem.',
      'c45': 'Mop roller problem.',
      'c48': 'Problem refilling water.',
      'c49': 'Problem draining water.',
      'c51': 'Temperature protection on. Wait for it to cool down.',
      'c52': 'Wash tray problem.',
      'c53': 'Wash tray full of water.',
      'c54': 'Mop holder fell off.',
      'c55': 'Check the wash tray.',
      'c56': 'Audio error.',
      'other': 'Error $code.',
    });
    return '$_temp0';
  }

  @override
  String dockErrorText(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c32': 'Dock bag or filter missing.',
      'c33': 'Auto-empty fan error.',
      'c34': 'Auto-empty duct clogged.',
      'c35': 'Auto-empty voltage error.',
      'c38': 'Clean water tank empty.',
      'c39': 'Dirty water tank full.',
      'c42': 'Dock maintenance brush stuck.',
      'c44': 'Dirty water tank lid open.',
      'c46': 'Dock tank missing.',
      'c53': 'Cleaning tank full or clogged.',
      'other': 'Dock error $code.',
    });
    return '$_temp0';
  }

  @override
  String get alertRobotTitle => 'The robot needs help';

  @override
  String get alertDockTitle => 'The dock needs attention';

  @override
  String get alertWaterTitle => 'Out of water';

  @override
  String get alertWaterBody => 'Fill the dock\'s clean water tank.';

  @override
  String get sectionCarpets => 'Carpets';

  @override
  String get sectionDock => 'Dock';

  @override
  String get sectionCleaning => 'Cleaning';

  @override
  String get sectionRobot => 'Robot';

  @override
  String get setCarpetMode => 'With the mop, on carpets';

  @override
  String get optAvoid => 'Avoid';

  @override
  String get optLiftMop => 'Lift the mop';

  @override
  String get optIgnore => 'Ignore';

  @override
  String get optCross => 'Cross';

  @override
  String get setCarpetBoost => 'Boost suction on carpets';

  @override
  String get setCarpetDeep => 'Deep carpet cleaning';

  @override
  String get setAutoEmpty => 'Empty the bin automatically';

  @override
  String get setEmptyMode => 'Emptying strength';

  @override
  String get optSmart => 'Smart';

  @override
  String get optLight => 'Light';

  @override
  String get optBalanced => 'Balanced';

  @override
  String get optMax => 'Max';

  @override
  String get optDeep => 'Deep';

  @override
  String get optVeryDeep => 'Very deep';

  @override
  String get setDryer => 'Dry the mop after washing';

  @override
  String get setWashMode => 'Mop washing';

  @override
  String get setWashInterval => 'Rewash the mop every';

  @override
  String get setWashIntervalSub => 'During the clean';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String get setCornerMop => 'Extend the mop into corners';

  @override
  String get setFurniture => 'Recognise furniture';

  @override
  String get setFurnitureSub => 'Cleans better around and under furniture';

  @override
  String get setLed => 'Button light';

  @override
  String get chAlerts => 'Robot alerts';

  @override
  String get chAlertsDesc => 'Errors, dock problems and low water';

  @override
  String get chCleans => 'Finished cleans';

  @override
  String get chCleansDesc => 'Summary of each clean';

  @override
  String get chStatus => 'Robot status';

  @override
  String get chStatusDesc => 'What the robot is doing and what comes next';

  @override
  String roomN(int id) {
    return 'Room $id';
  }

  @override
  String get robot => 'Robot';

  @override
  String get robotCharging => 'Robot charging';

  @override
  String get errNoLink => 'No connection to the robot';

  @override
  String get errTimeout => 'The robot did not answer in time. Try again.';

  @override
  String get errUnsupported => 'The robot does not support this.';

  @override
  String get errRobot => 'The robot refused the command.';

  @override
  String get errAccountNotFound => 'No Roborock account found for this email.';

  @override
  String get errTooManyCodes => 'Too many codes requested. Try again later.';

  @override
  String get errInvalidCode => 'Invalid code.';

  @override
  String get errAcceptTerms => 'Accept the terms in the Roborock app first.';

  @override
  String get errSessionExpired => 'Session expired. Log in again.';

  @override
  String get errNoHome => 'This account has no home.';

  @override
  String get errNoInternet => 'No connection to the Roborock cloud.';

  @override
  String get errUnexpected => 'Something went wrong. Try again.';

  @override
  String get pauseNotStarted => 'The robot did not start the clean.';

  @override
  String pauseRobotError(String error) {
    return 'The robot stopped with an error: $error';
  }

  @override
  String get pauseStartFailed => 'Could not start the next clean.';

  @override
  String get pauseInterrupted => 'The previous clean was interrupted. Continue with the rest of the queue?';

  @override
  String get outcomeFinished => 'Finished';

  @override
  String get outcomeUnreachable => 'Area unreachable';

  @override
  String get outcomeLostLocation => 'Lost its location';

  @override
  String get outcomeWashError => 'Washing error';

  @override
  String get outcomeInterrupted => 'Interrupted';

  @override
  String get sourceButton => 'Button';

  @override
  String get sourceApp => 'App';

  @override
  String get sourceSchedule => 'Schedule';

  @override
  String get sourceRoutine => 'Routine';

  @override
  String get sourceVoice => 'Voice assistant';

  @override
  String get sourceOther => 'Other';

  @override
  String routineQueuedTitle(String name) {
    return 'Routine \"$name\"';
  }

  @override
  String get routineQueuedBody => 'Queued at its scheduled time.';

  @override
  String get queuePaused => 'Queue paused';

  @override
  String jobZones(int count, String area) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count zones', one: 'Zone');
    return '$_temp0 ($area m²)';
  }

  @override
  String get wholeHome => 'Whole home';

  @override
  String cleaningRoom(String room) {
    return 'Cleaning: $room';
  }

  @override
  String minutesLeft(int n) {
    return '~$n min left';
  }

  @override
  String batteryPercent(int n) {
    return 'battery $n%';
  }

  @override
  String upNext(String job) {
    return 'up next: $job';
  }

  @override
  String get queuePausedLower => 'queue paused';

  @override
  String get cleanGeneric => 'Clean';

  @override
  String jobFinished(String job) {
    return '$job finished';
  }

  @override
  String get cleanInterrupted => 'Clean interrupted';

  @override
  String jobOutcome(String job, String outcome) {
    return '$job: $outcome';
  }

  @override
  String minutesArea(int min, String area) {
    return '$min min · $area m²';
  }

  @override
  String mopWashes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count mop washes', one: '1 mop wash');
    return '$_temp0';
  }

  @override
  String cleanZonesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clean $count zones',
      one: 'Clean this zone',
    );
    return '$_temp0';
  }

  @override
  String get zonesQueueNote => 'They join the queue after the current clean, one after another. Nothing is cancelled.';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get clean => 'Clean';

  @override
  String get drawZoneHint => 'Drag on the map to draw a zone. You can draw several.';

  @override
  String zonesArea(int count, String area) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count zones', one: '1 zone');
    return '$_temp0 · $area m²';
  }

  @override
  String get next => 'Next';

  @override
  String get addZone => 'Add zone';

  @override
  String get zone => 'Zone';

  @override
  String get cleanFinished => 'Clean finished';

  @override
  String get connecting => 'Connecting to the robot…';

  @override
  String get cleaning => 'Cleaning';

  @override
  String suctionLevel(String level) {
    return 'suction $level';
  }

  @override
  String waterLevelLine(String level) {
    return 'water $level';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get adjust => 'Adjust';

  @override
  String get dock => 'Dock';

  @override
  String get findMe => 'Where are you?';

  @override
  String get cleanWholeHome => 'Clean the whole home';

  @override
  String get addToQueueLong => 'Add to queue';

  @override
  String get adjustRunning => 'Adjust the running clean';

  @override
  String get adjustRunningSub => 'Applies now, nothing is cancelled.';

  @override
  String get upNextTitle => 'Up next';

  @override
  String get resumeQueue => 'Resume queue';

  @override
  String nowJob(String job) {
    return 'Now: $job';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get skipToNext => 'Skip to the next one';

  @override
  String get stopping => 'Stopping…';

  @override
  String get skip => 'Skip';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get notifications => 'Notifications';

  @override
  String get now => 'Now';

  @override
  String get recent => 'Recent';

  @override
  String get noAlertsYet => 'No alerts yet.';

  @override
  String get linkLocal => 'Connected over the local network';

  @override
  String get linkCloud => 'Connected through the cloud';

  @override
  String get linkOffline => 'No connection';

  @override
  String get fanMopOnly => 'Mop only';

  @override
  String get fanQuiet => 'Quiet';

  @override
  String get fanBalanced => 'Balanced';

  @override
  String get fanTurbo => 'Turbo';

  @override
  String get fanMax => 'Max';

  @override
  String get fanMaxPlus => 'Max+';

  @override
  String get waterOff => 'No water';

  @override
  String get waterLow => 'Low';

  @override
  String get waterMedium => 'Medium';

  @override
  String get waterHigh => 'High';

  @override
  String get waterExtreme => 'Extreme';

  @override
  String get routeFast => 'Fast';

  @override
  String get routeStandard => 'Standard';

  @override
  String get routeDeepPlus => 'Deep+';

  @override
  String get styleSmart => 'Smart';

  @override
  String get styleVacuum => 'Vacuum';

  @override
  String get styleVacuumMop => 'Vacuum and mop';

  @override
  String get styleVacuumThenMop => 'Vacuum, then mop';

  @override
  String get styleMop => 'Mop only';

  @override
  String get styleCustom => 'Custom';

  @override
  String get sumSmart => 'smart';

  @override
  String get sumVacuumThenMop => 'vacuum, then mop';

  @override
  String get sumMopOnly => 'mop only';

  @override
  String sumVacuum(String level) {
    return 'vacuum $level';
  }

  @override
  String sumMop(String level) {
    return 'mop $level';
  }

  @override
  String sumRoute(String route) {
    return 'route $route';
  }

  @override
  String get smartHint => 'The robot adapts suction, water and route to the floor and dirt in each area.';

  @override
  String get suction => 'Suction';

  @override
  String get mop => 'Mop';

  @override
  String get mopRoute => 'Mop route';

  @override
  String get passes => 'Passes';

  @override
  String get passOne => 'One';

  @override
  String get passTwo => 'Two';

  @override
  String get passThree => 'Three';

  @override
  String get modeRooms => 'Rooms';

  @override
  String get modeZones => 'Zones';

  @override
  String get modePoint => 'Go to';

  @override
  String get modeHome => 'Whole home';

  @override
  String get hintRooms => 'Tap the rooms in the order you want them cleaned.';

  @override
  String get hintZones => 'Drag on the map to draw zones.';

  @override
  String get hintPoint => 'Tap where the robot should go.';

  @override
  String get hintHome => 'Cleans the whole home in the order the robot thinks best.';

  @override
  String get howToClean => 'How to clean';

  @override
  String get appliesToAllRooms => 'Applies to all the chosen rooms.';

  @override
  String get roomOnlySettings => 'Settings for this room only.';

  @override
  String routineSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count jobs', one: '1 job');
    return '$_temp0 · $when';
  }

  @override
  String get joinsQueueNoCancel => 'joins the queue without cancelling the current clean';

  @override
  String get startsNow => 'starts now';

  @override
  String get cleanNow => 'Clean now';

  @override
  String get newRoutine => 'New routine';

  @override
  String get routine => 'Routine';

  @override
  String get name => 'Name';

  @override
  String get repeat => 'Repeat';

  @override
  String get weekdaysNarrow => 'M T W T F S S';

  @override
  String atTime(String time) {
    return 'At $time';
  }

  @override
  String get unscheduled => 'No schedule (manual only)';

  @override
  String get time => 'Time';

  @override
  String get changeTime => 'Change time';

  @override
  String get enabled => 'Enabled';

  @override
  String get save => 'Save';

  @override
  String get deleteRoutine => 'Delete routine';

  @override
  String get pickRoomsOnMap => 'Pick rooms on the map';

  @override
  String cleanRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Clean $count rooms', one: 'Clean 1 room');
    return '$_temp0';
  }

  @override
  String queueRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Queue $count rooms', one: 'Queue 1 room');
    return '$_temp0';
  }

  @override
  String get drawZoneOnMap => 'Draw a zone on the map';

  @override
  String cleanZones(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Clean $count zones', one: 'Clean 1 zone');
    return '$_temp0';
  }

  @override
  String queueZones(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Queue $count zones', one: 'Queue 1 zone');
    return '$_temp0';
  }

  @override
  String get tapPointOnMap => 'Tap a point on the map';

  @override
  String get goHere => 'Go here';

  @override
  String get queueWholeHome => 'Queue the whole home';

  @override
  String get plan => 'Plan';

  @override
  String runRoutine(String name) {
    return 'Run routine $name';
  }

  @override
  String get undoLastZone => 'Undo the last zone';

  @override
  String get how => 'How';

  @override
  String get saveAsRoutine => 'Save as routine';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String settingsOf(String name) {
    return 'Settings for $name';
  }

  @override
  String get consMainBrush => 'Main\nbrush';

  @override
  String get consSideBrush => 'Side\nbrush';

  @override
  String get consFilter => 'Filter';

  @override
  String get consSensors => 'Sensors';

  @override
  String get startsAt => 'Starts at';

  @override
  String get endsAt => 'Ends at';

  @override
  String resetPart(String name) {
    return 'Reset $name?';
  }

  @override
  String get resetPartSub => 'Do this after replacing or cleaning the part.';

  @override
  String get reset => 'Reset';

  @override
  String stateBattery(String state, int n) {
    return '$state · battery $n%';
  }

  @override
  String get connectingShort => 'Connecting…';

  @override
  String get emptyBin => 'Empty bin';

  @override
  String get washMop => 'Wash mop';

  @override
  String get map => 'Map';

  @override
  String get editMap => 'Edit map';

  @override
  String get editMapSub => 'No-go zones, no-mop zones and virtual walls';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get cleanNowShort => 'clean now';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get gaugeHint => 'Tap a gauge after cleaning or replacing the part.';

  @override
  String currentValue(int value) {
    return 'Current ($value)';
  }

  @override
  String get doNotDisturb => 'Do not disturb';

  @override
  String get quietAtNight => 'Quiet at night';

  @override
  String get quietAtNightSub => 'Does not start cleans or speak';

  @override
  String get from => 'From';

  @override
  String get to => 'to';

  @override
  String get soundSafety => 'Sound and safety';

  @override
  String get voiceVolume => 'Voice volume';

  @override
  String get childLock => 'Child lock';

  @override
  String get childLockSub => 'Disables the buttons on the robot';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get logOut => 'Log out';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationHourMin(int h, int m) {
    return '$h h $m min';
  }

  @override
  String todayAt(String time) {
    return 'Today, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday, $time';
  }

  @override
  String dateAt(DateTime date, String time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString, $time';
  }

  @override
  String get history => 'History';

  @override
  String get historySub => 'What the robot did and how long it took';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get cleansUnit => 'cleans';

  @override
  String get timeLabel => 'Time';

  @override
  String get in7Days => 'in 7 days';

  @override
  String get areaLabel => 'Area';

  @override
  String get m2In7Days => 'm² in 7 days';

  @override
  String allTime(int count, int hours, int area) {
    return 'All time: $count cleans · $hours h · $area m²';
  }

  @override
  String get perRoom => 'Per room';

  @override
  String get perRoomSub => 'Measured by the app during the cleans it followed.';

  @override
  String roomStats(int count, String duration) {
    return '$count× · average $duration';
  }

  @override
  String get cleans => 'Cleans';

  @override
  String get noRecordsYet => 'No records yet.';

  @override
  String washes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count washes', one: '1 wash');
    return '$_temp0';
  }

  @override
  String obstaclesAvoided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obstacles avoided',
      one: '1 obstacle avoided',
    );
    return '$_temp0';
  }

  @override
  String fasterThanAvg(int m) {
    return '$m min faster than the average for these rooms';
  }

  @override
  String slowerThanAvg(int m) {
    return '$m min slower than the average for these rooms';
  }

  @override
  String get omissionNote => 'The robot flagged areas it could not clean.';

  @override
  String get activity => 'Activity';

  @override
  String get days14 => '14 days';

  @override
  String get weeks8 => '8 weeks';

  @override
  String weekOf(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Week of $dateString';
  }

  @override
  String shortDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get noCleans => 'no cleans';

  @override
  String activityDetail(int count, int min, String area) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count cleans', one: '1 clean');
    return '$_temp0 · $min min · $area m²';
  }

  @override
  String get recordMapGone =>
      'The robot no longer has this clean\'s map. From now on the app keeps each clean\'s map on the phone, so you can always see it.';

  @override
  String get toolNoGo => 'No-go';

  @override
  String get toolNoGoHint => 'Drag to mark where the robot cannot go. Tap one to delete it.';

  @override
  String get toolNoMop => 'No mop';

  @override
  String get toolNoMopHint => 'Drag to mark where it vacuums but does not mop. Tap one to delete it.';

  @override
  String get toolWall => 'Wall';

  @override
  String get toolWallHint => 'Drag a line the robot cannot cross. Tap one to delete it.';

  @override
  String get saveNotShownYet => 'The robot accepted it, but the map does not show the changes yet. Try again shortly.';

  @override
  String restrictions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restrictions',
      one: '1 restriction',
      zero: 'No restrictions',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Undo';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get saveToRobot => 'Save to robot';

  @override
  String get noChanges => 'No changes';

  @override
  String get errNoRobots => 'This account has no robots.';

  @override
  String get loginPitch =>
      'Everything the official app does, plus what it lacks: a cleaning queue, changes without cancelling, a clear map. Sign in with your Roborock account.';

  @override
  String get emailHint => 'your@email.com';

  @override
  String get codeHint => 'code from the email';

  @override
  String get signIn => 'Sign in';

  @override
  String get sendCode => 'Send code';

  @override
  String get changeEmail => 'Change email';

  @override
  String get sending => 'Sending…';

  @override
  String get loading => 'Loading';

  @override
  String get choose => 'Choose';

  @override
  String get tabNow => 'Now';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabHistory => 'History';

  @override
  String get tabRobot => 'Robot';

  @override
  String get setDryTime => 'Drying time';

  @override
  String get setWaterTemp => 'Mop wash water';

  @override
  String get tempRoom => 'Room temperature';

  @override
  String get tempWarm => 'Warm';

  @override
  String get tempHot => 'Hot';
}
