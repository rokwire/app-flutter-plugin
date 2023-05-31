
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Events2 with Service implements NotificationsListener {

  static const String notifyLaunchDetail  = "edu.illinois.rokwire.event2.launch_detail";

  List<Map<String, dynamic>>? _eventDetailsCache;

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

  // Implementation

  Future<List<Event2>?> loadEvents(Events2Query? query) async {
    if (Config().calendarUrl != null) {
      Response? response = await Network().get("${Config().calendarUrl}/events/load", body: JsonUtils.encode(query?.toQueryJson()), auth: Auth2());
      return (response?.statusCode == 200) ? Event2.listFromJson(JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }


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

  final String? searchText;
  final Set<EventTypeFilter>? typeFilter;
  final Position? location;
  final EventTimeFilter? timeFilter;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final Map<String, dynamic>? attributes;
  final EventSortType? sortType;
  final EventSortOrder? sortOrder;
  final int? offset;
  final int? limit;

  Events2Query({this.searchText,
    this.typeFilter, this.location,
    this.timeFilter = EventTimeFilter.upcoming, this.startTimeUtc, this.endTimeUtc,
    this.attributes,
    this.sortType, this.sortOrder = EventSortOrder.ascending,
    this.offset = 0, this.limit
  });

  Map<String, dynamic> toQueryJson() {
    Map<String, dynamic> options = <String, dynamic>{};

    if (searchText != null) {
      options['name'] = searchText;
    }

    if (typeFilter != null) {
      _buildTypeLoadOptions(options, typeFilter!, location: location);
    }

    if (timeFilter != null) {
      _buildTimeLoadOptions(options, timeFilter!, startTimeUtc: startTimeUtc, endTimeUtc: endTimeUtc);
    }

    if (attributes != null) {
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
      options['order'] = eventSortOrderToOption(sortOrder);
    }

    if (offset != null) {
      options['offset'] = offset;
    }

    if (limit != null) {
      options['limit'] = limit;
    }

    return options;
  }


  void _buildTypeLoadOptions(Map<String, dynamic> options, Set<EventTypeFilter> typeFilter, { Position? location }) {
    if (typeFilter.contains(EventTypeFilter.free)) {
      options['free'] = true;
    }
    else if (typeFilter.contains(EventTypeFilter.paid)) {
      options['free'] = false;
    }
    
    if (typeFilter.contains(EventTypeFilter.inPerson)) {
      options['online'] = false;
    }
    else if (typeFilter.contains(EventTypeFilter.online)) {
      options['online'] = true;
    }

    if (typeFilter.contains(EventTypeFilter.public)) {
      options['private'] = false;
    }
    else if (typeFilter.contains(EventTypeFilter.private)) {
      options['private'] = true;
    }

    if (typeFilter.contains(EventTypeFilter.nearby) && (location != null)) {
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

  void _buildTimeLoadOptions(Map<String, dynamic> options, EventTimeFilter timeFilter, { DateTime? startTimeUtc, DateTime? endTimeUtc }) {
    TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
    
    if (timeFilter == EventTimeFilter.upcoming) {
      options['end_time_after'] = nowUni.millisecondsSinceEpoch / 1000;
    }
    else if (timeFilter == EventTimeFilter.today) {
      TZDateTime endTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, nowUni.year, nowUni.month, nowUni.day, 23, 59, 59);
      options['end_time_after'] = nowUni.millisecondsSinceEpoch / 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch / 1000;
    }
    else if (timeFilter == EventTimeFilter.tomorrow) {
      TZDateTime tomorrowUni = nowUni.add(const Duration(days: 1));
      TZDateTime startTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, tomorrowUni.year, tomorrowUni.month, tomorrowUni.day, 0, 0, 0);
      TZDateTime endTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, tomorrowUni.year, tomorrowUni.month, tomorrowUni.day, 23, 59, 59);
      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch / 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch / 1000;
    }
    else if (timeFilter == EventTimeFilter.thisWeek) {
      int nowWeekdayUni = nowUni.weekday;
      TZDateTime endOfWeekUni = (nowWeekdayUni < 7) ? nowUni.add(Duration(days: (7 - nowWeekdayUni))) :  nowUni;
      TZDateTime endTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, endOfWeekUni.year, endOfWeekUni.month, endOfWeekUni.day, 23, 59, 59);
      options['end_time_after'] = nowUni.millisecondsSinceEpoch / 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch / 1000;
    }
    else if (timeFilter == EventTimeFilter.thisWeekend) {
      int nowWeekdayUni = nowUni.weekday;
      late TZDateTime startTimeUni;
      if (nowWeekdayUni < 6) {
        TZDateTime startOfWeekUni = nowUni.add(Duration(days: (6 - nowWeekdayUni)));
        startTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, startOfWeekUni.year, startOfWeekUni.month, startOfWeekUni.day, 0, 0, 0);
      }
      else {
        startTimeUni = nowUni;
      }

      TZDateTime endOfWeekUni = (nowWeekdayUni < 7) ? nowUni.add(Duration(days: (7 - nowWeekdayUni))) :  nowUni;
      TZDateTime endTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, endOfWeekUni.year, endOfWeekUni.month, endOfWeekUni.day, 23, 59, 59);

      options['end_time_after'] = startTimeUni.millisecondsSinceEpoch / 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch / 1000;
    }
    else if (timeFilter == EventTimeFilter.thisMonth) {
      TZDateTime startOfNextMonth = (nowUni.month < 12) ? TZDateTime(DateTimeUni.timezoneUniOrLocal, nowUni.year, nowUni.month + 1, 1) : TZDateTime(DateTimeUni.timezoneUniOrLocal, nowUni.year + 1, 1, 1);
      TZDateTime endOfThisMonth = startOfNextMonth.subtract(const Duration(days: 1));
      TZDateTime endTimeUni = TZDateTime(DateTimeUni.timezoneUniOrLocal, endOfThisMonth.year, endOfThisMonth.month, endOfThisMonth.day, 23, 59, 59);
      options['end_time_after'] = nowUni.millisecondsSinceEpoch / 1000;
      options['start_time_before'] = endTimeUni.millisecondsSinceEpoch / 1000;
    }
    else if (timeFilter == EventTimeFilter.customRange) {
      if (startTimeUtc != null) {
        options['end_time_after'] = startTimeUtc.millisecondsSinceEpoch / 1000;
      }
      if (endTimeUtc != null) {
        options['start_time_before'] = endTimeUtc.millisecondsSinceEpoch / 1000;
      }
    }
  }

  void _buildSortTypeOptions(Map<String, dynamic> options, EventSortType sortType, { Position? location }) {
    // sort_by: name, start_time, end_time, proximity. Default: start_time 
    options['sort_by'] = eventSortTypeToOption(sortType);
    if ((sortType == EventSortType.proximity) && (location != null)) {
      options['location'] ??= {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    }
  }
}