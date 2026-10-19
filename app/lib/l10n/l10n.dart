import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('pt')];

  /// No description provided for @robotState.
  ///
  /// In en, this message translates to:
  /// **'{code, select, c1{Starting} c2{Off the dock} c3{Idle} c4{Remote control} c5{Cleaning} c6{Returning to dock} c7{Manual mode} c8{On the dock} c9{Charging problem} c10{Paused} c11{Spot cleaning} c12{Error} c13{Shutting down} c14{Updating} c15{Docking} c16{Going to target} c17{Cleaning zone} c18{Cleaning rooms} c22{Emptying the bin} c23{Washing the mop} c25{Washing the mop} c26{Going to wash the mop} c29{Mapping} c100{Fully charged} c101{Offline} other{State}}'**
  String robotState(String code);

  /// No description provided for @fanLevel.
  ///
  /// In en, this message translates to:
  /// **'{code, select, c101{quiet} c102{balanced} c103{turbo} c104{max} c108{max+} c105{off} c106{custom} c110{smart} other{—}}'**
  String fanLevel(String code);

  /// No description provided for @waterLevel.
  ///
  /// In en, this message translates to:
  /// **'{code, select, c200{no water} c221{very low} c225{low} c230{mild} c235{medium} c240{moderate} c245{high} c250{extreme} other{—}}'**
  String waterLevel(String code);

  /// No description provided for @robotErrorText.
  ///
  /// In en, this message translates to:
  /// **'{code, select, c1{Laser blocked. Check that nothing covers the sensor on top.} c2{Bumper stuck. Tap it to free it.} c3{Wheels off the floor. Put the robot down.} c4{Cliff sensors dirty or blocked. Clean them.} c5{Main brush stuck. Remove hair and strings.} c6{Side brush stuck.} c7{Wheels stuck.} c8{The robot is trapped. Free it.} c9{Dustbin missing.} c10{Dustbin filter problem.} c12{Low battery.} c13{Charging error. Clean the dock and robot contacts.} c14{Battery error.} c15{Wall sensor dirty.} c16{Robot tilted. Put it on a flat surface.} c17{Side brush error.} c18{Fan error.} c19{Dock problem.} c20{Optical sensor dirty. Clean it.} c21{Vertical bumper pressed.} c22{Cannot find the dock.} c23{Could not return to the dock.} c24{Inside a no-go zone.} c25{Camera dirty or blocked.} c27{Mop lift mechanism stuck.} c28{Robot on a carpet with the mop.} c29{Filter blocked. Clean or replace it.} c30{Virtual wall detected.} c31{Cannot cross the carpet.} c32{Internal error. Restart the robot.} c34{Auto-empty error.} c35{Auto-empty error.} c36{Mop roller problem.} c37{Mop roller problem.} c38{Clean water tank empty or not seated.} c39{Dirty water tank full or not seated.} c40{Wash tray filter clogged.} c41{Clean water tank problem.} c42{Dock cleaning brush problem.} c43{Dock cleaning brush problem.} c44{Dock filter problem.} c45{Mop roller problem.} c48{Problem refilling water.} c49{Problem draining water.} c51{Temperature protection on. Wait for it to cool down.} c52{Wash tray problem.} c53{Wash tray full of water.} c54{Mop holder fell off.} c55{Check the wash tray.} c56{Audio error.} other{Error {code}.}}'**
  String robotErrorText(String code);

  /// No description provided for @dockErrorText.
  ///
  /// In en, this message translates to:
  /// **'{code, select, c32{Dock bag or filter missing.} c33{Auto-empty fan error.} c34{Auto-empty duct clogged.} c35{Auto-empty voltage error.} c38{Clean water tank empty.} c39{Dirty water tank full.} c42{Dock maintenance brush stuck.} c44{Dirty water tank lid open.} c46{Dock tank missing.} c53{Cleaning tank full or clogged.} other{Dock error {code}.}}'**
  String dockErrorText(String code);

  /// No description provided for @alertRobotTitle.
  ///
  /// In en, this message translates to:
  /// **'The robot needs help'**
  String get alertRobotTitle;

  /// No description provided for @alertDockTitle.
  ///
  /// In en, this message translates to:
  /// **'The dock needs attention'**
  String get alertDockTitle;

  /// No description provided for @alertWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of water'**
  String get alertWaterTitle;

  /// No description provided for @alertWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Fill the dock\'s clean water tank.'**
  String get alertWaterBody;

  /// No description provided for @sectionCarpets.
  ///
  /// In en, this message translates to:
  /// **'Carpets'**
  String get sectionCarpets;

  /// No description provided for @sectionDock.
  ///
  /// In en, this message translates to:
  /// **'Dock'**
  String get sectionDock;

  /// No description provided for @sectionCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get sectionCleaning;

  /// No description provided for @sectionRobot.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get sectionRobot;

  /// No description provided for @setCarpetMode.
  ///
  /// In en, this message translates to:
  /// **'With the mop, on carpets'**
  String get setCarpetMode;

  /// No description provided for @optAvoid.
  ///
  /// In en, this message translates to:
  /// **'Avoid'**
  String get optAvoid;

  /// No description provided for @optLiftMop.
  ///
  /// In en, this message translates to:
  /// **'Lift the mop'**
  String get optLiftMop;

  /// No description provided for @optIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get optIgnore;

  /// No description provided for @optCross.
  ///
  /// In en, this message translates to:
  /// **'Cross'**
  String get optCross;

  /// No description provided for @setCarpetBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost suction on carpets'**
  String get setCarpetBoost;

  /// No description provided for @setCarpetDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep carpet cleaning'**
  String get setCarpetDeep;

  /// No description provided for @setAutoEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty the bin automatically'**
  String get setAutoEmpty;

  /// No description provided for @setEmptyMode.
  ///
  /// In en, this message translates to:
  /// **'Emptying strength'**
  String get setEmptyMode;

  /// No description provided for @optSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get optSmart;

  /// No description provided for @optLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get optLight;

  /// No description provided for @optBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get optBalanced;

  /// No description provided for @optMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get optMax;

  /// No description provided for @optDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get optDeep;

  /// No description provided for @optVeryDeep.
  ///
  /// In en, this message translates to:
  /// **'Very deep'**
  String get optVeryDeep;

  /// No description provided for @setDryer.
  ///
  /// In en, this message translates to:
  /// **'Dry the mop after washing'**
  String get setDryer;

  /// No description provided for @setWashMode.
  ///
  /// In en, this message translates to:
  /// **'Mop washing'**
  String get setWashMode;

  /// No description provided for @setWashInterval.
  ///
  /// In en, this message translates to:
  /// **'Rewash the mop every'**
  String get setWashInterval;

  /// No description provided for @setWashIntervalSub.
  ///
  /// In en, this message translates to:
  /// **'During the clean'**
  String get setWashIntervalSub;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutes(int n);

  /// No description provided for @setCornerMop.
  ///
  /// In en, this message translates to:
  /// **'Extend the mop into corners'**
  String get setCornerMop;

  /// No description provided for @setFurniture.
  ///
  /// In en, this message translates to:
  /// **'Recognise furniture'**
  String get setFurniture;

  /// No description provided for @setFurnitureSub.
  ///
  /// In en, this message translates to:
  /// **'Cleans better around and under furniture'**
  String get setFurnitureSub;

  /// No description provided for @setLed.
  ///
  /// In en, this message translates to:
  /// **'Button light'**
  String get setLed;

  /// No description provided for @chAlerts.
  ///
  /// In en, this message translates to:
  /// **'Robot alerts'**
  String get chAlerts;

  /// No description provided for @chAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Errors, dock problems and low water'**
  String get chAlertsDesc;

  /// No description provided for @chCleans.
  ///
  /// In en, this message translates to:
  /// **'Finished cleans'**
  String get chCleans;

  /// No description provided for @chCleansDesc.
  ///
  /// In en, this message translates to:
  /// **'Summary of each clean'**
  String get chCleansDesc;

  /// No description provided for @chStatus.
  ///
  /// In en, this message translates to:
  /// **'Robot status'**
  String get chStatus;

  /// No description provided for @chStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'What the robot is doing and what comes next'**
  String get chStatusDesc;

  /// No description provided for @roomN.
  ///
  /// In en, this message translates to:
  /// **'Room {id}'**
  String roomN(int id);

  /// No description provided for @robot.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get robot;

  /// No description provided for @robotCharging.
  ///
  /// In en, this message translates to:
  /// **'Robot charging'**
  String get robotCharging;

  /// No description provided for @errNoLink.
  ///
  /// In en, this message translates to:
  /// **'No connection to the robot'**
  String get errNoLink;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The robot did not answer in time. Try again.'**
  String get errTimeout;

  /// No description provided for @errUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The robot does not support this.'**
  String get errUnsupported;

  /// No description provided for @errRobot.
  ///
  /// In en, this message translates to:
  /// **'The robot refused the command.'**
  String get errRobot;

  /// No description provided for @errAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No Roborock account found for this email.'**
  String get errAccountNotFound;

  /// No description provided for @errTooManyCodes.
  ///
  /// In en, this message translates to:
  /// **'Too many codes requested. Try again later.'**
  String get errTooManyCodes;

  /// No description provided for @errInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code.'**
  String get errInvalidCode;

  /// No description provided for @errAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept the terms in the Roborock app first.'**
  String get errAcceptTerms;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Log in again.'**
  String get errSessionExpired;

  /// No description provided for @errNoHome.
  ///
  /// In en, this message translates to:
  /// **'This account has no home.'**
  String get errNoHome;

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No connection to the Roborock cloud.'**
  String get errNoInternet;

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errUnexpected;

  /// No description provided for @pauseNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The robot did not start the clean.'**
  String get pauseNotStarted;

  /// No description provided for @pauseRobotError.
  ///
  /// In en, this message translates to:
  /// **'The robot stopped with an error: {error}'**
  String pauseRobotError(String error);

  /// No description provided for @pauseStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the next clean.'**
  String get pauseStartFailed;

  /// No description provided for @pauseInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The previous clean was interrupted. Continue with the rest of the queue?'**
  String get pauseInterrupted;

  /// No description provided for @outcomeFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get outcomeFinished;

  /// No description provided for @outcomeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Area unreachable'**
  String get outcomeUnreachable;

  /// No description provided for @outcomeLostLocation.
  ///
  /// In en, this message translates to:
  /// **'Lost its location'**
  String get outcomeLostLocation;

  /// No description provided for @outcomeWashError.
  ///
  /// In en, this message translates to:
  /// **'Washing error'**
  String get outcomeWashError;

  /// No description provided for @outcomeInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get outcomeInterrupted;

  /// No description provided for @sourceButton.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get sourceButton;

  /// No description provided for @sourceApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sourceApp;

  /// No description provided for @sourceSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get sourceSchedule;

  /// No description provided for @sourceRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get sourceRoutine;

  /// No description provided for @sourceVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant'**
  String get sourceVoice;

  /// No description provided for @sourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sourceOther;

  /// No description provided for @routineQueuedTitle.
  ///
  /// In en, this message translates to:
  /// **'Routine \"{name}\"'**
  String routineQueuedTitle(String name);

  /// No description provided for @routineQueuedBody.
  ///
  /// In en, this message translates to:
  /// **'Queued at its scheduled time.'**
  String get routineQueuedBody;

  /// No description provided for @queuePaused.
  ///
  /// In en, this message translates to:
  /// **'Queue paused'**
  String get queuePaused;

  /// No description provided for @jobZones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Zone} other{{count} zones}} ({area} m²)'**
  String jobZones(int count, String area);

  /// No description provided for @wholeHome.
  ///
  /// In en, this message translates to:
  /// **'Whole home'**
  String get wholeHome;

  /// No description provided for @cleaningRoom.
  ///
  /// In en, this message translates to:
  /// **'Cleaning: {room}'**
  String cleaningRoom(String room);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'~{n} min left'**
  String minutesLeft(int n);

  /// No description provided for @batteryPercent.
  ///
  /// In en, this message translates to:
  /// **'battery {n}%'**
  String batteryPercent(int n);

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'up next: {job}'**
  String upNext(String job);

  /// No description provided for @queuePausedLower.
  ///
  /// In en, this message translates to:
  /// **'queue paused'**
  String get queuePausedLower;

  /// No description provided for @cleanGeneric.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get cleanGeneric;

  /// No description provided for @jobFinished.
  ///
  /// In en, this message translates to:
  /// **'{job} finished'**
  String jobFinished(String job);

  /// No description provided for @cleanInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Clean interrupted'**
  String get cleanInterrupted;

  /// No description provided for @jobOutcome.
  ///
  /// In en, this message translates to:
  /// **'{job}: {outcome}'**
  String jobOutcome(String job, String outcome);

  /// No description provided for @minutesArea.
  ///
  /// In en, this message translates to:
  /// **'{min} min · {area} m²'**
  String minutesArea(int min, String area);

  /// No description provided for @mopWashes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mop wash} other{{count} mop washes}}'**
  String mopWashes(int count);

  /// No description provided for @cleanZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Clean this zone} other{Clean {count} zones}}'**
  String cleanZonesTitle(int count);

  /// No description provided for @zonesQueueNote.
  ///
  /// In en, this message translates to:
  /// **'They join the queue after the current clean, one after another. Nothing is cancelled.'**
  String get zonesQueueNote;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @clean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get clean;

  /// No description provided for @drawZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Drag on the map to draw a zone. You can draw several.'**
  String get drawZoneHint;

  /// No description provided for @zonesArea.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 zone} other{{count} zones}} · {area} m²'**
  String zonesArea(int count, String area);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @addZone.
  ///
  /// In en, this message translates to:
  /// **'Add zone'**
  String get addZone;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @cleanFinished.
  ///
  /// In en, this message translates to:
  /// **'Clean finished'**
  String get cleanFinished;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the robot…'**
  String get connecting;

  /// No description provided for @cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// No description provided for @suctionLevel.
  ///
  /// In en, this message translates to:
  /// **'suction {level}'**
  String suctionLevel(String level);

  /// No description provided for @waterLevelLine.
  ///
  /// In en, this message translates to:
  /// **'water {level}'**
  String waterLevelLine(String level);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @dock.
  ///
  /// In en, this message translates to:
  /// **'Dock'**
  String get dock;

  /// No description provided for @findMe.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get findMe;

  /// No description provided for @cleanWholeHome.
  ///
  /// In en, this message translates to:
  /// **'Clean the whole home'**
  String get cleanWholeHome;

  /// No description provided for @addToQueueLong.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueueLong;

  /// No description provided for @adjustRunning.
  ///
  /// In en, this message translates to:
  /// **'Adjust the running clean'**
  String get adjustRunning;

  /// No description provided for @adjustRunningSub.
  ///
  /// In en, this message translates to:
  /// **'Applies now, nothing is cancelled.'**
  String get adjustRunningSub;

  /// No description provided for @upNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNextTitle;

  /// No description provided for @resumeQueue.
  ///
  /// In en, this message translates to:
  /// **'Resume queue'**
  String get resumeQueue;

  /// No description provided for @nowJob.
  ///
  /// In en, this message translates to:
  /// **'Now: {job}'**
  String nowJob(String job);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @skipToNext.
  ///
  /// In en, this message translates to:
  /// **'Skip to the next one'**
  String get skipToNext;

  /// No description provided for @stopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get stopping;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @removeFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueue;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet.'**
  String get noAlertsYet;

  /// No description provided for @linkLocal.
  ///
  /// In en, this message translates to:
  /// **'Connected over the local network'**
  String get linkLocal;

  /// No description provided for @linkCloud.
  ///
  /// In en, this message translates to:
  /// **'Connected through the cloud'**
  String get linkCloud;

  /// No description provided for @linkOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get linkOffline;

  /// No description provided for @fanMopOnly.
  ///
  /// In en, this message translates to:
  /// **'Mop only'**
  String get fanMopOnly;

  /// No description provided for @fanQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get fanQuiet;

  /// No description provided for @fanBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get fanBalanced;

  /// No description provided for @fanTurbo.
  ///
  /// In en, this message translates to:
  /// **'Turbo'**
  String get fanTurbo;

  /// No description provided for @fanMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get fanMax;

  /// No description provided for @fanMaxPlus.
  ///
  /// In en, this message translates to:
  /// **'Max+'**
  String get fanMaxPlus;

  /// No description provided for @waterOff.
  ///
  /// In en, this message translates to:
  /// **'No water'**
  String get waterOff;

  /// No description provided for @waterLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get waterLow;

  /// No description provided for @waterMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get waterMedium;

  /// No description provided for @waterHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get waterHigh;

  /// No description provided for @waterExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get waterExtreme;

  /// No description provided for @routeFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get routeFast;

  /// No description provided for @routeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get routeStandard;

  /// No description provided for @routeDeepPlus.
  ///
  /// In en, this message translates to:
  /// **'Deep+'**
  String get routeDeepPlus;

  /// No description provided for @styleSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get styleSmart;

  /// No description provided for @styleVacuum.
  ///
  /// In en, this message translates to:
  /// **'Vacuum'**
  String get styleVacuum;

  /// No description provided for @styleVacuumMop.
  ///
  /// In en, this message translates to:
  /// **'Vacuum and mop'**
  String get styleVacuumMop;

  /// No description provided for @styleVacuumThenMop.
  ///
  /// In en, this message translates to:
  /// **'Vacuum, then mop'**
  String get styleVacuumThenMop;

  /// No description provided for @styleMop.
  ///
  /// In en, this message translates to:
  /// **'Mop only'**
  String get styleMop;

  /// No description provided for @styleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get styleCustom;

  /// No description provided for @sumSmart.
  ///
  /// In en, this message translates to:
  /// **'smart'**
  String get sumSmart;

  /// No description provided for @sumVacuumThenMop.
  ///
  /// In en, this message translates to:
  /// **'vacuum, then mop'**
  String get sumVacuumThenMop;

  /// No description provided for @sumMopOnly.
  ///
  /// In en, this message translates to:
  /// **'mop only'**
  String get sumMopOnly;

  /// No description provided for @sumVacuum.
  ///
  /// In en, this message translates to:
  /// **'vacuum {level}'**
  String sumVacuum(String level);

  /// No description provided for @sumMop.
  ///
  /// In en, this message translates to:
  /// **'mop {level}'**
  String sumMop(String level);

  /// No description provided for @sumRoute.
  ///
  /// In en, this message translates to:
  /// **'route {route}'**
  String sumRoute(String route);

  /// No description provided for @smartHint.
  ///
  /// In en, this message translates to:
  /// **'The robot adapts suction, water and route to the floor and dirt in each area.'**
  String get smartHint;

  /// No description provided for @suction.
  ///
  /// In en, this message translates to:
  /// **'Suction'**
  String get suction;

  /// No description provided for @mop.
  ///
  /// In en, this message translates to:
  /// **'Mop'**
  String get mop;

  /// No description provided for @mopRoute.
  ///
  /// In en, this message translates to:
  /// **'Mop route'**
  String get mopRoute;

  /// No description provided for @passes.
  ///
  /// In en, this message translates to:
  /// **'Passes'**
  String get passes;

  /// No description provided for @passOne.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get passOne;

  /// No description provided for @passTwo.
  ///
  /// In en, this message translates to:
  /// **'Two'**
  String get passTwo;

  /// No description provided for @passThree.
  ///
  /// In en, this message translates to:
  /// **'Three'**
  String get passThree;

  /// No description provided for @modeRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get modeRooms;

  /// No description provided for @modeZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get modeZones;

  /// No description provided for @modePoint.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get modePoint;

  /// No description provided for @modeHome.
  ///
  /// In en, this message translates to:
  /// **'Whole home'**
  String get modeHome;

  /// No description provided for @hintRooms.
  ///
  /// In en, this message translates to:
  /// **'Tap the rooms in the order you want them cleaned.'**
  String get hintRooms;

  /// No description provided for @hintZones.
  ///
  /// In en, this message translates to:
  /// **'Drag on the map to draw zones.'**
  String get hintZones;

  /// No description provided for @hintPoint.
  ///
  /// In en, this message translates to:
  /// **'Tap where the robot should go.'**
  String get hintPoint;

  /// No description provided for @hintHome.
  ///
  /// In en, this message translates to:
  /// **'Cleans the whole home in the order the robot thinks best.'**
  String get hintHome;

  /// No description provided for @howToClean.
  ///
  /// In en, this message translates to:
  /// **'How to clean'**
  String get howToClean;

  /// No description provided for @appliesToAllRooms.
  ///
  /// In en, this message translates to:
  /// **'Applies to all the chosen rooms.'**
  String get appliesToAllRooms;

  /// No description provided for @roomOnlySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings for this room only.'**
  String get roomOnlySettings;

  /// No description provided for @routineSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}} · {when}'**
  String routineSummary(int count, String when);

  /// No description provided for @joinsQueueNoCancel.
  ///
  /// In en, this message translates to:
  /// **'joins the queue without cancelling the current clean'**
  String get joinsQueueNoCancel;

  /// No description provided for @startsNow.
  ///
  /// In en, this message translates to:
  /// **'starts now'**
  String get startsNow;

  /// No description provided for @cleanNow.
  ///
  /// In en, this message translates to:
  /// **'Clean now'**
  String get cleanNow;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get routine;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @weekdaysNarrow.
  ///
  /// In en, this message translates to:
  /// **'M T W T F S S'**
  String get weekdaysNarrow;

  /// No description provided for @atTime.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String atTime(String time);

  /// No description provided for @unscheduled.
  ///
  /// In en, this message translates to:
  /// **'No schedule (manual only)'**
  String get unscheduled;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @changeTime.
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get changeTime;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete routine'**
  String get deleteRoutine;

  /// No description provided for @pickRoomsOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick rooms on the map'**
  String get pickRoomsOnMap;

  /// No description provided for @cleanRooms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Clean 1 room} other{Clean {count} rooms}}'**
  String cleanRooms(int count);

  /// No description provided for @queueRooms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Queue 1 room} other{Queue {count} rooms}}'**
  String queueRooms(int count);

  /// No description provided for @drawZoneOnMap.
  ///
  /// In en, this message translates to:
  /// **'Draw a zone on the map'**
  String get drawZoneOnMap;

  /// No description provided for @cleanZones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Clean 1 zone} other{Clean {count} zones}}'**
  String cleanZones(int count);

  /// No description provided for @queueZones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Queue 1 zone} other{Queue {count} zones}}'**
  String queueZones(int count);

  /// No description provided for @tapPointOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap a point on the map'**
  String get tapPointOnMap;

  /// No description provided for @goHere.
  ///
  /// In en, this message translates to:
  /// **'Go here'**
  String get goHere;

  /// No description provided for @queueWholeHome.
  ///
  /// In en, this message translates to:
  /// **'Queue the whole home'**
  String get queueWholeHome;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @runRoutine.
  ///
  /// In en, this message translates to:
  /// **'Run routine {name}'**
  String runRoutine(String name);

  /// No description provided for @undoLastZone.
  ///
  /// In en, this message translates to:
  /// **'Undo the last zone'**
  String get undoLastZone;

  /// No description provided for @how.
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get how;

  /// No description provided for @saveAsRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save as routine'**
  String get saveAsRoutine;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @settingsOf.
  ///
  /// In en, this message translates to:
  /// **'Settings for {name}'**
  String settingsOf(String name);

  /// No description provided for @consMainBrush.
  ///
  /// In en, this message translates to:
  /// **'Main\nbrush'**
  String get consMainBrush;

  /// No description provided for @consSideBrush.
  ///
  /// In en, this message translates to:
  /// **'Side\nbrush'**
  String get consSideBrush;

  /// No description provided for @consFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get consFilter;

  /// No description provided for @consSensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get consSensors;

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get startsAt;

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get endsAt;

  /// No description provided for @resetPart.
  ///
  /// In en, this message translates to:
  /// **'Reset {name}?'**
  String resetPart(String name);

  /// No description provided for @resetPartSub.
  ///
  /// In en, this message translates to:
  /// **'Do this after replacing or cleaning the part.'**
  String get resetPartSub;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @stateBattery.
  ///
  /// In en, this message translates to:
  /// **'{state} · battery {n}%'**
  String stateBattery(String state, int n);

  /// No description provided for @connectingShort.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingShort;

  /// No description provided for @emptyBin.
  ///
  /// In en, this message translates to:
  /// **'Empty bin'**
  String get emptyBin;

  /// No description provided for @washMop.
  ///
  /// In en, this message translates to:
  /// **'Wash mop'**
  String get washMop;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @editMap.
  ///
  /// In en, this message translates to:
  /// **'Edit map'**
  String get editMap;

  /// No description provided for @editMapSub.
  ///
  /// In en, this message translates to:
  /// **'No-go zones, no-mop zones and virtual walls'**
  String get editMapSub;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @cleanNowShort.
  ///
  /// In en, this message translates to:
  /// **'clean now'**
  String get cleanNowShort;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String hours(int n);

  /// No description provided for @gaugeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a gauge after cleaning or replacing the part.'**
  String get gaugeHint;

  /// No description provided for @currentValue.
  ///
  /// In en, this message translates to:
  /// **'Current ({value})'**
  String currentValue(int value);

  /// No description provided for @doNotDisturb.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb'**
  String get doNotDisturb;

  /// No description provided for @quietAtNight.
  ///
  /// In en, this message translates to:
  /// **'Quiet at night'**
  String get quietAtNight;

  /// No description provided for @quietAtNightSub.
  ///
  /// In en, this message translates to:
  /// **'Does not start cleans or speak'**
  String get quietAtNightSub;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @soundSafety.
  ///
  /// In en, this message translates to:
  /// **'Sound and safety'**
  String get soundSafety;

  /// No description provided for @voiceVolume.
  ///
  /// In en, this message translates to:
  /// **'Voice volume'**
  String get voiceVolume;

  /// No description provided for @childLock.
  ///
  /// In en, this message translates to:
  /// **'Child lock'**
  String get childLock;

  /// No description provided for @childLockSub.
  ///
  /// In en, this message translates to:
  /// **'Disables the buttons on the robot'**
  String get childLockSub;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String durationMin(int m);

  /// No description provided for @durationHourMin.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String durationHourMin(int h, int m);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String yesterdayAt(String time);

  /// No description provided for @dateAt.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String dateAt(DateTime date, String time);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @historySub.
  ///
  /// In en, this message translates to:
  /// **'What the robot did and how long it took'**
  String get historySub;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @cleansUnit.
  ///
  /// In en, this message translates to:
  /// **'cleans'**
  String get cleansUnit;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @in7Days.
  ///
  /// In en, this message translates to:
  /// **'in 7 days'**
  String get in7Days;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @m2In7Days.
  ///
  /// In en, this message translates to:
  /// **'m² in 7 days'**
  String get m2In7Days;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time: {count} cleans · {hours} h · {area} m²'**
  String allTime(int count, int hours, int area);

  /// No description provided for @perRoom.
  ///
  /// In en, this message translates to:
  /// **'Per room'**
  String get perRoom;

  /// No description provided for @perRoomSub.
  ///
  /// In en, this message translates to:
  /// **'Measured by the app during the cleans it followed.'**
  String get perRoomSub;

  /// No description provided for @roomStats.
  ///
  /// In en, this message translates to:
  /// **'{count}× · average {duration}'**
  String roomStats(int count, String duration);

  /// No description provided for @cleans.
  ///
  /// In en, this message translates to:
  /// **'Cleans'**
  String get cleans;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get noRecordsYet;

  /// No description provided for @washes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 wash} other{{count} washes}}'**
  String washes(int count);

  /// No description provided for @obstaclesAvoided.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 obstacle avoided} other{{count} obstacles avoided}}'**
  String obstaclesAvoided(int count);

  /// No description provided for @fasterThanAvg.
  ///
  /// In en, this message translates to:
  /// **'{m} min faster than the average for these rooms'**
  String fasterThanAvg(int m);

  /// No description provided for @slowerThanAvg.
  ///
  /// In en, this message translates to:
  /// **'{m} min slower than the average for these rooms'**
  String slowerThanAvg(int m);

  /// No description provided for @omissionNote.
  ///
  /// In en, this message translates to:
  /// **'The robot flagged areas it could not clean.'**
  String get omissionNote;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @days14.
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get days14;

  /// No description provided for @weeks8.
  ///
  /// In en, this message translates to:
  /// **'8 weeks'**
  String get weeks8;

  /// No description provided for @weekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String weekOf(DateTime date);

  /// No description provided for @shortDate.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String shortDate(DateTime date);

  /// No description provided for @noCleans.
  ///
  /// In en, this message translates to:
  /// **'no cleans'**
  String get noCleans;

  /// No description provided for @activityDetail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 clean} other{{count} cleans}} · {min} min · {area} m²'**
  String activityDetail(int count, int min, String area);

  /// No description provided for @recordMapGone.
  ///
  /// In en, this message translates to:
  /// **'The robot no longer has this clean\'s map. From now on the app keeps each clean\'s map on the phone, so you can always see it.'**
  String get recordMapGone;

  /// No description provided for @toolNoGo.
  ///
  /// In en, this message translates to:
  /// **'No-go'**
  String get toolNoGo;

  /// No description provided for @toolNoGoHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to mark where the robot cannot go. Tap one to delete it.'**
  String get toolNoGoHint;

  /// No description provided for @toolNoMop.
  ///
  /// In en, this message translates to:
  /// **'No mop'**
  String get toolNoMop;

  /// No description provided for @toolNoMopHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to mark where it vacuums but does not mop. Tap one to delete it.'**
  String get toolNoMopHint;

  /// No description provided for @toolWall.
  ///
  /// In en, this message translates to:
  /// **'Wall'**
  String get toolWall;

  /// No description provided for @toolWallHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a line the robot cannot cross. Tap one to delete it.'**
  String get toolWallHint;

  /// No description provided for @saveNotShownYet.
  ///
  /// In en, this message translates to:
  /// **'The robot accepted it, but the map does not show the changes yet. Try again shortly.'**
  String get saveNotShownYet;

  /// No description provided for @restrictions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No restrictions} =1{1 restriction} other{{count} restrictions}}'**
  String restrictions(int count);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @saveToRobot.
  ///
  /// In en, this message translates to:
  /// **'Save to robot'**
  String get saveToRobot;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get noChanges;

  /// No description provided for @errNoRobots.
  ///
  /// In en, this message translates to:
  /// **'This account has no robots.'**
  String get errNoRobots;

  /// No description provided for @loginPitch.
  ///
  /// In en, this message translates to:
  /// **'Everything the official app does, plus what it lacks: a cleaning queue, changes without cancelling, a clear map. Sign in with your Roborock account.'**
  String get loginPitch;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get emailHint;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'code from the email'**
  String get codeHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @tabNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get tabNow;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabRobot.
  ///
  /// In en, this message translates to:
  /// **'Robot'**
  String get tabRobot;

  /// No description provided for @setDryTime.
  ///
  /// In en, this message translates to:
  /// **'Drying time'**
  String get setDryTime;

  /// No description provided for @setWaterTemp.
  ///
  /// In en, this message translates to:
  /// **'Mop wash water'**
  String get setWaterTemp;

  /// No description provided for @tempRoom.
  ///
  /// In en, this message translates to:
  /// **'Room temperature'**
  String get tempRoom;

  /// No description provided for @tempWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get tempWarm;

  /// No description provided for @tempHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get tempHot;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'pt':
      return L10nPt();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
