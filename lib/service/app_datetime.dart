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
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

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

    _localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    timezone.Location deviceLocation = timezone.getLocation(_localTimeZone);
    timezone.setLocalLocation(deviceLocation);

    await super.initService();
  }

  // Implementation

  DateTime get now {
    return DateTime.now();
  }

  @protected
  Future<Uint8List?> get timezoneDatabase async {
    ByteData? byteData = await AppBundle.loadBytes('packages/rokwire_plugin/assets/timezone.tzf');
    return byteData?.buffer.asUint8List();
  }

  String? get universityLocationName  => Config().timezoneLocation;

  timezone.Location? get universityLocation {
    String? locationName = universityLocationName;
    return (locationName != null) ? timezone.getLocation(locationName) : null;
  }

  bool get useDeviceLocalTimeZone => true;

  DateTime? getUtcTimeFromDeviceTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    DateTime dtUtc = dateTime.toUtc();
    return dtUtc;
  }

  DateTime? getDeviceTimeFromUtcTime(DateTime? dateTimeUtc) {
    if (dateTimeUtc == null) {
      return null;
    }
    timezone.TZDateTime deviceDateTime = timezone.TZDateTime.from(dateTimeUtc, timezone.local);
    return deviceDateTime;
  }

  DateTime? getUniLocalTimeFromUtcTime(DateTime? dateTimeUtc) {
    timezone.Location? uniLocation = universityLocation;
    if ((dateTimeUtc == null) || (uniLocation == null)) {
      return null;
    }
    timezone.TZDateTime tzDateTimeUni = timezone.TZDateTime.from(dateTimeUtc, uniLocation);
    return tzDateTimeUni;
  }

  String? formatUniLocalTimeFromUtcTime(DateTime? dateTimeUtc, String? format) {
    if(dateTimeUtc != null && format != null){
      DateTime uniTime = getUniLocalTimeFromUtcTime(dateTimeUtc)!;
      return DateFormat(format).format(uniTime);
    }
    return null;
  }

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
      formattedDateTime = formattedDateTime?.toLowerCase();
      if (showTzSuffix && (formattedDateTime != null)) {
        formattedDateTime = '$formattedDateTime CT';
      }
    }
    catch (e) {
      debugPrint(e.toString());
    }
    return formattedDateTime != null ? StringUtils.capitalize(formattedDateTime) : null;
  }

  DateTime? dateTimeLocalFromJson(dynamic json) {
    return getDeviceTimeFromUtcTime(DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json)));
  }

  String? dateTimeLocalToJson(DateTime? dateTime) {
    return DateTimeUtils.utcDateTimeToString(getUtcTimeFromDeviceTime(dateTime));
  }

  String getDisplayDateTime(DateTime? dateTimeUtc, {String? format, bool allDay = false, bool includeToday = true, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false, bool multiLine = false}) {
    if (dateTimeUtc == null) {
      return '';
    }
    if (format != null) {
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      return formatDateTime(dateTimeToCompare, format: format, ignoreTimeZone: false, showTzSuffix: true) ?? '';
    }
    
    String? timePrefix = getDisplayDay(dateTimeUtc: dateTimeUtc, allDay: allDay, includeToday: includeToday, considerSettingsDisplayTime: considerSettingsDisplayTime, includeAtSuffix: includeAtSuffix);
    String? timeSuffix = getDisplayTime(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime);
    if (timePrefix == null) {
      return timeSuffix ?? '';
    }
    return '$timePrefix,${multiLine ? '\n' : ' '}$timeSuffix';
  }

  String? getDisplayDay({DateTime? dateTimeUtc, bool allDay = false, bool includeToday = true, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    String? displayDay = '';
    if (dateTimeUtc != null) {
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      timezone.Location? location = useDeviceLocalTimeZone ? null : universityLocation;

      if (DateTimeUtils.isToday(dateTimeToCompare, location: location)) {
        if (!includeToday) {
          return null;
        }
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
        displayDay = formatDateTime(dateTimeToCompare, format: "MMM d", ignoreTimeZone: true, showTzSuffix: false);
      }
    }
    return displayDay;
  }

  String? getDisplayTime({DateTime? dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true}) {
    String? timeToString = '';
    if (dateTimeUtc != null && !allDay) {
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      String format = (dateTimeToCompare.minute == 0) ? 'h a' : 'h:mm a';
      timeToString = formatDateTime(dateTimeToCompare, format: format, ignoreTimeZone: true, showTzSuffix: !useDeviceLocalTimeZone);
    }
    return timeToString;
  }

  String getRelativeDisplayTime(DateTime time) {
    Duration difference = DateTime.now().difference(time);

    String suffix = Localization().getStringEx('model.explore.date_time.ago', ' ago');
    if (difference.inSeconds < 0) {
      difference *= -1;
      suffix = Localization().getStringEx('model.explore.date_time.left', ' left');
    }

    if (difference.inSeconds < 60) {
      return Localization().getStringEx('model.explore.date_time.now', 'just now');
    }
    else if (difference.inMinutes < 60) {
      return difference.inMinutes.toString() +
          Localization().getStringEx('model.explore.date_time.minutes', 'm') + suffix;
    }
    else if (difference.inHours < 24) {
      return difference.inHours.toString() +
          Localization().getStringEx('model.explore.date_time.hours', 'h') + suffix;
    }
    else if (difference.inDays < 30) {
      return difference.inDays.toString() +
          Localization().getStringEx('model.explore.date_time.days', 'd') + suffix;
    }
    else {
      int differenceInMonths = difference.inDays ~/ 30;
      if (differenceInMonths < 12) {
        return differenceInMonths.toString() +
            Localization().getStringEx('model.explore.date_time.months', 'mo') + suffix;
      } else {
        int differenceInYears = difference.inDays ~/ 360;
        return differenceInYears.toString() +
            Localization().getStringEx('model.explore.date_time.years', 'y') + suffix;
      }
    }
    // return DateFormat("MMM dd, yyyy").format(deviceDateTime);
  }

  DateTime? _getDateTimeToCompare({DateTime? dateTimeUtc, bool considerSettingsDisplayTime = true}) {
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
}

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
