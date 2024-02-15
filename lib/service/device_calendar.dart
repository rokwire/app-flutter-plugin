
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/device_calendar.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:collection/collection.dart';

class DeviceCalendar with Service {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  // Singletone Factory
  static DeviceCalendar? _instance;
  static DeviceCalendar? get instance => _instance;

  @protected
  static set instance(DeviceCalendar? value) => _instance = value;

  factory DeviceCalendar() => _instance ?? (_instance = DeviceCalendar.internal());

  @protected
  DeviceCalendar.internal();
  
  // Service

  @override
  Future<void> initService() async {
    await super.initService();
  }

  //@protected
  Future<DeviceCalendarError?> placeCalendarEvent(DeviceCalendarEvent event) async {
    String? eventId = event.internalEventId;
    if (eventId != null) {
      dynamic calendar = await loadCalendar();
      if (calendar is Calendar) {
        Result<String>? createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event.toCalendarEvent(calendar.id));
        if (createEventResult?.isSuccess == true) {
          String? calendarEventId = createEventResult?.data;
          if (calendarEventId != null) {
            return null; // No error
          }
          else {
            return DeviceCalendarError.internal();
          }
        }
        else {
          return DeviceCalendarError.fromResultErrors(createEventResult?.errors ?? <ResultError>[]);
        }
      }
      else {
        return (calendar is DeviceCalendarError) ? calendar : DeviceCalendarError.internal();
      }
    }
    else {
      return DeviceCalendarError.internal();
    }
  }

  @protected
  Future<dynamic> loadCalendar() async {
    // returns Calendar or DeviceCalendarError
    DeviceCalendarError? error = await requestPermissions();
    if (error == null) {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess) {
        List<Calendar>? calendars = calendarsResult.data;
        List<Calendar>? deviceCalendars = ((calendars != null) && calendars.isNotEmpty) ? calendars.where((Calendar calendar) => calendar.isReadOnly == false).toList() : null;
        Calendar? defaultCalendar = ((deviceCalendars != null) && deviceCalendars.isNotEmpty) ? deviceCalendars.firstWhereOrNull((element) => (element.isDefault == true)) : null;
        if (defaultCalendar != null) {
          return defaultCalendar;
        }
        else {
          return DeviceCalendarError.missingCalendar();
        }
      }
      else {
        return DeviceCalendarError.fromResultErrors(calendarsResult.errors);
      }
    }
    else {
      return error;
    }
  }

  @protected
  Future<DeviceCalendarError?> requestPermissions() async {
    Result<bool> permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess) {
      if (permissionsGranted.data == true) {
        return null; // Permission granted
      }
      else {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (permissionsGranted.isSuccess) {
          return (permissionsGranted.data != true) ? DeviceCalendarError.permissionDenied() : null; // Permission granted
        }
        else {
          return DeviceCalendarError.fromResultErrors(permissionsGranted.errors);
        }
      }
    }
    else {
      return DeviceCalendarError.fromResultErrors(permissionsGranted.errors);
    }
  }
}
