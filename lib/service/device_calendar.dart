
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/device_calendar.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:collection/collection.dart';

class DeviceCalendar with Service {
  Calendar? _defaultCalendar;
  List<Calendar>? _deviceCalendars;
  Calendar? _selectedCalendar;
  Map<String, String>? _calendarEventIdTable;
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

  // Implementation

  Calendar? get defaultCalendar => _defaultCalendar;
  List<Calendar>? get deviceCalendars => _deviceCalendars;
  Calendar? get selectedCalendar => _selectedCalendar;
  Map<String, String>? get calendarEventIdTable => _calendarEventIdTable;
  DeviceCalendarPlugin get deviceCalendarPlugin => _deviceCalendarPlugin;

  //@protected
  Future<bool> placeCalendarEvent(DeviceCalendarEvent? event) async {
    if (event == null) {
      return false;
    }

    //init check
    bool initResult = await loadDefaultCalendarIfNeeded();
    if(!initResult){
      debugPrint("Unable to init plugin");
      return false;
    }

    debugPrint("Add to calendar- id:${calendar?.id}, name:${calendar?.name}, accountName:${calendar?.accountName}, accountType:${calendar?.accountType}, isReadOnly:${calendar?.isReadOnly}, isDefault:${calendar?.isDefault},");
    //PLACE
    if(calendar != null) {
      Result<String>? createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event.toCalendarEvent(calendar?.id));
      if (createEventResult?.data!=null) {
        storeEventId(event.internalEventId, createEventResult?.data);
      }

      debugPrint("result.data: ${createEventResult?.data}, result?.errors?.toString(): ${createEventResult?.errors.toString()}");

      if((createEventResult == null) || !createEventResult.isSuccess) {
        debugPrint('failed to create/update event: ${createEventResult?.errors.toString()}');
        return false;
      }
      else{
        debugPrint("added");
        return true;
      }
    } else {
      debugPrint("calendar is missing");
      return false;
    }
  }

  Future<bool> deleteEvent(DeviceCalendarEvent? event) async {
    if (event == null) {
      return false;
    }

    //init check
    bool initResult = await loadDefaultCalendarIfNeeded();
    if (!initResult) {
      debugPrint("Unable to init plugin");
      return false;
    }

    String? eventId = event.internalEventId != null && _calendarEventIdTable!= null ? _calendarEventIdTable![event.internalEventId] : null;
    debugPrint("Try delete eventId: ${event.internalEventId} stored with calendarId: $eventId from calendarId ${calendar!.id}");
    if (StringUtils.isEmpty(eventId)) {
      return false;
    }

    final deleteEventResult = await _deviceCalendarPlugin.deleteEvent(calendar?.id, eventId);
    debugPrint("delete result.data: ${deleteEventResult.data}, result.error: ${deleteEventResult.errors.toString()}");
    if (deleteEventResult.isSuccess) {
      eraseEventId(event.internalEventId);
    }
    return deleteEventResult.isSuccess;
  }

  //@protected
  Future<bool> loadDefaultCalendarIfNeeded() async{
    return (calendar == null) ? await loadCalendars() : true;
  }

  @protected
  Future<bool> loadCalendars() async {
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      debugPrint("No Calendar permissions");
      return false;
    }
    
    debugPrint("Has permissions");
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    List<Calendar>? calendars = calendarsResult.data;
    _deviceCalendars = calendars!=null && calendars.isNotEmpty? calendars.where((Calendar calendar) => calendar.isReadOnly == false).toList() : null;
    if(CollectionUtils.isNotEmpty(_deviceCalendars)) {
      _defaultCalendar = _deviceCalendars!.firstWhereOrNull((element) => (element.isDefault == true));
      return true;
    }
    debugPrint("No Calendars");
    return false;
  }

  Future<List<Calendar>?> refreshCalendars() async {
    await loadCalendars();
    return _deviceCalendars;
  }

  
  @protected
  Future<bool> requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return false;
      }
    }

    return true;
  }

  @protected
  void storeEventId(String? eventId, String? calendarEventId) {
    if ((_calendarEventIdTable != null) && (eventId != null) && (calendarEventId != null)) {
      _calendarEventIdTable![eventId] = calendarEventId;
      Storage().calendarEventsTable = _calendarEventIdTable;
    }
  }
  
  @protected
  void eraseEventId(String? id) {
    if (_calendarEventIdTable != null) {
      _calendarEventIdTable!.remove(id);
      Storage().calendarEventsTable = _calendarEventIdTable;
    }
  }

  bool get canAddToCalendar =>
    Storage().calendarEnabledToSave;

  bool get shouldPrompt =>
    Storage().calendarShouldPrompt;

  bool get shouldAutoSave =>
    Storage().calendarEnabledToAutoSave;

  Calendar? get calendar =>
    _selectedCalendar ?? _defaultCalendar;

  set calendar(Calendar? calendar) =>
    _selectedCalendar = calendar;
}
