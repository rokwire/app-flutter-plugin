import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart' as timezone;

class DeviceCalendarEvent {
  final String? internalEventId;
  final String? title;
  final String? deepLinkUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  DeviceCalendarEvent({this.internalEventId, this.title, this.deepLinkUrl, this.startDate, this.endDate});

  device_calendar.Event toCalendarEvent(String? calendarId){
    device_calendar.Event calendarEvent = device_calendar.Event(calendarId);
    calendarEvent.title = title ?? "";

    if (startDate != null) {
      calendarEvent.start = timezone.TZDateTime.from(startDate!, AppDateTime().universityLocation!);
    }

    if (endDate != null) {
      calendarEvent.end = timezone.TZDateTime.from(endDate!, AppDateTime().universityLocation!);
    } else if (startDate != null) {
      calendarEvent.end = timezone.TZDateTime(AppDateTime().universityLocation!, startDate!.year, startDate!.month, startDate!.day, 24);
    }

    String? redirectUrl = Config().deepLinkRedirectUrl;
    calendarEvent.description = StringUtils.isNotEmpty(redirectUrl) ? "$redirectUrl?target=$deepLinkUrl" : deepLinkUrl;

    return calendarEvent;
  }
}

class DeviceCalendarError {
  final int code;
  final String? message;

  DeviceCalendarError(this.code, { this.message });

  factory DeviceCalendarError.fromResultError(device_calendar.ResultError resultError) =>
    DeviceCalendarError(resultError.errorCode, message: resultError.errorMessage);

  factory DeviceCalendarError.fromResultErrors(List<device_calendar.ResultError> resultErrors, { int code = DeviceCalendarErrorCodes.internal, String? message }) =>
    resultErrors.isNotEmpty ? DeviceCalendarError.fromResultError(resultErrors.first) : DeviceCalendarError(code, message: message);

  factory DeviceCalendarError.internal({ String? message }) =>
    DeviceCalendarError(DeviceCalendarErrorCodes.internal, message: message);

  factory DeviceCalendarError.permissionDenied({ String? message }) =>
    DeviceCalendarError(DeviceCalendarErrorCodes.permissionDenied, message: message);

  factory DeviceCalendarError.missingCalendar({ String? message }) =>
    DeviceCalendarError(DeviceCalendarErrorCodes.missingCalendar, message: message);
}

class DeviceCalendarErrorCodes {
  static const int internal = 1001;
  static const int permissionDenied = 1002;
  static const int missingCalendar = 1003;
}

