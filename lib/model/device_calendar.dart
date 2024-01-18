import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart' as timezone;

class DeviceCalendarEvent {
  String? internalEventId;
  String? title;
  String? deepLinkUrl;
  DateTime? startDate;
  DateTime? endDate;

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
