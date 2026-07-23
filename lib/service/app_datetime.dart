/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/datetime_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:flutter_timezone/flutter_timezone.dart';

// AppDateTime is the single entry point for anything that needs to respect the
// user's timezone display setting (useDeviceLocalTimeZone / universityLocation).
// For pure, settings-agnostic date/time parsing, formatting, or calendar-day
// comparison, use DateTimeUtils / TZDateTimeUtils in utils.dart instead - AppDateTime
// builds on top of those, it does not duplicate them.
//
// Methods on this class fall into three groups (each tagged inline below):
//  1. Raw, single-target conversion primitives (getUtcTimeFromDeviceTime,
//     getDeviceTimeFromUtcTime, getUniLocalTimeFromUtcTime) - building blocks, NOT
//     setting-aware by themselves.
//  2. Setting-aware display API (formatDateTime, getDisplayDay/Time/DateTime,
//     getDateTimeToCompare, getDisplayTZDateTime/getDisplayNowTZDateTime,
//     displayLocation) - branches on useDeviceLocalTimeZone; call these for any
//     setting-respecting display.
//  3. Fixed-zone / local-storage helpers (formatUniLocalTimeFromUtcTime,
//     dateTimeLocalFromJson/ToJson) - deliberately ignore the setting for a narrow,
//     documented reason; not for general display use.
class AppDateTime with Service {

  static const String iso8601DateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  late String _localTimeZone;
  String get localTimeZone => _localTimeZone;

  // Singletone Factory

  static AppDateTime? _instance;

  static AppDateTime? get instance => _instance;
  
  @protected
  static set instance(AppDateTime? value) => _instance = value;

  factory AppDateTime() => _instance ?? (_instance = AppDateTime.internal());

  @protected
  AppDateTime.internal();

  // Service

  @override
  Future<void> initService() async {

    Uint8List? rawData = await timezoneDatabase;
    if (rawData != null) {
      timezone.initializeDatabase(rawData);
    }
    else {
      debugPrint('AppDateTime: Timezone database initializiation omitted.');
    }

    TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    _localTimeZone = timezoneInfo.identifier;
    timezone.Location deviceLocation = timezone.getLocation(_localTimeZone);
    timezone.setLocalLocation(deviceLocation);

    await super.initService();
  }

  // Implementation

  DateTime get now {
    return DateTime.now();
  }

  Future<Uint8List?> get timezoneDatabase async => null;

  String? get universityLocationName  => null;

  timezone.Location? get universityLocation {
    String? locationName = universityLocationName;
    return (locationName != null) ? timezone.getLocation(locationName) : null;
  }

  bool get useDeviceLocalTimeZone => false;

  // Raw building block - always device<->UTC, unconditionally. NOT setting-aware by
  // itself; do not call directly for a setting-respecting display (that exact mistake
  // caused the Poll/InboxMessage/Social bugs this project fixed). Use
  // getDateTimeToCompare / formatDateTime / getDisplayDay / getDisplayTime /
  // getDisplayDateTime instead, which choose the right conversion per the setting.
  DateTime? getUtcTimeFromDeviceTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    DateTime dtUtc = dateTime.toUtc();
    return dtUtc;
  }

  // Raw building block - always UTC->device, unconditionally. Same caveat as
  // getUtcTimeFromDeviceTime above: not setting-aware by itself.
  DateTime? getDeviceTimeFromUtcTime(DateTime? dateTimeUtc) {
    if (dateTimeUtc == null) {
      return null;
    }
    timezone.TZDateTime deviceDateTime = timezone.TZDateTime.from(dateTimeUtc, timezone.local);
    return deviceDateTime;
  }

  // Raw building block - always UTC->university zone, unconditionally. Same caveat as
  // getUtcTimeFromDeviceTime above: not setting-aware by itself.
  DateTime? getUniLocalTimeFromUtcTime(DateTime? dateTimeUtc) {
    timezone.Location? uniLocation = universityLocation;
    if ((dateTimeUtc == null) || (uniLocation == null)) {
      return null;
    }
    timezone.TZDateTime tzDateTimeUni = timezone.TZDateTime.from(dateTimeUtc, uniLocation);
    return tzDateTimeUni;
  }

  // Fixed-zone helper - always university zone, deliberately ignores
  // useDeviceLocalTimeZone. Narrow use only (e.g. Wallet bus pass verification clock,
  // which must always read campus time regardless of the display setting).
  String? formatUniLocalTimeFromUtcTime(DateTime? dateTimeUtc, String? format) {
    if(dateTimeUtc != null && format != null){
      DateTime uniTime = getUniLocalTimeFromUtcTime(dateTimeUtc)!;
      return DateFormat(format).format(uniTime);
    }
    return null;
  }

  // ---- Setting-aware display API from here down: these branch on
  // useDeviceLocalTimeZone (directly, or via getDateTimeToCompare) and are what
  // feature code should call for anything that should follow the user's timezone
  // preference. ----
  String? formatDateTime(DateTime? dateTime,
      {String? format, String? locale, bool? ignoreTimeZone = false, bool showTzSuffix = false}) {
    if (dateTime == null) {
      return null;
    }
    String? formattedDateTime;
    try {
      if (StringUtils.isEmpty(format)) {
        format = iso8601DateTimeFormat;
      }
      DateFormat dateFormat = DateFormat(format, locale);
      if (ignoreTimeZone!) {
          formattedDateTime = dateFormat.format(dateTime);
      } else if (useDeviceLocalTimeZone) {
        DateTime? dt = (dateTime.isUtc) ? getDeviceTimeFromUtcTime(dateTime) : dateTime;
        formattedDateTime = (dt != null) ? dateFormat.format(dt) : null;
      } else {
          timezone.Location? uniLocation = universityLocation;
          timezone.TZDateTime? tzDateTime = (uniLocation != null) ? timezone.TZDateTime.from(dateTime, uniLocation) : null;
          formattedDateTime = (tzDateTime != null) ? dateFormat.format(tzDateTime) : null;
      }
      if (showTzSuffix && (formattedDateTime != null)) {
        formattedDateTime = '$formattedDateTime CT';
      }
    }
    catch (e) {
      debugPrint(e.toString());
    }
    return formattedDateTime;
  }

  // Fixed-zone helpers - always device zone, deliberately ignore the setting. For
  // personal, locally-stored values (e.g. a user-picked reminder date) where "device
  // local" is the correct semantic regardless of the display-timezone preference.
  DateTime? dateTimeLocalFromJson(dynamic json) {
    return getDeviceTimeFromUtcTime(DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json)));
  }

  String? dateTimeLocalToJson(DateTime? dateTime) {
    return DateTimeUtils.utcDateTimeToString(getUtcTimeFromDeviceTime(dateTime));
  }

  String getDisplayDateTime(DateTime dateTimeUtc, {String? format, bool allDay = false, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    if (format != null) {
      DateTime dateTimeToCompare = getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      return formatDateTime(dateTimeToCompare, format: format, ignoreTimeZone: false, showTzSuffix: true) ?? '';
    }
    
    String? timePrefix = getDisplayDay(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime, includeAtSuffix: includeAtSuffix);
    String? timeSuffix = getDisplayTime(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime);
    return '$timePrefix $timeSuffix';
  }

  String? getDisplayDay({DateTime? dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    String? displayDay = '';
    if (dateTimeUtc != null) {
      DateTime dateTimeToCompare = getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      timezone.Location? location = useDeviceLocalTimeZone ? null : universityLocation;

      if (DateTimeUtils.isToday(dateTimeToCompare, location: location)) {
        displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      } else if (DateTimeUtils.isTomorrow(dateTimeToCompare, location: location)) {
        displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      } else if (DateTimeUtils.isYesterday(dateTimeToCompare, location: location)) {
        displayDay = Localization().getStringEx('model.explore.time.yesterday', 'Yesterday');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      } else if (DateTimeUtils.isThisWeek(dateTimeToCompare, location: location)) {
        displayDay = formatDateTime(dateTimeToCompare, format: "EE", ignoreTimeZone: true, showTzSuffix: false);
      } else {
        displayDay = formatDateTime(dateTimeToCompare, format: "MMM dd", ignoreTimeZone: true, showTzSuffix: false);
      }
    }
    return displayDay;
  }

  String? getDisplayTime({DateTime? dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true}) {
    String? timeToString = '';
    if (dateTimeUtc != null && !allDay) {
      DateTime dateTimeToCompare = getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      String format = (dateTimeToCompare.minute == 0) ? 'ha' : 'h:mma';
      timeToString = formatDateTime(dateTimeToCompare, format: format, ignoreTimeZone: true, showTzSuffix: !useDeviceLocalTimeZone);
    }
    return timeToString;
  }

  // The Location the user's chosen setting resolves to for display purposes. Use this
  // when code needs a raw timezone.Location (e.g. to build a TZDateTime directly from
  // epoch millis) rather than a converted DateTime value - for the latter, use
  // getDateTimeToCompare below instead.
  timezone.Location get displayLocation =>
    useDeviceLocalTimeZone ? timezone.local : (universityLocation ?? timezone.local);

  // Canonical conversion entry point: turns a UTC instant into the DateTime the user
  // should see, per the useDeviceLocalTimeZone setting. Any code that needs a raw
  // DateTime value (not just a formatted string) for a setting-aware display should
  // call this instead of getDeviceTimeFromUtcTime/getUniLocalTimeFromUtcTime directly
  // or DateTimeUni/DateTimeLocal, both of which are fixed-zone and ignore the setting.
  DateTime? getDateTimeToCompare({DateTime? dateTimeUtc, bool considerSettingsDisplayTime = true}) {
    if (dateTimeUtc == null) {
      return null;
    }
    DateTime? dateTimeToCompare;
    if (useDeviceLocalTimeZone && considerSettingsDisplayTime) {
      dateTimeToCompare = getDeviceTimeFromUtcTime(dateTimeUtc);
    } else {
      dateTimeToCompare = getUniLocalTimeFromUtcTime(dateTimeUtc);
    }
    return dateTimeToCompare;
  }

  // Same as getDateTimeToCompare, but guaranteed non-null: falls back to device-local
  // zone if the setting-aware conversion can't resolve (e.g. universityLocation not yet
  // configured). Use this when feature display code needs a TZDateTime it can format
  // directly, instead of each caller re-implementing its own "?? some fallback" - that
  // duplication is exactly how the Event2/Survey/Appointment display helpers diverged
  // before being consolidated here.
  timezone.TZDateTime getDisplayTZDateTime(DateTime dateTimeUtc) =>
    (getDateTimeToCompare(dateTimeUtc: dateTimeUtc) as timezone.TZDateTime?) ??
      timezone.TZDateTime.from(dateTimeUtc, timezone.local);

  timezone.TZDateTime getDisplayNowTZDateTime() => getDisplayTZDateTime(now.toUtc());
}

// DateTimeUni / DateTimeLocal are low-level, fixed-zone conversions - each always
// resolves to one specific zone (university location or device local) regardless of
// the useDeviceLocalTimeZone setting. Only use these for genuinely fixed-zone needs
// (e.g. a "now" indicator that must always read the university's local time). For any
// display that should follow the user's timezone setting, call
// AppDateTime().getDateTimeToCompare(...) (or formatDateTime/getDisplayDay/
// getDisplayTime/getDisplayDateTime) instead.
extension DateTimeUni on DateTime {

  timezone.TZDateTime? toUni() => (AppDateTime().universityLocation != null) ? timezone.TZDateTime.from(this, AppDateTime().universityLocation!) : null;
  static timezone.TZDateTime? nowUni() => (AppDateTime().universityLocation != null) ? timezone.TZDateTime.from(DateTime.now(), AppDateTime().universityLocation!) : null;

  timezone.TZDateTime  toUniOrLocal() => timezone.TZDateTime.from(this, timezoneUniOrLocal);
  static timezone.TZDateTime  nowUniOrLocal() => timezone.TZDateTime.from(DateTime.now(), timezoneUniOrLocal);
  static timezone.Location get timezoneUniOrLocal => AppDateTime().universityLocation ?? timezone.local;
}

extension DateTimeLocal on DateTime {

  timezone.TZDateTime  toLocalTZ() => timezone.TZDateTime.from(this.toLocal(), timezoneLocal);
  static timezone.TZDateTime  nowLocalTZ() => timezone.TZDateTime.from(DateTime.now(), timezoneLocal);
  static timezone.Location get timezoneLocal => timezone.local;
}
