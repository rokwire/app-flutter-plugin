
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
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Events2 with Service implements NotificationsListener {

  static const String notifyLaunchDetail  = "edu.illinois.rokwire.event2.launch_detail";
  static const String notifyChanged  = "edu.illinois.rokwire.event2.changed";

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

  Future<Events2ListResult?> loadEvents(Events2Query? query) async {
    if (Storage().debugUseSampleEvents2 == true) {
      List<Event2> sampleEvents = _sampleEvents;
      int index = 0, limit = query?.limit ?? _sampleEvents.length;
      List<Event2> result = <Event2>[];
      while (result.length < limit) {
        result.add(sampleEvents[index]);
        index = (index + 1) % sampleEvents.length;
      }
      await Future.delayed(const Duration(seconds: 1));
      return Events2ListResult(
        events: result,
        totalCount: result.length
      );
    }
    else if (Config().calendarUrl != null) {
      String? body = JsonUtils.encode(query?.toQueryJson());
      Map<String, String?> headers = {"Accept": "application/json", "Content-type": "application/json"};
      Response? response = await Network().post("${Config().calendarUrl}/events/load", body: body, headers: headers, auth: Auth2());
      //TMP: debugPrint("$body => ${response?.statusCode} ${response?.body}", wrapWidth: 256);
      dynamic responseJson = JsonUtils.decode((response?.statusCode == 200) ? response?.body : null);
      if (responseJson is Map) {
        return Events2ListResult.fromJson(JsonUtils.mapValue(responseJson));
      }
      else if (responseJson is List) {
        return Events2ListResult(events: Event2.listFromJson(JsonUtils.listValue(responseJson)));
      }
      else {
        return null;
      }
    }
    return null;
  }

  List<Event2> get _sampleEvents => <Event2>[
    Event2(id: '1',
      name: 'Illinois CS Girls Who Code Club',
      description: "<p>Illinois Computer Science hosts a chapter of Girls Who Code (girlswhocode.com), a club that allows middle school and high school girls to explore coding in a fun and friendly environment. The goal is to inspire, educate, and equip girls with the computing skills to pursue 21st century opportunities. The Illinois Computer Science Girls Who Code club is full for the 2022-23 school year.</p>",
      instructions: 'Take it easy',
      imageUrl: 'https://rokwire-images.s3.us-east-2.amazonaws.com/event/tout/088b5d28-de44-11eb-9bf2-0a58a9feac02.webp',
      timezone: 'America/Chicago',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-07T16:30:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-07T18:30:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Big 10 Athletics', 'Campus Visits', 'Performances'],
        'sport': 'Wrestling',
        'college': 'Liberal Arts & Sciences',
        'department': 'Astronomy',
      },
      eventType: Event2Type.inPerson,
      location: ExploreLocation(building: 'Davenport Hall', room: '206A',
        fullAddress: '607 S Mathews Ave  Urbana, IL 61801',
        latitude: 40.1072, longitude: -88.2262,
      ),
      canceled: false, private: false, free: true,
      sponsor: 'Computer Science',
      speaker: 'Dr. Hong Hao',
      contacts: <Event2Contact>[
        Event2Contact(firstName: 'Cynthia', lastName: 'Coleman', email: 'ccoleman@illinois.edu'),
      ],
    ),
    Event2(id: '2',
      name: 'Away from the Empire: The Linguistic and Cultural Shift in Ukraine in the Wake of the Russian Invasion: Yaryna Zakalska and Serhii Yanchuk',
      description: "<p id=\"isPasted\"><span style=\"font-size: inherit; background-color: transparent;\">The Russian-Ukrainian war of the 21st century aimed not only to physically destroy Ukraine but also to expand the linguistic borders of the \u201cRussian world,\u201d denationalize Ukraine, and reestablish the cultural dominance of Russia over the Ukrainian people. The war that began in 2014 and intensified in the last year's invasion has led to a cultural and linguistic shift from Russian to Ukrainian among much of the Ukrainian population. On April 19, 21, and 26, 2023, the University of Illinois at Urbana-Champaign will host a virtual symposium titled \"Away from the Empire: The Linguistic and Cultural Shift in Ukraine in the Wake of the Russian Invasion\" that will explore this topic. The symposium will feature seven Ukrainian scholars (linguists, sociologists, literary scholars, ethnologists, and political scientists) and practitioners (front-line interpreters embedded with the Ukrainian Armed Forces). We kindly invite you to this exciting event. The symposium is supported by the Center for Global Studies and the Russian, East European, and Eurasian Center at the University of Illinois. For a full lineup of the symposium, please see the attached flyer.</span></p><p id=\"isPasted\"><strong>April 21:</strong><strong style=\"font-size: inherit; background-color: transparent;\">&nbsp;</strong></p><p><span style=\"background-color: transparent;\"><strong style=\"font-size: inherit;\">11:00 AM CT:</strong> Yaryna Zakalska: \"The Ukrainian Language as an Effective Weapon of Bloggers, Volunteers, and Actors in the Right Against the Enemy.\" (Assistant Professor in the Department of Folklore Studies at the Taras Shevchenko National University of Kyiv)</span></p><p><span style=\"background-color: transparent;\"><strong>12:00 PM CT:&nbsp;</strong>Serhii Yanchuk: \"Russia's War on Ukraine: Developments on the Language Front\" (Associate Professor, Institute of Philology, Taras Shevchenko National University of Kyiv, Currently&nbsp;Serving&nbsp;on the Front Lines of Ukraine)</span></p><p>For the program, registration link, and other information, please see the symposium webpage:<br id=\"isPasted\"><a data-auth=\"NotApplicable\" data-linkindex=\"0\" data-ogsc=\"\" data-safelink=\"true\" href=\"https://cgs.illinois.edu/spotlight/global-intersections-project/symposium-ukrainian-cultural-and-linguistic-shift\" id=\"LPlnk108020\" rel=\"noopener noreferrer\" target=\"_blank\">https://cgs.illinois.edu/spotlight/global-intersections-project/symposium-ukrainian-cultural-and-linguistic-shift</a>.</p>",
      instructions: 'Viva Ukraina!',
      imageUrl: 'https://api-dev.rokwire.illinois.edu/events/642ff8e73b037c000961c6c3/images/6447b33d3b037c000a2b1a5e',
      timezone: 'America/Chicago',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-08T17:00:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-08T18:00:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Recreation, Health & Fitness', 'Exhibits', 'Performances'],
        'recreation-health-fitness': 'Aquatics',
        'college': 'Medicine at UIUC',
        'department': 'Internal Medicine',
      },
      eventType: Event2Type.inPerson,
      location: ExploreLocation(building: 'College of Fine and Applied Arts Performing Arts Annex', room: '120',
        fullAddress: '1301 S Goodwin Ave  Urbana, IL 61801',
        latitude: 40.102062, longitude: -88.224815),
      canceled: false, private: false, free: true,
      sponsor: 'Center for Global Studies; Russian, East European, and Eurasian Center',
      speaker: 'Yaryna Zakalaska (Assistant Professor in the Department of Folklore Studies at the Taras Shevchenko National University of Kyiv); Serhii Yanchuk (Associate Professor, Institute of Philology, Taras Shevchenko National University of Kyiv, Currently Serving on the Front Lines of Ukraine)',
      contacts: <Event2Contact>[
        Event2Contact(firstName: 'REEEC', lastName: null, email: 'reeec@illinois.edu'),
      ],
    ),
    Event2(id: '3',
      name: 'GLBL 298 Costa Rica Winter Break Short-term Faculty-Led Study Abroad Info Session',
      description: "<p class=\"_04xlpA direction-ltr align-center para-style-body\" id=\"isPasted\"><span class=\"S1PPyQ\">Interested in Migration,</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span><span class=\"S1PPyQ\">Development, Social Justice,</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span><span class=\"S1PPyQ\">Urban Studies</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span>and Sustainability?</p><p class=\"_04xlpA direction-ltr align-center para-style-body\">This Short-term faculty-led GLBL 298 course on Migrations and Development Dilemmas in Costa Rica could be the perfect fit for you! Join LAS International Programs and Professor Nikolai Alvarado as we go over course/program specifics such as coursework, program objectives, brief background into La Carpio, San Jose, &nbsp;program dates, application requirements/expectations, and more!</p><p class=\"_04xlpA direction-ltr align-center para-style-body\">You won't want to miss out on this great opportunity!</p>",
      instructions: 'Hurry slowly',
      imageUrl: 'https://api-dev.rokwire.illinois.edu/events/642810183b037c000961c5cf/images/6447b33e3b037c0007363c02',
      timezone: 'America/Chicago',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T19:30:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T23:00:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Conferences & Workshops', 'Film Screenings', 'Club Athletics'],
        'sport': 'Wrestling',
        'college': 'University Library',
        'department': 'Library Research & Publication',
      },
      eventType: Event2Type.inPerson,
      location: ExploreLocation(building: 'La Casa Cultural Latina', room: '104 (Living Room)',
        fullAddress: '1203 W Nevada St, Urbana, IL 61801',
        latitude: 40.1057519, longitude: -88.2243409,
      ),
      canceled: false, private: false, free: true,
      sponsor: 'LAS International Programs',
      speaker: 'Nikolai Alvarado',
      contacts: <Event2Contact>[
        Event2Contact(firstName: 'LAS', lastName: 'International', email: 'las-studyabroad@illinois'),
      ],
    ),
    Event2(id: '4',
      name: 'GLBL 298 Costa Rica Winter Break Short-term Faculty-Led Study Abroad Info Session',
      description: "<p class=\"_04xlpA direction-ltr align-center para-style-body\" id=\"isPasted\"><span class=\"S1PPyQ\">Interested in Migration,</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span><span class=\"S1PPyQ\">Development, Social Justice,</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span><span class=\"S1PPyQ\">Urban Studies</span><span class=\"S1PPyQ white-space-prewrap\">&nbsp;</span>and Sustainability?</p><p class=\"_04xlpA direction-ltr align-center para-style-body\">This Short-term faculty-led GLBL 298 course on Migrations and Development Dilemmas in Costa Rica could be the perfect fit for you! Join LAS International Programs and Professor Nikolai Alvarado as we go over course/program specifics such as coursework, program objectives, brief background into La Carpio, San Jose, &nbsp;program dates, application requirements/expectations, and more!</p><p class=\"_04xlpA direction-ltr align-center para-style-body\">You won't want to miss out on this great opportunity!</p>",
      instructions: 'Hurry slowly',
      imageUrl: 'https://api-dev.rokwire.illinois.edu/events/642810183b037c000961c5cf/images/6447b33e3b037c0007363c02',
      timezone: 'America/Chicago',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T19:30:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-09T23:00:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Conferences & Workshops', 'Film Screenings', 'Club Athletics'],
        'sport': 'Wrestling',
        'college': 'University Library',
        'department': 'Library Research & Publication',
      },
      eventType: Event2Type.inPerson,
      location: ExploreLocation(building: 'La Casa Cultural Latina', room: '104 (Living Room)',
        fullAddress: '1203 W Nevada St, Urbana, IL 61801',
        latitude: 40.1057519, longitude: -88.2243409,
      ),
      canceled: false, private: false, free: true,
      sponsor: 'LAS International Programs',
      speaker: 'Nikolai Alvarado',
      contacts: <Event2Contact>[
        Event2Contact(firstName: 'LAS', lastName: 'International', email: 'las-studyabroad@illinois'),
      ],
    ),
    Event2(id: '5',
      name: "Astrophysics, Gravitation and Cosmology Seminar - Cosimo Bambi (Fudan University) \"Testing General Relativity with black hole X-ray data\"",
      description: "<p>The theory of General Relativity has successfully passed a large number of observational tests. The theory has been extensively tested in the weak-field regime with experiments in the Solar System and observations of binary pulsars. The past 6-7 years have seen significant advancements in the study of the strong-field regime, which can now be tested with gravitational waves, X-ray data, and mm Very Long Baseline Interferometry observations. In my talk, I will summarize the state-of-the-art of the tests of General Relativity with black hole X-ray data, discussing its recent progress and future developments.</p>",
      instructions: 'Freedom or Death!',
      imageUrl: null,
      timezone: 'America/Chicago',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-14T22:00:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-14T23:30:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Club Athletics', 'Big 10 Athletics'],
        'sport': ["Men's Cross Country"],
        'college': 'Auxiliary Units',
        'department': 'Parking Department',
      },
      eventType: Event2Type.inPerson,
      location: ExploreLocation(building: 'Parking Structure, Lot C7', room: null,
        fullAddress: '517 E John St  Champaign, IL 61820',
        latitude: 40.108772, longitude: -88.23081,
      ),
      canceled: false, private: false, free: true,
      sponsor: 'Department of Physics',
      speaker: 'Cosimo Bambi',
      contacts: <Event2Contact>[
        Event2Contact(firstName: 'Brandy', lastName: 'Koebbe', email: 'bkoebbe@illinois.edu'),
      ],
    ),
    Event2(id: '6',
      name: "ACCOUNTING: Journal Voucher Processing Session 3",
      description: "<p><strong>Instructor(s): Jason Bane</strong></p><hr><p><strong>&nbsp;Course Prerequisites:</strong><br><a href=\"https://www.obfs.uillinois.edu/training/materials/intro-banner-finance\" rel=\"noopener noreferrer\" target=\"_blank\"><strong>FN 101: Introduction to Banner and Finance I</strong></a> (online)<br><strong><a href=\"https://www.obfs.uillinois.edu/cms/One.aspx?portalId=77176&pageId=91714#advancedc-foapal\" rel=\"noopener noreferrer\" target=\"_blank\">FN 102: Introduction to Banner and Finance II</a></strong></p><hr><p><strong>&nbsp;Course Description:</strong><br>This course is fundamental for users that enter Journal Vouchers. Users will practice creating Journal Vouchers using the entry forms in Banner, as well as learn how to determine if completed documents are successfully posted. Other topics include deleting incomplete journal vouchers, completing incomplete journal vouchers, copying journal vouchers, and performing queries for journal vouchers in Banner. Participants will need their Net ID and password.</p><hr><p><strong>Bring to Session (Required):</strong><br>Printed copy of <strong><a href=\"https://www.obfs.uillinois.edu/common/pages/DisplayFile.aspx?itemId=96013\" rel=\"noopener noreferrer\" target=\"_blank\">GL 101 Participant Guide</a></strong><br>Net ID and password</p><hr><p><strong>Bring to Session (Optional):</strong><br>Job Aid: <strong><a href=\"https://www.obfs.uillinois.edu/common/pages/DisplayFile.aspx?itemId=95870\" rel=\"noopener noreferrer\" target=\"_blank\">Creating a Journal Voucher with FGAJVCD and FGAJVCQ</a></strong><br>Handout: <strong><a href=\"https://www.obfs.uillinois.edu/common/pages/DisplayFile.aspx?itemId=95856\" rel=\"noopener noreferrer\" target=\"_blank\">Approval Process for Journal Vouchers Involving Grant Funds</a></strong></p><hr><p><strong>CPE Statement:</strong><br>The Office of Business and Financial Services is an Illinois Public Accountant Continuing Professional Education (CPE) sponsor and can offer CPE credit to Certified Public Accountant (CPA) participants in this course.</p>",
      instructions: 'Venceremos!',
      imageUrl: null,
      timezone: 'America/Chicago',
      startTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-15T22:00:00Z', isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString('2023-06-15T23:30:00Z', isUtc: true),
      attributes: <String, dynamic>{
        'category': ['Club Athletics', 'Big 10 Athletics'],
        'sport': ["Men's Cross Country"],
        'college': 'Auxiliary Units',
        'department': 'Parking Department',
      },
      eventType: Event2Type.online,
      onlineDetails: Event2OnlineDetails(
        url: 'https://uillinois.abilitylms.com/UIllinois/LearnerWeb_PTM.php?ActionID=Module&SegmentID=CourseHomePage&CourseID=UAFR_JVP_S3_ONLINE',
        meetingId: '78FPU395',
        meetingPasscode: 'mv7@ntys0_34'
      ),
      canceled: false, private: false, free: true,
      registrationDetails: Event2RegistrationDetails(
        type: Event2RegistrationType.external,
        label: 'Please register to attend the event.',
        externalLink: 'https://uillinois.abilitylms.com/UIllinois/LearnerWeb_PTM.php?ActionID=Module&SegmentID=CourseHomePage&CourseID=UAFR_JVP_S3_ONLINE',
        eventCapacity: 50,
      ),
      sponsor: 'Learning Systems Support',
    ),
  ];

  Future<Event2?> loadEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String? body = JsonUtils.encode({
        "ids":[eventId]
      });
      Map<String, String?> headers = {"Accept": "application/json", "Content-type": "application/json"};
      Response? response = await Network().post("${Config().calendarUrl}/events/load", body: body, headers: headers, auth: Auth2());
      List<Event2>? resultList;
      dynamic responseJson = JsonUtils.decode((response?.statusCode == 200) ? response?.body : null);
      if (responseJson is Map) {
        resultList = Events2ListResult.fromJson(JsonUtils.mapValue(responseJson))?.events;
      }
      else if (responseJson is List) {
        resultList = Event2.listFromJson(JsonUtils.listValue(responseJson));
      }
      return ((resultList != null) && resultList.isNotEmpty) ? resultList.first : null;
    }
    return null;
  }

  // Returns Event2 in case of success, String description in case of error
  Future<dynamic> createEvent(Event2? source) async {
    if (Config().calendarUrl != null) {
      String? body = JsonUtils.encode(source?.toJson());
      Map<String, String?> headers = {"Accept": "application/json", "Content-type": "application/json"};
      Response? response = await Network().post("${Config().calendarUrl}/event", body: body, headers: headers, auth: Auth2());
      Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return Event2.fromJson(responseJson);
      }
      else {
        String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
        return message ?? response?.body;
      }
    }
    return null;
  }

  //Return error message, null if successful
  Future<dynamic> deleteEvent(String eventId) async{
    if (Config().calendarUrl != null) { //TBD this is deprecated API. Hook to the new one when available
      Map<String, String?> headers = {"Accept": "application/json", "Content-type": "application/json"};
      Response? response = await Network().delete("${Config().calendarUrl}/event/$eventId", headers: headers, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return null;
      }
      else {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
        return message ?? response?.body;
      }
    }
    return "Missing calendar url";
  }

  //Return error message, null if successful
  Future<dynamic> registerToEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      String? body = JsonUtils.encode({
        'event_id': eventId,
      });
      Map<String, String?> headers = {"Accept": "application/json", "Content-type": "application/json"};
      Response? response = await Network().post("${Config().calendarUrl}/event-person/register", body: body, headers: headers, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return null;
      }
      else {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
        return message ?? response?.body;
      }
    }
    return  "Missing calendar url";
  }

  //Return error message, null if successful
  Future<dynamic> unregisterFromEvent(String eventId) async {
    if (Config().calendarUrl != null) {
      Map<String, String?> headers = {"Accept": "application/json", "Content-type": "application/json"};
      String url = "${Config().calendarUrl}/event-person/unregister/$eventId";
      Response? response = await Network().delete(url, headers: headers, auth: Auth2());
      if (response?.statusCode == 200) {
        NotificationService().notify(notifyChanged);
        return null;
      }
      else {
        Map<String, dynamic>? responseJson = JsonUtils.decodeMap(response?.body);
        String? message = (responseJson != null) ? JsonUtils.stringValue(responseJson['message']) : null;
        return message ?? response?.body;
      }
    }
    return "Missing calendar url";
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

  Events2Query({this.searchText,
    this.types, this.location,
    this.timeFilter = Event2TimeFilter.upcoming, this.customStartTimeUtc, this.customEndTimeUtc,
    this.attributes,
    this.sortType, this.sortOrder = Event2SortOrder.ascending,
    this.offset = 0, this.limit
  });

  Map<String, dynamic> toQueryJson() {
    Map<String, dynamic> options = <String, dynamic>{};

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
      options['type'] = event2TypeToString(Event2Type.inPerson);
    }
    else if (types.contains(Event2TypeFilter.online)) {
      options['type'] = event2TypeToString(Event2Type.online);
    }
    else if (types.contains(Event2TypeFilter.hybrid)) {
      options['type'] = event2TypeToString(Event2Type.hybrid);
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