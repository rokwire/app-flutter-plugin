
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Events2 with Service, NotificationsListener {

  static const String notifyLaunchDetail  = "edu.illinois.rokwire.event2.launch.detail";
  static const String notifyLaunchQuery  = "edu.illinois.rokwire.event2.launch.query";
  static const String notifySelfCheckIn  = "edu.illinois.rokwire.event2.self.checkin";
  static const String notifyChanged  = "edu.illinois.rokwire.event2.changed";
  static const String notifyUpdated  = "edu.illinois.rokwire.event2.updated";
  static const String notifyNotificationsUpdated  = "edu.illinois.rokwire.event2.notifications.updated";

  static const String sportEventCategory = 'Big 10 Athletics';

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
      DeepLink.notifyUiUri,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { DeepLink() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUiUri) {
      onDeepLinkUri(JsonUtils.cast(param));
    }
  }

  // Content Attributes

  static const String contentAttributesScope = 'events';

  ContentAttributes? get contentAttributes =>
    Content().contentAttributes(contentAttributesScope);

  bool isContentAttributeEnabled(ContentAttribute? attribute) =>
    FlexUI().isAttributeEnabled(attribute?.id, scope: contentAttributesScope);

  List<String>? displaySelectedContentAttributeLabelsFromSelection(Map<String, dynamic>? selection, { ContentAttributeUsage? usage, bool complete = false }) =>
    contentAttributes?.displaySelectedLabelsFromSelection(selection, usage: usage, scope: contentAttributesScope, complete: complete);

  // Implementation

  Future<Response?> _loadEventsResponse(Events2Query? query, {Client? client}) async {
    if (Config().calendarUrl == null) {
      debugPrint('Failed to load events - missing calendar url.');
      return null;
    }

    String? requestBody = JsonUtils.encode(query?.toQueryJson());
    Response? response = await Network()
        .post("${Config().calendarUrl}/v2/events/load", body: requestBody, headers: _jsonHeaders, client: client, auth: Auth2());

    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode != 200) {
      debugPrint('Failed to load events. Reason: $responseCode, $responseBody');
    }
    return response;
  }

  // Returns Events2ListResult in case of success, String description in case of error
  Future<dynamic> loadEventsEx(Events2Query? query, {Client? client}) async {
    Response? response = await _loadEventsResponse(query, client: client);
    //TMP: debugPrint("$body => ${response?.statusCode} ${response?.body}", wrapWidth: 256);
    return (response?.statusCode == 200) ? Events2ListResult.fromResponseJson(JsonUtils.decode(response?.body)) : response?.errorText;
  }

  Future<Events2ListResult?> loadEvents(Events2Query? query, {Client? client}) async {
    dynamic result = await loadEventsEx(query, client: client);
    return (result is Events2ListResult) ? result : null;
  }

  Future<Events2ListResult?> loadGroupEvents({String? groupId, Event2TimeFilter? timeFilter, int? offset, int? limit}) async =>
    StringUtils.isNotEmpty(groupId) ? loadEvents(Events2Query(
        groupIds: {groupId!},
        groupings: Event2Grouping.individualEvents(),
        timeFilter: timeFilter,
        sortType: Event2SortType.dateTime,
        sortOrder: (timeFilter == Event2TimeFilter.past) ? Event2SortOrder.descending : Event2SortOrder.ascending,
        offset: offset, limit: limit
    )) : null;

  Future<List<Event2>?> loadEventsList(Events2Query? query) async =>
    (await loadEvents(query))?.events;

  Future<dynamic> loadEventEx(String eventId, {bool admin = false}) async {
    if (Config().calendarUrl != null) {
      String? url = Config().calendarUrl;
      url = admin ? '$url/admin/events' : '$url/v2/events/load';
      String? body = JsonUtils.encode({"ids":[eventId]});
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        List<Event2>? resultList = Events2ListResult.listFromResponseJson(JsonUtils.decode(response?.body));
        return ((resultList != null) && resultList.isNotEmpty) ? resultList.first : null;
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  Future<Event2?> loadEvent(String eventId, {bool admin = false}) async {
    dynamic result = await loadEventEx(eventId, admin: admin);
    return (result is Event2) ? result : null;
  }

  Future<dynamic> loadEventsByIdsEx({List<String>? eventIds, Event2SortType? sortType,
    Event2TimeFilter? timeFilter, Event2SortOrder? sortOrder, int? offset, int? limit}) async {
    if (Config().calendarUrl != null && CollectionUtils.isNotEmpty(eventIds)) {
      Map<String, dynamic> options = <String, dynamic>{};
      if (eventIds != null) {
        options['ids'] = List<String>.from(eventIds);
      }
      if (timeFilter != null) {
        Events2Query.buildTimeLoadOptions(options, timeFilter);
      }
      if (sortType != null) {
        options['sort_by'] = event2SortTypeToOption(sortType);
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

      String url = "${Config().calendarUrl}/events/lite";
      String? body = JsonUtils.encode(options);
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        List<Event2>? resultList = Events2ListResult.listFromResponseJson(JsonUtils.decode(response?.body));
        return resultList;
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  Future<List<Event2>?> loadEventsByIds({List<String>? eventIds,
    Event2SortType? sortType = Event2SortType.dateTime,
    Event2TimeFilter timeFilter = Event2TimeFilter.upcoming,
    Event2SortOrder sortOrder = Event2SortOrder.ascending,
    int offset = 0, int? limit}) async {
    dynamic result = await loadEventsByIdsEx(eventIds: eventIds, sortType: sortType, sortOrder: sortOrder, timeFilter: timeFilter);
    return (result is List<Event2>) ? result : null;
  }

  // Returns Event2 in case of success, String description in case of error
  Future<dynamic> createEvent(Event2 source, {List<Event2PersonIdentifier>? adminIdentifiers}) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/v3/event";
      String? body = JsonUtils.encode({
          "event": source.toJson(),
          "admins_identifiers": Event2PersonIdentifier.listToNotNullJson(adminIdentifiers) ?? []
      });
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        _notifyGroupsForModifiedEvents(groupIds: source.groupIds);
        return Event2.fromJson(JsonUtils.decodeMap(response?.body)?["event"]);
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  // Returns Event2 in case of success, String description in case of error
  Future<dynamic> updateEvent(Event2 source, {Set<String>? initialGroupIds, List<Event2PersonIdentifier>? adminIdentifiers}) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/v3/event/${source.id}";
      String? body = JsonUtils.encode({
        "event": source.toJson(),
        "admins_identifiers": Event2PersonIdentifier.listToNotNullJson(adminIdentifiers) ?? []
      });
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        Event2? event = Event2.fromJson(JsonUtils.decodeMap(response?.body)?["event"]);
        Set<String> notifyGroupIds = source.groupIds ?? <String>{};
        if (CollectionUtils.isNotEmpty(initialGroupIds)) {
          notifyGroupIds = notifyGroupIds.union(initialGroupIds!);
        }
        NotificationService().notify(notifyUpdated, event);
        NotificationService().notify(notifyChanged);
        _notifyGroupsForModifiedEvents(groupIds: notifyGroupIds);
        return event;
      }
      else {
        return response?.errorText;
      }
    }
    return null;
  }

  Future<bool> linkEventToGroup({required Event2 event, required groupId, required bool link}) async {
    if (Config().calendarUrl != null) {
      Event2ContextItem groupItem = Event2ContextItem(name: Event2ContextItemName.group_member, identifier: groupId);
      Event2AuthorizationContext? authorizationContext;
      // 1 Add or remove authorization item based on the action (link / unlink)
      if (event.authorizationContext?.status == Event2AuthorizationContextStatus.active) {
        Event2AuthorizationContextStatus? status = event.authorizationContext?.status;
        List<Event2ContextItem>? items = event.authorizationContext?.items;
        if (items == null) {
          items = <Event2ContextItem>[];
        }
        // 1.1 Unlink event from group - e.g. remove context item
        if (link == false) {
          if (items.contains(groupItem)) {
            items.remove(groupItem);
          }
          if (CollectionUtils.isEmpty(items)) {
            // Make the event public if there are no more items so that an admin can view and edit the event
            status = Event2AuthorizationContextStatus.none;
          }
        } else {
          // 1.2 Link event to group - e.g. add context item
          items.add(groupItem);
        }
        authorizationContext = Event2AuthorizationContext(status: status, items: items);
      }
      else {
        authorizationContext = event.authorizationContext;
      }
      // 2 Add or remove context item based on the action (link / unlink)
      Event2Context? event2Context;
      // 2.1 Unlink event from group - e.g. remove context item
      List<Event2ContextItem>? items;
      if (link == false) {
        items = ListUtils.from(event.context?.items);
        if (items?.contains(groupItem) ?? false) {
          items!.remove(groupItem);
          event2Context = Event2Context(items: items);
        }
      } else {
        // 2.2 Link event to group - e.g. add context item
        if (event.context == null) {
          event2Context = Event2Context.fromIdentifiers(identifiers: [groupId]);
        } else {
          List<Event2ContextItem> items = ListUtils.from(event.context?.items) ?? <Event2ContextItem>[];
          items.add(groupItem);
          event2Context = Event2Context(items: items);
        }
      }

      // 3 Update the event contexts
      Map<String, dynamic> requestBody = {};
      if (authorizationContext != null) {
        requestBody['authorization_context'] = authorizationContext.toJson();
      }
      if (event2Context != null) {
        requestBody['context'] = event2Context.toJson();
      }

      String url = "${Config().calendarUrl}/event/${event.id}/context";
      String? body = JsonUtils.encode(requestBody);
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      String? responseString = response?.body;
      int? responseCode = response?.statusCode;
      if (responseCode == 200) {
        Event2? event = Event2.fromJson(JsonUtils.decodeMap(responseString));
        NotificationService().notify(notifyUpdated, event);
        NotificationService().notify(notifyChanged);
        _notifyGroupsForModifiedEvents(groupIds: {groupId});
        return true;
      } else {
        debugPrint(responseString);
      }
    }
    return false;
  }

  // Returns error message, true if successful
  Future<dynamic> deleteEvent({required String eventId, Set<String>? groupIds}) async{
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId";
      Response? response = await Network().delete(url, headers: _jsonHeaders, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        _notifyGroupsForModifiedEvents(groupIds: groupIds);
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
      return _processEventUpdateResponse(response);
    }
    return null;
  }

  dynamic _processEventUpdateResponse(Response? response) {
    if (response?.statusCode == 200) {
      Event2? event = Event2.fromJson(JsonUtils.decodeMap(response?.body));
      NotificationService().notify(notifyUpdated, event);
      return event;
    }
    else {
      return response?.errorText;
    }
  }
  
  // Returns error message, Event2 if successful
  Future<dynamic> updateEventAttendanceDetails(String eventId, Event2AttendanceDetails? attendanceDetails) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/attendance";
      String? body = JsonUtils.encode({ 'attendance_details' : attendanceDetails?.toJson()});
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      return _processEventUpdateResponse(response);
    }
    return null;
  }

  // Returns error message, Event2 if successful
  Future<dynamic> updateEventSurveyDetails(String eventId, Event2SurveyDetails? surveyDetails) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/survey";
      String? body = JsonUtils.encode({'survey_details': surveyDetails?.toJson()});
      Response? response = await Network().put(url, body: body, headers: _jsonHeaders, auth: Auth2());
      return _processEventUpdateResponse(response);
    }
    return null;
  }

  // Returns error message, true if successful
  Future<dynamic> registerToEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event-person/register";
      String? body = JsonUtils.encode({'event_id': eventId,});
      Response? response = await Network().post(url, body: body, headers: _jsonHeaders, auth: Auth2());
      return _processEventUpdateResponse(response);
    }
    return null;
  }

  // Returns error message, true if successful
  Future<dynamic> unregisterFromEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event-person/unregister/$eventId";
      Response? response = await Network().delete(url, headers: _jsonHeaders, auth: Auth2());
      return _processEventUpdateResponse(response);
    }
    return null;
  }

  // Returns error message, Event2PersonsResult if successful
  Future<dynamic> loadEventPeopleEx(String eventId) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/users";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Event2PersonsResult.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
    }
    return null;
  }

  Future<Event2PersonsResult?> loadEventPeople(String eventId) async {
    dynamic result = await loadEventPeopleEx(eventId);
    return (result is Event2PersonsResult) ? result : null;
  }

  // Returns error message, List<Event2PersonIdentifier> if successful
  Future<dynamic> loadEventPersonsEx({String? uin}) async {
    if (Config().calendarUrl != null) {
      String baseUrl = "${Config().calendarUrl}/users";
      Map<String, String> urlParams = <String, String>{};
      if (uin != null) {
        urlParams['uin'] = uin;
      }
      String url = UrlUtils.addQueryParameters(baseUrl, urlParams);
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Event2PersonIdentifier.listFromJson(JsonUtils.decodeList(response?.body)) : response?.errorText;
    }
    return null;
  }

  Future<List<Event2PersonIdentifier>?> loadEventPersons({String? uin}) async {
    dynamic result = await loadEventPersonsEx(uin: uin);
    return (result is List<Event2PersonIdentifier>) ? result : null;
  }

  // Returns error message, Event2PersonIdentifier if successful
  Future<dynamic> loadEventPersonEx({String? uin}) async {
    dynamic result = await loadEventPersonsEx(uin: uin);
    return (result is List<Event2PersonIdentifier>) ? (result.isNotEmpty ? result.first : null) : result;
  }

  Future<Event2PersonIdentifier?> loadEventPerson({String? uin}) async {
    dynamic result = await loadEventPersonEx(uin: uin);
    return (result is Event2PersonIdentifier) ? result : null;
  }

  // Returns secret string if successful, otherwise null
  Future<String?> getEventSelfCheckInSecret(String eventId) async {
    //TMP: return Future.delayed(Duration(milliseconds: 1500), () => 'abracadabra');
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/security/secret";
      Response? response = await Network().get(url, headers: _jsonHeaders, auth: Auth2());
      Map<String, dynamic>? responseData = (response?.statusCode == 200) ? JsonUtils.decodeMap(response?.body)  : null;  
      return JsonUtils.stringValue(responseData?['secret']);
    }
    return null;
  }

  // Returns error message, Event2Person if successful
  Future<dynamic> selfCheckInEvent(String eventId, { String? secret }) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/attendee/self-check-in";
      String? body = JsonUtils.encode({
        if (secret != null)
          'secret': secret,
      });
      Response? response = await Network().post(url, headers: _jsonHeaders, body: body, auth: Auth2());
      return (response?.statusCode == 200) ? Event2Person.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
    }
    return null;
  }

  // Returns error message, Event2Person if successful
  Future<dynamic> attendEvent(String eventId, { Event2PersonIdentifier? personIdentifier, String? uin }) async {

    if (Config().calendarUrl != null) {
      String? url, body;
      if (personIdentifier != null) {
        url = "${Config().calendarUrl}/event/$eventId/manual-attendee/add";
        body = JsonUtils.encode({'identifier': personIdentifier.toJson()});
      }
      else if (uin != null) {
        url = "${Config().calendarUrl}/event/$eventId/attendee";
        body = JsonUtils.encode({'uin': uin });
      }
      if ((url != null) && (body != null)) {
        Response? response = await Network().post(url, headers: _jsonHeaders, body: body, auth: Auth2());
        return (response?.statusCode == 200) ? Event2Person.fromJson(JsonUtils.decodeMap(response?.body)) : response?.errorText;
      }
    }
    return null;
  }

  // Returns error message, true if successful
  Future<dynamic> unattendEvent(String eventId, { Event2PersonIdentifier? personIdentifier }) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/manual-attendee/remove";
      String? body = JsonUtils.encode({'identifier': personIdentifier?.toJson()});

      Response? response = await Network().delete(url, headers: _jsonHeaders, body: body, auth: Auth2());
      return (response?.statusCode == 200) ? true : response?.errorText;
    }
    return null;
  }

  // Event Custom Notifications
  Future<dynamic> saveNotificationSettings({required String eventId, List<dynamic>? notificationSettings}) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/notification-settings";
      String? body = JsonUtils.encode(Event2NotificationSetting.listToJson(notificationSettings));
      Response? response = await Network().post(url, headers: _jsonHeaders, body: body, auth: Auth2(),);

      if(response?.statusCode == 200){
        NotificationService().notify(Events2.notifyNotificationsUpdated);
        return true;
      } else
        return response?.errorText;
    }
    return null;
  }

  Future<dynamic> loadNotificationSettings({required String eventId}) async {
    if (Config().calendarUrl != null) {
      String url = "${Config().calendarUrl}/event/$eventId/notification-settings";
      Response? response = await Network().get(url, auth: Auth2());
      return (response?.statusCode == 200) ? Event2NotificationSetting.listFromJson(JsonUtils.decodeList(response?.body)) : response?.errorText;
    }
    return null;
  }

  ///
  /// Returns null if delete is successful, error String message - otherwise
  ///
  Future<String?> deleteAllNotification({required String eventId, required List<String> notificationIds}) async {
    //TBD probably we can delete them at once (pass list of notificationIds to BB)
    if (Config().calendarUrl == null) {
      return 'Missing calendar url.';
    }
    if (CollectionUtils.isEmpty(notificationIds)) {
      return 'Please, select at least one notification.';
    }
    List<String?>? errorMsgs;
    for (String notificationId in notificationIds) {
      String? notificationDeleteError = await _deleteNotification(eventId: eventId, notificationId: notificationId);
      if (notificationDeleteError != null) {
        if (errorMsgs == null) {
          errorMsgs = <String?>[];
        }
        ListUtils.add(errorMsgs, notificationDeleteError);
        break;
      }
    }
    if (CollectionUtils.isNotEmpty(errorMsgs)) {
      return errorMsgs!.join('\n\n'); // split error messages by new line
    } else {
      NotificationService().notify(Events2.notifyNotificationsUpdated, null);
      return null;
    }
  }

  ///
  /// Returns null if delete is successful, error String message - otherwise
  ///
  Future<String?> _deleteNotification({required String eventId, required String notificationId}) async {
    if (Config().calendarUrl == null) {
      return 'Missing calendar url.';
    }
    String url = "${Config().calendarUrl}/event/$eventId/notification-settings/$notificationId";
    Response? response = await Network().delete(url, headers: _jsonHeaders, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return null;
    } else {
      String errorText = 'Failed to delete event notification. Reason: $responseCode, $responseString';
      debugPrint(errorText);
      return errorText;
    }
  }

  // User Data

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    Response? response = (Config().calendarUrl != null) ? await Network().get("${Config().calendarUrl}/user-data", auth: Auth2()) : null;
    return (response?.succeeded == true) ? JsonUtils.decodeMap(response?.body) : null;
  }

  // Helpers

  void _notifyGroupsForModifiedEvents({Set<String>? groupIds}) {
    if (CollectionUtils.isNotEmpty(groupIds)) {
      for (String groupId in groupIds!) {
        NotificationService().notify(Groups.notifyGroupEventsUpdated, groupId);
      }
    }
  }

  Map<String, String?> get _jsonHeaders => {"Accept": "application/json", "Content-type": "application/json"};

  // DeepLinks

  static String get eventDetailRawUrl => '${DeepLink().appUrl}/event2_detail'; //TBD: => event_detail
  static String eventDetailUrl(String eventId) => UrlUtils.buildWithQueryParameters(eventDetailRawUrl, <String, String>{
    'event_id' : eventId
  });

  static String get eventsQueryRawUrl => '${DeepLink().appUrl}/events2_query'; //TBD: => events_query
  static String eventsQueryUrl(Map<String, String> params) => UrlUtils.buildWithQueryParameters(eventsQueryRawUrl,
      params
  );

  static String get eventSelfCheckInRawUrl => '${DeepLink().appUrl}/event2_self_checkin'; //TBD: => event_self_checkin
  static String eventSelfCheckInUrl(String eventId, { String? secret }) => UrlUtils.buildWithQueryParameters(eventSelfCheckInRawUrl, <String, String>{
    'event_id' : eventId,
    if (secret != null)
      'secret': secret,
  });

  @protected
  void onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      if (uri.matchDeepLinkUri(Uri.tryParse(eventDetailRawUrl))) {
        try { NotificationService().notify(notifyLaunchDetail, uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { print(e.toString()); }
      }
      else if (uri.matchDeepLinkUri(Uri.tryParse(eventsQueryRawUrl))) {
        try { NotificationService().notify(notifyLaunchQuery, uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { print(e.toString()); }
      }
      else if (uri.matchDeepLinkUri(Uri.tryParse(eventSelfCheckInRawUrl))) {
        try { NotificationService().notify(notifySelfCheckIn, uri.queryParameters.cast<String, dynamic>()); }
        catch (e) { print(e.toString()); }
      }
    }
  }
}

class Events2Query {
  static double get nearbyDistanceInMiles => Config().event2NearbyDistanceInMiles;
  static int get startTimeOffsetInMsIfNullEndTime => Config().event2StartTimeOffsetIfNullEndTime * 1000; // in milliseconds

  final Iterable<String>? ids;
  final Event2Grouping? grouping;
  final List<Event2Grouping>? groupings;
  final String? searchText;
  final Set<Event2TypeFilter>? types;
  final Position? location;
  final Event2TimeFilter? timeFilter;
  final DateTime? customStartTimeUtc;
  final DateTime? customEndTimeUtc;
  final Map<String, dynamic>? attributes;
  final Set<String>? groupIds;
  final Event2SortType? sortType;
  final Event2SortOrder? sortOrder;
  final int? offset;
  final int? limit;

  Events2Query({this.ids, this.grouping, this.groupings, this.searchText,
    this.types, this.location,
    this.timeFilter = Event2TimeFilter.upcoming, this.customStartTimeUtc, this.customEndTimeUtc,
    this.attributes, this.groupIds,
    this.sortType, this.sortOrder = Event2SortOrder.ascending,
    this.offset = 0, this.limit
  });

  Map<String, dynamic> toQueryJson() {
    Map<String, dynamic> options = <String, dynamic>{};

    if (ids != null) {
      options['ids'] = List<String>.from(ids!);
    }

    if (grouping != null) {
      options['grouping'] = grouping?.toJson();
    }

    if (groupings != null) {
      options['groupings'] = Event2Grouping.listToJson(groupings);
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

    if (CollectionUtils.isNotEmpty(groupIds)) {
      options['context'] = Event2Context.fromIdentifiers(identifiers: groupIds!.toList()).toJson();
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
      options['authorization_context'] = Event2AuthorizationContext.none();
    }
    else if (types.contains(Event2TypeFilter.private)) {
      options['authorization_context'] = Event2AuthorizationContext.registeredUser();
    }

    if (types.contains(Event2TypeFilter.superEvent)) {
      options['groupings'] = Event2Grouping.listToJson(Event2Grouping.superEvents());
    }

    if (types.contains(Event2TypeFilter.admin)) {
      options['person'] = Event2Person(role: Event2UserRole.admin).toJson();
    }

    if (types.contains(Event2TypeFilter.favorite)) {
      LinkedHashSet<String>? favoriteIds = Auth2().account?.prefs?.getFavorites(Event2.favoriteKeyName);
      if ((favoriteIds != null) && favoriteIds.isNotEmpty) {
        List<String>? filterIds = JsonUtils.listStringsValue(options['ids']);
        options['ids'] = ((filterIds != null) && filterIds.isNotEmpty) ?
          favoriteIds.intersection(filterIds.toSet()) : favoriteIds.toList();
      }
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
    TZDateTime nowLocal = DateTimeLocal.nowLocalTZ();

    if (timeFilter == Event2TimeFilter.past) {
      options['start_time_before'] = nowLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.upcoming) {
      options['end_time_after'] = nowLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (nowLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.today) {
      TZDateTime endTimeLocal = TZDateTimeUtils.dateOnly(nowLocal, inclusive: true);
      
      options['end_time_after'] = nowLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (nowLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.tomorrow) {
      TZDateTime tomorrowLocal = nowLocal.add(const Duration(days: 1));
      TZDateTime startTimeLocal = TZDateTimeUtils.dateOnly(tomorrowLocal);
      TZDateTime endTimeLocal = TZDateTimeUtils.dateOnly(tomorrowLocal, inclusive: true);
      
      options['end_time_after'] = startTimeLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (startTimeLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.thisWeek) {
      int nowWeekdayLocal = nowLocal.weekday;
      TZDateTime endTimeLocal = TZDateTimeUtils.dateOnly((nowWeekdayLocal < 7) ? nowLocal.add(Duration(days: (7 - nowWeekdayLocal))) :  nowLocal, inclusive: true);
      
      options['end_time_after'] = nowLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (nowLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.thisWeekend) {
      int nowWeekdayLocal = nowLocal.weekday;
      TZDateTime startTimeLocal = (nowWeekdayLocal < 6) ? TZDateTimeUtils.dateOnly(nowLocal.add(Duration(days: (6 - nowWeekdayLocal)))) : nowLocal;
      TZDateTime endTimeLocal = TZDateTimeUtils.dateOnly((nowWeekdayLocal < 7) ? nowLocal.add(Duration(days: (7 - nowWeekdayLocal))) :  nowLocal, inclusive: true);

      options['end_time_after'] = startTimeLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (startTimeLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.nextWeek) {
      int nowWeekdayLocal = nowLocal.weekday;
      TZDateTime startTimeLocal = TZDateTimeUtils.dateOnly(nowLocal.add(Duration(days: (8 - nowWeekdayLocal))));
      TZDateTime endTimeLocal = TZDateTimeUtils.dateOnly(nowLocal.add(Duration(days: (14 - nowWeekdayLocal))), inclusive: true);
      
      options['end_time_after'] = startTimeLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (startTimeLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.nextWeekend) {
      int nowWeekdayLocal = nowLocal.weekday;
      TZDateTime startTimeLocal = TZDateTimeUtils.dateOnly(nowLocal.add(Duration(days: (13 - nowWeekdayLocal))));
      TZDateTime endTimeLocal = TZDateTimeUtils.dateOnly(nowLocal.add(Duration(days: (14 - nowWeekdayLocal))), inclusive: true);
      
      options['end_time_after'] = startTimeLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (startTimeLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.thisMonth) {
      TZDateTime endTimeLocal = TZDateTimeUtils.endOfThisMonth(nowLocal);

      options['end_time_after'] = nowLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (nowLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.nextMonth) {
      TZDateTime startTimeLocal = TZDateTimeUtils.startOfNextMonth(nowLocal);
      TZDateTime endTimeLocal = TZDateTimeUtils.endOfThisMonth(startTimeLocal);

      options['end_time_after'] = startTimeLocal.millisecondsSinceEpoch ~/ 1000;
      options['start_time_after_null_end_time'] = (startTimeLocal.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      options['start_time_before'] = endTimeLocal.millisecondsSinceEpoch ~/ 1000;
    }
    else if (timeFilter == Event2TimeFilter.customRange) {
      if (customStartTimeUtc != null) {
        options['end_time_after'] = customStartTimeUtc.millisecondsSinceEpoch ~/ 1000;
        options['start_time_after_null_end_time'] = (customStartTimeUtc.millisecondsSinceEpoch - startTimeOffsetInMsIfNullEndTime) ~/ 1000;
      }
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
  final int? registrationOccupancy;
  
  Event2PersonsResult({this.registrants, this.attendees, this.registrationOccupancy});

  static Event2PersonsResult? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event2PersonsResult(
      registrants: Event2Person.listFromJson(JsonUtils.listValue(json['people'])),
      attendees: Event2Person.listFromJson(JsonUtils.listValue(json['attendees'])),
      registrationOccupancy: JsonUtils.intValue(json['registration_occupancy']),
    ) : null;
  }

  factory Event2PersonsResult.fromOther(Event2PersonsResult? persons, {
    List<Event2Person>? registrants, List<Event2Person>? attendees, int? registrationOccupancy,
  }) {
    registrants ??= persons?.registrants;
    attendees ??= persons?.attendees;
    return Event2PersonsResult(
      registrants: (registrants != null) ? List.from(registrants) : null,
      attendees: (attendees != null) ? List.from(attendees) : null,
      registrationOccupancy: registrationOccupancy ?? persons?.registrationOccupancy,
    );
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

