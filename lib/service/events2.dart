
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
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

  // Content Attributes

  ContentAttributes? get contentAttributes => Content().contentAttributes('events');

  // Implementation

  Future<List<Event2>?> loadEvents(Events2Query? query) async {
    if (kDebugMode) {
      return _sampleEvents;
    }
    else if (Config().calendarUrl != null) {
      Response? response = await Network().get("${Config().calendarUrl}/events/load", body: JsonUtils.encode(query?.toQueryJson()), auth: Auth2());
      return (response?.statusCode == 200) ? Event2.listFromJson(JsonUtils.decodeList(response?.body)) : null;
    }
    return null;
  }

  List<Event2> get _sampleEvents => <Event2>[
    Event2(id: '1',
      name: 'Illinois CS Girls Who Code Club',
      description: "<p>Illinois Computer Science hosts a chapter of Girls Who Code (girlswhocode.com), a club that allows middle school and high school girls to explore coding in a fun and friendly environment. The goal is to inspire, educate, and equip girls with the computing skills to pursue 21st century opportunities. The Illinois Computer Science Girls Who Code club is full for the 2022-23 school year.</p>",
      instructions: 'Take it easy',
      imageUrl: 'https://rokwire-images.s3.us-east-2.amazonaws.com/event/tout/088b5d28-de44-11eb-9bf2-0a58a9feac02.webp',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-07T16:30:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-07T18:30:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Big 10 Athletics', 'Campus Visits', 'Performances'],
        'sport': 'Wrestling',
        'college': 'Liberal Arts & Sciences',
        'department': 'Astronomy',
      },
      location: ExploreLocation(building: 'Davenport Hall', room: '206A',
        fullAddress: '607 S Mathews Ave  Urbana, IL 61801',
        latitude: 40.1072, longitude: -88.2262,
      ),
      required: false, canceled: false, private: false, free: true, online: false,
      sponsor: 'Computer Science',
      speaker: 'Dr. Hong Hao',
      contacts: <Contact>[
        Contact(firstName: 'Cynthia', lastName: 'Coleman', email: 'ccoleman@illinois.edu'),
      ],
    ),
    Event2(id: '2',
      name: 'Away from the Empire: The Linguistic and Cultural Shift in Ukraine in the Wake of the Russian Invasion: Yaryna Zakalska and Serhii Yanchuk',
      description: "<p id=\"isPasted\"><span style=\"font-size: inherit; background-color: transparent;\">The Russian-Ukrainian war of the 21st century aimed not only to physically destroy Ukraine but also to expand the linguistic borders of the \u201cRussian world,\u201d denationalize Ukraine, and reestablish the cultural dominance of Russia over the Ukrainian people. The war that began in 2014 and intensified in the last year's invasion has led to a cultural and linguistic shift from Russian to Ukrainian among much of the Ukrainian population. On April 19, 21, and 26, 2023, the University of Illinois at Urbana-Champaign will host a virtual symposium titled \"Away from the Empire: The Linguistic and Cultural Shift in Ukraine in the Wake of the Russian Invasion\" that will explore this topic. The symposium will feature seven Ukrainian scholars (linguists, sociologists, literary scholars, ethnologists, and political scientists) and practitioners (front-line interpreters embedded with the Ukrainian Armed Forces). We kindly invite you to this exciting event. The symposium is supported by the Center for Global Studies and the Russian, East European, and Eurasian Center at the University of Illinois. For a full lineup of the symposium, please see the attached flyer.</span></p><p id=\"isPasted\"><strong>April 21:</strong><strong style=\"font-size: inherit; background-color: transparent;\">&nbsp;</strong></p><p><span style=\"background-color: transparent;\"><strong style=\"font-size: inherit;\">11:00 AM CT:</strong> Yaryna Zakalska: \"The Ukrainian Language as an Effective Weapon of Bloggers, Volunteers, and Actors in the Right Against the Enemy.\" (Assistant Professor in the Department of Folklore Studies at the Taras Shevchenko National University of Kyiv)</span></p><p><span style=\"background-color: transparent;\"><strong>12:00 PM CT:&nbsp;</strong>Serhii Yanchuk: \"Russia's War on Ukraine: Developments on the Language Front\" (Associate Professor, Institute of Philology, Taras Shevchenko National University of Kyiv, Currently&nbsp;Serving&nbsp;on the Front Lines of Ukraine)</span></p><p>For the program, registration link, and other information, please see the symposium webpage:<br id=\"isPasted\"><a data-auth=\"NotApplicable\" data-linkindex=\"0\" data-ogsc=\"\" data-safelink=\"true\" href=\"https://cgs.illinois.edu/spotlight/global-intersections-project/symposium-ukrainian-cultural-and-linguistic-shift\" id=\"LPlnk108020\" rel=\"noopener noreferrer\" target=\"_blank\">https://cgs.illinois.edu/spotlight/global-intersections-project/symposium-ukrainian-cultural-and-linguistic-shift</a>.</p>",
      instructions: 'Viva Ukraina!',
      imageUrl: 'https://api-dev.rokwire.illinois.edu/events/642ff8e73b037c000961c6c3/images/6447b33d3b037c000a2b1a5e',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-08T17:00:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-08T18:00:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Recreation, Health & Fitness', 'Exhibits', 'Performances'],
        'recreation-health-fitness': 'Aquatics',
        'college': 'Medicine at UIUC',
        'department': 'Internal Medicine',
      },
      location: ExploreLocation(building: 'College of Fine and Applied Arts Performing Arts Annex', room: '120',
        fullAddress: '1301 S Goodwin Ave  Urbana, IL 61801',
        latitude: 40.102062, longitude: -88.224815),
      required: true, canceled: false, private: false, free: true, online: false,
      sponsor: 'Center for Global Studies; Russian, East European, and Eurasian Center',
      speaker: 'Yaryna Zakalaska (Assistant Professor in the Department of Folklore Studies at the Taras Shevchenko National University of Kyiv); Serhii Yanchuk (Associate Professor, Institute of Philology, Taras Shevchenko National University of Kyiv, Currently Serving on the Front Lines of Ukraine)',
      contacts: <Contact>[
        Contact(firstName: 'REEEC', lastName: null, email: 'reeec@illinois.edu'),
      ],
    ),
    Event2(id: '3',
      name: 'GLBL 298 Costa Rica Winter Break Short-term Faculty-Led Study Abroad Info Session',
      description: "<p class=\"_04xlpA direction-ltr align-center para-style-body\" id=\"isPasted\"><span class=\"S1PPyQ\">Interested in Migration,</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span><span class=\"S1PPyQ\">Development, Social Justice,</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span><span class=\"S1PPyQ\">Urban Studies</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span>and Sustainability?</p><p class=\"_04xlpA direction-ltr align-center para-style-body\">This Short-term faculty-led GLBL 298 course on Migrations and Development Dilemmas in Costa Rica could be the perfect fit for you! Join LAS International Programs and Professor Nikolai Alvarado as we go over course/program specifics such as coursework, program objectives, brief background into La Carpio, San Jose, &nbsp;program dates, application requirements/expectations, and more!</p><p class=\"_04xlpA direction-ltr align-center para-style-body\">You won't want to miss out on this great opportunity!</p>",
      instructions: 'Hurry slowly',
      imageUrl: 'https://api-dev.rokwire.illinois.edu/events/642810183b037c000961c5cf/images/6447b33e3b037c0007363c02',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T19:30:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T23:00:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Conferences & Workshops', 'Film Screenings', 'Club Athletics'],
        'sport': 'Wrestling',
        'college': 'University Library',
        'department': 'Library Research & Publication',
      },
      location: ExploreLocation(building: 'La Casa Cultural Latina', room: '104 (Living Room)',
        fullAddress: '1203 W Nevada St, Urbana, IL 61801',
        latitude: 40.1057519, longitude: -88.2243409,
      ),
      required: false, canceled: false, private: false, free: true, online: false,
      sponsor: 'LAS International Programs',
      speaker: 'Nikolai Alvarado',
      contacts: <Contact>[
        Contact(firstName: 'LAS', lastName: 'International', email: 'las-studyabroad@illinois'),
      ],
    ),
    Event2(id: '4',
      name: "Seminar: Leilani Cannon, Director, Business Development, Essent Biologics: \"Bridging the Gap Between Benchtop to Biological Asset\"",
      description: "<p><a href=\"https://illinois.zoom.us/j/88093730478?pwd=YnBtaXlNR3IycDRac3FxZTBaRzlCZz09\">Online</a></p><p>Meeting Password: 219706</p><p>All members of the Illinois Computer Science department - faculty, staff, and students - are expected to adhere to the&nbsp;<a href=\"https://cs.illinois.edu/about/values\"><strong>CS Values and Code of Conduct</strong></a>. The&nbsp;<a href=\"https://cs.illinois.edu/about/cs-cares\"><strong>CS CARES Committee</strong></a> is available to serve as a resource to help people who are concerned about or experience a potential violation of the Code. During CS CARES Office Hours, CS Community Members (students, faculty, and staff) are welcome to confidentially meet with CS CARES committee members to discuss their experiences in the CS department. To learn more about CS CARES, other ways to contact the committee, and the Standards of Ethics, Confidentiality, and Conflicts of Interest, <a href=\"https://cs.illinois.edu/about/cs-cares\">please visit the CS CARES webpage</a>.</p><p>For general inquiries (scheduling, issues with accessing office hours, non-confidential inquiries), please contact&nbsp;<strong><a href=\"mailto:ccoleman@illinois.edu\">Cynthia Coleman</a>.</strong></p>",
      instructions: 'Die hard',
      imageUrl: 'https://api-dev.rokwire.illinois.edu/events/6422d81f19d1670007b9d7aa/images/644904cbd6e8140009ba3119',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T21:00:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T22:30:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Conferences & Workshops', 'Ceremonies & Services', 'Performances'],
        'college': 'Education',
        'department': 'Curriculum and Instruction',
      },
      location: ExploreLocation(building: 'Thomas M. Siebel Center for Computer Science', room: 'Charles G. Miller Auditorium B102 CLSL',
        fullAddress: '201/205 N Goodwin Ave  Urbana, IL 61801',
        latitude: 40.11394, longitude: -88.22487,
      ),
      required: false, canceled: false, private: false, free: true, online: false,
      sponsor: 'UIUC',
      contacts: <Contact>[
        Contact(firstName: 'Laura', lastName: 'Martin', email: 'lmmartin@illinois.edu', phone: '217-265-0046'),
      ],
    ),
  ];


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