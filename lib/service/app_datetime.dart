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

class AppDateTime with Service {

  static const String iso8601DateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  late String _localTimeZone;
  String get localTimeZone => _localTimeZone;

  // Singleton Factory

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
      debugPrint('AppDateTime: Timezone database initialization omitted.');
    }

    TimezoneInfo timezoneInfo = await FlutterTimezone.getLocalTimezone();
    _localTimeZone = timezoneInfo.identifier;
    timezone.Location deviceTimezoneLocation = timezone.getLocation(_localTimeZone);
    timezone.setLocalLocation(deviceTimezoneLocation);

    await super.initService();
  }

  // Implementation

  DateTime get now => DateTime.now();

  Future<Uint8List?> get timezoneDatabase async => null;

  String? get universityLocationName  => null;

  timezone.Location? get universityLocation {
    String? locationName = universityLocationName;
    return (locationName != null) ? timezone.getLocation(locationName) : null;
  }

  timezone.Location get deviceLocation => timezone.local;

  timezone.Location get displayLocation =>
      useDeviceLocalTimeZone ? deviceLocation : (universityLocation ?? deviceLocation);

  timezone.Location get universityOrDeviceLocation => universityLocation ?? deviceLocation;

  bool get useDeviceLocalTimeZone => false;

  bool get showTimeZoneSuffix => !useDeviceLocalTimeZone;

  DateTime? getDeviceTimeFromUtc(DateTime? dateTimeUtc) {
    if (dateTimeUtc == null) {
      return null;
    }
    timezone.TZDateTime deviceDateTime = timezone.TZDateTime.from(dateTimeUtc, deviceLocation);
    return deviceDateTime;
  }

  DateTime? getUniversityTimeFromUtc(DateTime? dateTimeUtc) {
    timezone.Location? uniLocation = universityLocation;
    if ((dateTimeUtc == null) || (uniLocation == null)) {
      return null;
    }
    timezone.TZDateTime tzDateTimeUni = timezone.TZDateTime.from(dateTimeUtc, uniLocation);
    return tzDateTimeUni;
  }

  DateTime? getZonedTimeFromUtc({DateTime? dateTimeUtc, bool considerSettingsDisplayTime = true}) {
    if (dateTimeUtc == null) {
      return null;
    }
    DateTime? zonedDateTime;
    if (useDeviceLocalTimeZone && considerSettingsDisplayTime) {
      zonedDateTime = getDeviceTimeFromUtc(dateTimeUtc);
    } else {
      zonedDateTime = getUniversityTimeFromUtc(dateTimeUtc);
    }
    return zonedDateTime;
  }

  DateTime? getDeviceTimeFromJson(dynamic json) => DateTimeUtils.zonedDateTimeFromJson(json, location: deviceLocation);

  timezone.TZDateTime getZonedTZTimeFromUtc(DateTime dateTimeUtc) =>
      (getZonedTimeFromUtc(dateTimeUtc: dateTimeUtc) as timezone.TZDateTime?) ?? timezone.TZDateTime.from(dateTimeUtc, deviceLocation);

  timezone.TZDateTime getZonedNowTZTime() => getZonedTZTimeFromUtc(now.toUtc());

  timezone.TZDateTime getUniversityOrDeviceTZTimeFromUtc(DateTime dateTimeUtc) =>
      (getUniversityTimeFromUtc(dateTimeUtc) as timezone.TZDateTime?) ?? timezone.TZDateTime.from(dateTimeUtc, deviceLocation);

  timezone.TZDateTime getUniversityOrDeviceNowTZTime() => getUniversityOrDeviceTZTimeFromUtc(now.toUtc());

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
        DateTime? dt = (dateTime.isUtc) ? getDeviceTimeFromUtc(dateTime) : dateTime;
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

  String formatDisplayDateTime(DateTime dateTimeUtc, {String? format, bool allDay = false, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    if (format != null) {
      DateTime zonedDateTime = getZonedTimeFromUtc(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      return formatDateTime(zonedDateTime, format: format, ignoreTimeZone: false, showTzSuffix: true) ?? '';
    }
    
    String? timePrefix = formatDisplayDay(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime, includeAtSuffix: includeAtSuffix);
    String? timeSuffix = formatDisplayTime(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime);
    return '$timePrefix $timeSuffix';
  }

  String? formatDisplayDay({DateTime? dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    String? displayDay = '';
    if (dateTimeUtc != null) {
      DateTime zonedDateTime = getZonedTimeFromUtc(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      timezone.Location? location = useDeviceLocalTimeZone ? null : universityLocation;

      if (DateTimeUtils.isToday(zonedDateTime, location: location)) {
        displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      } else if (DateTimeUtils.isTomorrow(zonedDateTime, location: location)) {
        displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      } else if (DateTimeUtils.isYesterday(zonedDateTime, location: location)) {
        displayDay = Localization().getStringEx('model.explore.time.yesterday', 'Yesterday');
        if (!allDay && includeAtSuffix) {
          displayDay += " ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      } else if (DateTimeUtils.isThisWeek(zonedDateTime, location: location)) {
        displayDay = formatDateTime(zonedDateTime, format: "EE", ignoreTimeZone: true, showTzSuffix: false);
      } else {
        displayDay = formatDateTime(zonedDateTime, format: "MMM dd", ignoreTimeZone: true, showTzSuffix: false);
      }
    }
    return displayDay;
  }

  String? formatDisplayTime({DateTime? dateTimeUtc, bool allDay = false, bool considerSettingsDisplayTime = true}) {
    String? timeToString = '';
    if (dateTimeUtc != null && !allDay) {
      DateTime zonedDateTime = getZonedTimeFromUtc(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      String format = (zonedDateTime.minute == 0) ? 'ha' : 'h:mma';
      timeToString = formatDateTime(zonedDateTime, format: format, ignoreTimeZone: true, showTzSuffix: showTimeZoneSuffix);
    }
    return timeToString;
  }
}
