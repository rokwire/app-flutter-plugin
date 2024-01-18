
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/device_calendar.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:collection/collection.dart';

class DeviceCalendar with Service {
  late Map<String, String> _calendarEventIdTable;
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
    _calendarEventIdTable = Storage().calendarEventsTable ?? {};
    await super.initService();
  }

  //@protected
  Future<DeviceCalendarError?> placeCalendarEvent(DeviceCalendarEvent event) async {
    String? eventId = event.internalEventId;
    if (eventId != null) {
      dynamic calendar = loadCalendar();
      if (calendar is Calendar) {
        Result<String>? createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event.toCalendarEvent(calendar.id));
        if (createEventResult?.isSuccess == true) {
          String? calendarEventId = createEventResult?.data;
          if (calendarEventId != null) {
            storeEventId(eventId, calendarEventId);
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

  Future<DeviceCalendarError?> removeCalendarEvent(DeviceCalendarEvent event) async {
    String? calendarEventId = _calendarEventIdTable[event.internalEventId];
    if (calendarEventId != null) {
      dynamic calendar = loadCalendar();
      if (calendar is Calendar) {
        Result<bool> deleteEventResult = await _deviceCalendarPlugin.deleteEvent(calendar.id, calendarEventId);
        if (deleteEventResult.isSuccess == true) {
          eraseEventId(event.internalEventId);
          return null; // No error
        }
        else {
          return DeviceCalendarError.fromResultErrors(deleteEventResult.errors);
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
          return (permissionsGranted.data == true) ? DeviceCalendarError.permissionDenied() : null; // Permission granted
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

  @protected
  void storeEventId(String eventId, String calendarEventId) {
    _calendarEventIdTable[eventId] = calendarEventId;
    Storage().calendarEventsTable = _calendarEventIdTable;
  }
  
  @protected
  void eraseEventId(String? eventId) {
    if (eventId != null) {
      _calendarEventIdTable.remove(eventId);
      Storage().calendarEventsTable = _calendarEventIdTable;
    }
  }

  bool get canAddToCalendar =>
    Storage().calendarEnabledToSave;

  bool get shouldPrompt =>
    Storage().calendarShouldPrompt;

  bool get shouldAutoSave =>
    Storage().calendarEnabledToAutoSave;
}
