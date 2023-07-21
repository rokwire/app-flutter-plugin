
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Events2 with Service implements NotificationsListener {

  static const String notifyLaunchDetail  = "edu.illinois.rokwire.event2.launch_detail";
  static const String notifyChanged  = "edu.illinois.rokwire.event2.changed";

  List<Map<String, dynamic>>? _eventDetailsCache;
  final bool _useAttendShortcuts = false;

  // Singletone Factory

  static Events2? _instance;

  factory Events2() => _instance ?? (_instance = Events2.internal());

  @protected
  static set instance(Events2? value) => _instance = value;

  @protected
  Events2.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      DeepLink.notifyUri,
    ]);
    _eventDetailsCache = [];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  void initServiceUI() {
    processCachedEventDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      onDeepLinkUri(param);
    }
  }

  // Content Attributes

  ContentAttributes? get contentAttributes => Content().contentAttributes('events');


  // Implementation

  Future<Events2ListResult?> loadEvents(Events2Query? query, {Client? client}) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/events/load";
      String? body = JsonUtils.encode(query?.toQueryJson());
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, client: client, auth: Auth2());
      //TMP: debugPrint("$body => ${response?.statusCode} ${response?.body}", wrapWidth: 256);
      return Events2ListResult.fromResponseJson(JsonUtils.decode((response?.statusCode == 200) ? response?.body : null));
    }
    return null;
  }

  Future<List<Event2>?> loadEventsList(Events2Query? query) async =>
    (await loadEvents(query))?.events;

  Future<Event2?> loadEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/events/load";
      String? body = JsonUtils.encode({"ids":[eventId]});
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      List<Event2>? resultList = Events2ListResult.listFromResponseJson(JsonUtils.decode((response?.statusCode == 200) ? response?.body : null));
      return ((resultList != null) && resultList.isNotEmpty) ? resultList.first : null;
    }
    return null;
  }

  // Returns Event2 in case of success, String description in case of error
  Future<dynamic> createEvent(Event2 source) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event";
      String? body = JsonUtils.encode(source.toJson());
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return Event2.fromJson(JsonUtils.decodeMap(response?.body));
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  // Returns Event2 in case of success, String description in case of error
  Future<dynamic> updateEvent(Event2 source) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/${source.id}";
      String? body = JsonUtils.encode(source.toJson());
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return Event2.fromJson(JsonUtils.decodeMap(response?.body));
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  // Returns error message, true if successful
  Future<dynamic> deleteEvent(String eventId) async{
    if (Config().calendarUrl != null) { //TBD this is deprecated API. Hook to the new one when available
      String url = "${Config().calendarUrl}/event/$eventId";
      Response? response = await Network().delete(url, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return true;
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  // Returns error message, Event2 if successful
  Future<dynamic> updateEventRegistrationDetails(String eventId, Event2RegistrationDetails? registrationDetails) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/registration";
      String? body = JsonUtils.encode({ 'registration_details' : registrationDetails?.toJson()});
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      return (response?.statusCode == 200) ? Event2.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
    }
    return null;
  }
  
  // Returns error message, Event2 if successful
  Future<dynamic> updateEventAttendanceDetails(String eventId, Event2AttendanceDetails? attendanceDetails) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/attendance";
      String? body = JsonUtils.encode({ 'attendance_details' : attendanceDetails?.toJson()});
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      return (response?.statusCode == 200) ? Event2.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
    }
    return null;
  }

  // Returns error message, true if successful
  Future<dynamic> registerToEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event-person/register";
      String? body = JsonUtils.encode({'event_id': eventId,});
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      return (response?.statusCode == 200) ? true : response?.errorText;
    }
    return null;
  }

  // Returns error message, true if successful
  Future<dynamic> unregisterFromEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event-person/unregister/$eventId";
      Response? response = await Network().delete(url, headers: _jsonHeaders, auth: Auth2());
      return (response?.statusCode == 200) ? true : response?.errorText;
    }
    return null;
  }

  // Returns error message, Event2PersonsResult if successful
  Future<dynamic> loadEventPeople(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/users";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Event2PersonsResult.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
    }
    return null;
  }

  // Returns error message, Event2Person if successful
  Future<dynamic> attendEvent(String eventId, { Event2PersonIdentifier? personIdentifier, String? uin }) async {

    if (!_useAttendShortcuts) {
      if (Config().calendarUrl != null) {
        Map<String, dynamic>? postData;
        if (personIdentifier != null) {
          postData = {'identifier': personIdentifier.toJson()};
        }
        else if (uin != null) {
          postData = {'uin': uin };
        }
        if (postData != null) {
          String url = "${Config().calendarUrl}/event/$eventId/attendees";
          String? body = JsonUtils.encode(postData);

          Response? response = await Network().put(url, headers: _jsonHeaders, body: body, auth: Auth2());
          return (response?.statusCode == 200) ? Event2Person.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
        }
      }
      return null;
    }
    else {
      await Future.delayed(const Duration(seconds: 1));
      
      if (personIdentifier != null) {
        return Event2Person(
          identifier: personIdentifier,
          time: DateTime.now().millisecondsSinceEpoch * 1000,
        );
      }
      else if (uin != null) {
        return Event2Person(
          identifier: Event2PersonIdentifier(exteralId: uin),
          time: DateTime.now().millisecondsSinceEpoch * 1000,
        );
      }
      else {
        return 'Internal error occured';
      }
    }
  }

  // Returns error message, true if successful
  Future<dynamic> unattendEvent(String eventId, { Event2PersonIdentifier? personIdentifier }) async {
    if (!_useAttendShortcuts) {
      if (Config().calendarUrl != null) {
        String url = "${Config().calendarUrl}/event/$eventId/attendees";
        String? body = JsonUtils.encode({'identifier': personIdentifier?.toJson()});

        Response? response = await Network().delete(url, headers: _jsonHeaders, body: body, auth: Auth2());
        return (response?.statusCode == 200) ? true : response?.errorText;
      }
      return null;
    }
    else {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
  }

  // Helpers

  Map<String, String?> get _jsonHeaders => {"Accept": "application/json", "Content-type": "application/json"};

  // DeepLinks

  String get eventDetailUrl => '${DeepLink().appUrl}/event2_detail'; //TBD: => event_detail

  @protected
  void onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? eventUri = Uri.tryParse(eventDetailUrl);
      if ((eventUri != null) &&
          (eventUri.scheme == uri.scheme) &&
          (eventUri.authority == uri.authority) &&
          (eventUri.path == uri.path))
      {
        try { handleEventDetail(uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { debugPrint(e.toString()); }
      }
    }
  }

  @protected
  void handleEventDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_eventDetailsCache != null) {
        cacheEventDetail(params);
      }
      else {
        processEventDetail(params);
      }
    }
  }

  @protected
  void processEventDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyLaunchDetail, params);
  }

  @protected
  void cacheEventDetail(Map<String, dynamic> params) {
    _eventDetailsCache?.add(params);
  }

  @protected
  void processCachedEventDetails() {
    if (_eventDetailsCache != null) {
      List<Map<String, dynamic>> eventDetailsCache = _eventDetailsCache!;
      _eventDetailsCache = null;

      for (Map<String, dynamic> eventDetail in eventDetailsCache) {
        processEventDetail(eventDetail);
      }
    }
  }
}

class Events2Query {
  static const double nearbyDistanceInMiles = 1.0;

  final Iterable<String>? ids;
  final String? searchText;
  final Set<Event2TypeFilter>? types;
  final Position? location;
  final Event2TimeFilter? timeFilter;
  final DateTime? customStartTimeUtc;
  final DateTime? customEndTimeUtc;
  final Map<String, dynamic>? attributes;
  final Event2SortType? sortType;
  final Event2SortOrder? sortOrder;
  final int? offset;
  final int? limit;

  Events2Query({this.ids, this.searchText,
    this.types, this.location,
    this.timeFilter = Event2TimeFilter.upcoming, this.customStartTimeUtc, this.customEndTimeUtc,
    this.attributes,
    this.sortType, this.sortOrder = Event2SortOrder.ascending,
    this.offset = 0, this.limit
  });

  Map<String, dynamic> toQueryJson() {
    Map<String, dynamic> options = <String, dynamic>{};

    if (ids != null) {
      options['ids'] = List<String>.from(ids!);
    }

    if (searchText != null) {
      options['name'] = searchText;
    }

    if (types != null) {
      _buildTypeLoadOptions(options, types!, location: location);
    }

    if (timeFilter != null) {
      buildTimeLoadOptions(options, timeFilter!, customStartTimeUtc: customStartTimeUtc, customEndTimeUtc: customEndTimeUtc);
    }

    if ((attributes != null) && attributes!.isNotEmpty) {
      // May need rework to backend attributes format:
      // "attribute": {
      //   "mode": "all" | "in" | null,   // optional
      //   "values": ...
      // }
      options['attributes'] = attributes;
    }

    if (sortType != null) {
      _buildSortTypeOptions(options, sortType!, location: location);
    }

    if (sortOrder != null) {
      options['order'] = event2SortOrderToOption(sortOrder);
    }

    if (offset != null) {
      options['offset'] = offset;
    }

    if (limit != null) {
      options['limit'] = limit;
    }

    return options;
  }


  void _buildTypeLoadOptions(Map<String, dynamic> options, Set<Event2TypeFilter> types, { Position? location }) {
    if (types.contains(Event2TypeFilter.free)) {
      options['free'] = true;
    }
    else if (types.contains(Event2TypeFilter.paid)) {
      options['free'] = false;
    }
    
    if (types.contains(Event2TypeFilter.inPerson)) {
      options['event_type'] = event2TypeToString(Event2Type.inPerson);
    }
    else if (types.contains(Event2TypeFilter.online)) {
      options['event_type'] = event2TypeToString(Event2Type.online);
    }
    else if (types.contains(Event2TypeFilter.hybrid)) {
      options['event_type'] = event2TypeToString(Event2Type.hybrid);
    }

    if (types.contains(Event2TypeFilter.public)) {
      options['private'] = false;
    }
    else if (types.contains(Event2TypeFilter.private)) {
      options['private'] = true;
    }

    if (types.contains(Event2TypeFilter.nearby) && (location != null)) {
      Map<String, dynamic>? locationParam = JsonUtils.mapValue(options['location']);
      if (locationParam != null) {
        locationParam['distance_in_miles'] = nearbyDistanceInMiles;
      }
      else {
        options['location'] = {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'distance_in_miles': nearbyDistanceInMiles,
        };
      }
    }
  }

  static void buildTimeLoadOptions(Map<String, dynamic> options, Event2TimeFilter? timeFilter, { DateTime? customStartTimeUtc, DateTime? customEndTimeUtc }) {
    TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
    
    if (timeFilter == Event2TimeFilter.upcoming) {
      options['end_time_after'] = nowUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.today) {
      TZDateTime endTimeUni = TZDateTimeUtils.dateOnly(nowUni, inclusive: true);
      
      options['end_time_after'] = nowUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.tomorrow) {
      TZDateTime tomorrowUni = nowUni.add(const Duration(days: 1));
      TZDateTime startTimeUni = TZDateTimeUtils.dateOnly(tomorrowUni);
      TZDateTime endTimeUni = TZDateTimeUtils.dateOnly(tomorrowUni, inclusive: true);
      
      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.thisWeek) {
      int nowWeekdayUni = nowUni.weekday;
      TZDateTime endTimeUni = TZDateTimeUtils.dateOnly((nowWeekdayUni < 7) ? nowUni.add(Duration(days: (7 - nowWeekdayUni))) :  nowUni, inclusive: true);
      
      options['end_time_after'] = nowUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.thisWeekend) {
      int nowWeekdayUni = nowUni.weekday;
      TZDateTime startTimeUni = (nowWeekdayUni < 6) ? TZDateTimeUtils.dateOnly(nowUni.add(Duration(days: (6 - nowWeekdayUni)))) : nowUni;
      TZDateTime endTimeUni = TZDateTimeUtils.dateOnly((nowWeekdayUni < 7) ? nowUni.add(Duration(days: (7 - nowWeekdayUni))) :  nowUni, inclusive: true);

      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.nextWeek) {
      int nowWeekdayUni = nowUni.weekday;
      TZDateTime startTimeUni = TZDateTimeUtils.dateOnly(nowUni.add(Duration(days: (8 - nowWeekdayUni))));
      TZDateTime endTimeUni = TZDateTimeUtils.dateOnly(nowUni.add(Duration(days: (14 - nowWeekdayUni))), inclusive: true);
      
      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.nextWeekend) {
      int nowWeekdayUni = nowUni.weekday;
      TZDateTime startTimeUni = TZDateTimeUtils.dateOnly(nowUni.add(Duration(days: (13 - nowWeekdayUni))));
      TZDateTime endTimeUni = TZDateTimeUtils.dateOnly(nowUni.add(Duration(days: (14 - nowWeekdayUni))), inclusive: true);
      
      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.thisMonth) {
      TZDateTime endTimeUni = TZDateTimeUtils.endOfThisMonth(nowUni);

      options['end_time_after'] = nowUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.nextMonth) {
      TZDateTime startTimeUni = TZDateTimeUtils.startOfNextMonth(nowUni);
      TZDateTime endTimeUni = TZDateTimeUtils.endOfThisMonth(startTimeUni);

      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch ~/ 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.customRange) {
      DateTime startTimeUtc = (customStartTimeUtc != null) && (customStartTimeUtc.isAfter(nowUni)) ? customStartTimeUtc : nowUni;
      options['end_time_after'] = startTimeUtc.millisecondsSinceEpoch ~/ 1000;
      if (customEndTimeUtc != null) {
        options['start_time_before'] = customEndTimeUtc.millisecondsSinceEpoch ~/ 1000;
      }
    }
  }

  void _buildSortTypeOptions(Map<String, dynamic> options, Event2SortType sortType, { Position? location }) {
    // sort_by: name, start_time, end_time, proximity. Default: start_time 
    options['sort_by'] = event2SortTypeToOption(sortType);
    if ((sortType == Event2SortType.proximity) && (location != null)) {
      options['location'] ??= {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    }
  }
}

class Event2PersonsResult {
  final List<Event2Person>? registrants;
  final List<Event2Person>? attendees;
  
  Event2PersonsResult({this.registrants, this.attendees});

  static Event2PersonsResult? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event2PersonsResult(
      registrants: Event2Person.listFromJson(JsonUtils.listValue(json['people'])),
      attendees: Event2Person.listFromJson(JsonUtils.listValue(json['attendees'])),
    ) : null;
  }
}

extension _ResponseExt on Response {
  String? get errorText {
    String? responseBody = body;
    Map<String, dynamic>? responseJson = JsonUtils.decodeMap(responseBody);
    String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
    if (StringUtils.isNotEmpty(message)) {
      return message;
    }
    else if (StringUtils.isNotEmpty(responseBody)) {
      return responseBody;
    }
    else {
      return StringUtils.isNotEmpty(reasonPhrase) ? "$statusCode $reasonPhrase" : "$statusCode";
    }

  }
}