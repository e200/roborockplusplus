import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show BuildContext;

import 'l10n.dart';

export 'l10n.dart';

/// Strings for code without a widget tree (the background service, notifications): the phone's language if
/// supported, English otherwise.
L10n deviceStrings() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  final supported = L10n.supportedLocales.any((l) => l.languageCode == code);
  return lookupL10n(Locale(supported ? code : 'en'));
}

extension L10nContext on BuildContext {
  L10n get l => L10n.of(this);
}
