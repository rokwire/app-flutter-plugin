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
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class AppDateTime with Service {

  static const String iso8601DateTimeFormat = 'yyyy-MM-ddTHH:mm:ss';

  String? _localTimeZone;
  String? get localTimeZone => _localTimeZone;

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
    if (_localTimeZone != null) {
      timezone.Location deviceLocation = timezone.getLocation(_localTimeZone!);
      timezone.setLocalLocation(deviceLocation);
    }
    else {
      debugPrint('AppDateTime: Failed to retrieve local timezone.');
    }

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
      if (ignoreTimeZone! || useDeviceLocalTimeZone) {
          formattedDateTime = dateFormat.format(dateTime);
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
}