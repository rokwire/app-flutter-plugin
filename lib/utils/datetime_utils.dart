/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart' as timezone;

class DateTimeUtils {

  static const String iso8601DateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  static DateTime? dateTimeFromString(String? dateTimeString, {String? format, bool isUtc = false}) {
    if (StringUtils.isEmpty(dateTimeString)) {
      return null;
    }
    DateTime? dateTime;
    try {
      dateTime = StringUtils.isNotEmpty(format) ?
        DateFormat(format).parse(dateTimeString!, isUtc) :
        DateTime.tryParse(dateTimeString!);
    }
    on Exception catch (e) {
      debugPrint(e.toString());
    }
    return dateTime;
  }

  static DateTime? zonedDateTimeFromJson(dynamic json, {timezone.Location? location}) {
    DateTime? parsedDateTime = dateTimeFromString(JsonUtils.stringValue(json));
    if ((parsedDateTime == null) || (location == null)) {
      return parsedDateTime;
    }
    return timezone.TZDateTime.from(parsedDateTime, location);
  }

  static String? dateTimeToString(DateTime? dateTime, {String format = iso8601DateTimeFormat, String? timeZoneSuffix}) {
    if (dateTime == null) {
      return null;
    }
    String formattedDateTime = DateFormat(format).format(dateTime);
    if (StringUtils.isNotEmpty(timeZoneSuffix)) {
      formattedDateTime = '$formattedDateTime $timeZoneSuffix';
    }
    return formattedDateTime;
  }

  static String? utcDateTimeToString(DateTime? dateTime, { String format  = 'yyyy-MM-ddTHH:mm:ss.SSS'  }) {
    return (dateTime != null) ? (DateFormat(format).format(dateTime.isUtc ? dateTime : dateTime.toUtc()) + 'Z') : null;
  }

  static String? localDateTimeToString(DateTime? dateTime, { String format  = 'yyyy-MM-ddTHH:mm:ss.SSS'  }) {
    return (dateTime != null) ? (DateFormat(format).format(dateTime.toLocal())) : null;
  }

  static String? localDateTimeFileStampToString(DateTime? dateTime, { String format  = 'yyyy-MM-ddTHH_mm_ss.SSS'  }) {
    return (dateTime != null) ? (DateFormat(format).format(dateTime.toLocal())) : null;
  }

  static String? utcTimeToString(DateTime? dateTimeUtc, timezone.Location location, {String? timeZoneSuffix}) {
    DateTime? dateTime = TZDateTimeUtils.copyFromDateTime(dateTimeUtc, location);
    if (dateTime == null) {
      return null;
    }

    String format = (dateTime.minute == 0) ? 'ha' : 'h:mma';
    String formattedTime = DateFormat(format).format(dateTime);
    if (StringUtils.isNotEmpty(timeZoneSuffix)) {
      formattedTime = '$formattedTime $timeZoneSuffix';
    }
    return formattedTime;
  }

  static DateTime? dateTimeFromSecondsSinceEpoch(int? seconds, {bool isUtc = false}) =>
    (seconds != null) ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: isUtc) : null;

  static int? dateTimeToSecondsSinceEpoch(DateTime? dateTime) =>
    (dateTime != null) ? (dateTime.millisecondsSinceEpoch ~/ 1000) : null;


  static DayPart getDayPart({DateTime? dateTime}) {
    int hour = (dateTime ?? DateTime.now()).hour;
    if (hour < 6) {
      return DayPart.night;
    }
    else if ((6 <= hour) && (hour < 12)) {
      return DayPart.morning;
    }
    else if ((12 <= hour) && (hour < 17)) {
      return DayPart.afternoon;
    }
    else if ((17 <= hour) && (hour < 20)) {
      return DayPart.evening;
    }
    else /* if (20 <= hour) */ {
      return DayPart.night;
    }
  }

  static String? dayPartToString(DayPart? dayPart) {
    switch(dayPart) {
      case DayPart.morning: return "morning";
      case DayPart.afternoon: return "afternoon";
      case DayPart.evening: return "evening";
      case DayPart.night: return "night";
      default: return null;
    }
  }

  static DateTime? midnight(DateTime? date) {
    return (date != null) ? DateTime(date.year, date.month, date.day) : null;
  }

  static DateTime nowTimezone(timezone.Location? location) {
    DateTime now = DateTime.now();
    if (location != null) {
      return timezone.TZDateTime.from(now, location);
    }
    return now;
  }

  static bool isToday(DateTime? date, {timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    DateTime now = nowTimezone(location);
    return now.day == date.day && now.month == date.month && now.year == date.year;
  }

  static bool isYesterday(DateTime? date, {timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    DateTime yesterday = nowTimezone(location).subtract(const Duration(days: 1));
    return yesterday.day == date.day && yesterday.month == date.month && yesterday.year == date.year;
  }

  static bool isTomorrow(DateTime? date, {timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    DateTime tomorrow = nowTimezone(location).add(const Duration(days: 1));
    return tomorrow.day == date.day && tomorrow.month == date.month && tomorrow.year == date.year;
  }

  static bool isThisWeek(DateTime? date, {timezone.Location? location}) {
    if (date == null) {
      return false;
    }
    if (date.isAfter(weekStart(location: location)) && date.isBefore(weekEnd(location: location))) {
      return true;
    }
    return false;
  }

  static DateTime weekStart({timezone.Location? location}) {
    DateTime now = nowTimezone(location);
    return now.subtract(Duration(days: now.weekday - 1));
  }

  static DateTime weekEnd({timezone.Location? location}) {
    return weekStart(location: location).add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
  }

  static timezone.TZDateTime? changeTimeZoneToDate(DateTime time, timezone.Location location) {
    try{
     return timezone.TZDateTime(location,time.year,time.month,time.day, time.hour, time.minute);
    } catch(e){
      debugPrint(e.toString());
    }
    return null;
  }

  static DateTime copyDateTime(DateTime date){
    return DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second);
  }

  static DateTime min(DateTime v1, DateTime v2) => (v1.isBefore(v2)) ? v1 : v2;
  static DateTime max(DateTime v1, DateTime v2) => (v1.isAfter(v2)) ? v1 : v2;
}

enum DayPart { morning, afternoon, evening, night }

class TZDateTimeUtils {
  static timezone.TZDateTime dateOnly(timezone.TZDateTime dateTime, { timezone.Location? location, bool inclusive = false }) =>
    dateTime.dateOnly(location: location, inclusive: inclusive);

  static timezone.TZDateTime startOfNextMonth(timezone.TZDateTime dateTime, { timezone.Location? location }) =>
    dateTime.startOfNextMonth(location: location);

  static timezone.TZDateTime endOfThisMonth(timezone.TZDateTime dateTime, { timezone.Location? location }) =>
    dateTime.endOfThisMonth(location: location);

  static timezone.TZDateTime? copyFromDateTime(DateTime? time, timezone.Location location) =>
    (time != null) ? timezone.TZDateTime.from(time, location) : null;

  static timezone.TZDateTime max(timezone.TZDateTime v1, timezone.TZDateTime v2) => (v1.isAfter(v2)) ? v1 : v2;
}

extension TZDateTimeExt on timezone.TZDateTime {
  timezone.TZDateTime dateOnly({ timezone.Location? location, bool inclusive = false }) =>
    timezone.TZDateTime(location ?? this.location, year, month, day, inclusive ? 23 : 0, inclusive ? 59 : 0, inclusive ? 59 : 0);

  timezone.TZDateTime startOfNextMonth({ timezone.Location? location }) => (month < 12) ?
    timezone.TZDateTime(location ?? this.location, year, month + 1, 1) :
    timezone.TZDateTime(location ?? this.location, year + 1, 1, 1);

  timezone.TZDateTime endOfThisMonth({ timezone.Location? location }) =>
    startOfNextMonth(location: location).subtract(const Duration(days: 1)).dateOnly(inclusive: true);

  toJson() => {
    'location': location.name,
    'timestamp': millisecondsSinceEpoch
  };

  static timezone.TZDateTime? fromJson(dynamic json) {
    if (json is Map) {
      String? locationName = JsonUtils.stringValue(json['location']);
      timezone.Location? location = (locationName != null) ? timezone.getLocation(locationName) : null;
      int? timestamp = JsonUtils.intValue(json['timestamp']);
      if ((location != null) && (timestamp != null)) {
        return timezone.TZDateTime.fromMillisecondsSinceEpoch(location, timestamp);
      }
    }
    return null;
  }
}
