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
import 'package:rokwire_plugin/utils/datetime_utils.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:flutter_timezone/flutter_timezone.dart';

class AppDateTime with Service {

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


  @protected
  Future<Uint8List?> get timezoneDatabase async => null;

  @protected
  String? get universityLocationName => null;

  String? get timeZoneSuffix => null;

  timezone.Location? get universityLocation {
    String? locationName = universityLocationName;
    return (locationName != null) ? timezone.getLocation(locationName) : null;
  }

  timezone.Location get deviceLocation => timezone.local;

  timezone.Location get zonedLocation =>
      useUniversityTimeZone ? (universityLocation ?? deviceLocation) : deviceLocation;

  timezone.Location get universityOrDeviceLocation => universityLocation ?? deviceLocation;

  bool get useUniversityTimeZone => false;

  bool get showTimeZoneSuffix => useUniversityTimeZone;

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

  DateTime? getZonedTimeFromUtc({DateTime? dateTimeUtc}) {
    if (dateTimeUtc == null) {
      return null;
    }
    DateTime? zonedDateTime;
    if (useUniversityTimeZone) {
      zonedDateTime = getUniversityTimeFromUtc(dateTimeUtc);
    } else {
      zonedDateTime = getDeviceTimeFromUtc(dateTimeUtc);
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
}
