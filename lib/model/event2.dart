import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2 with Explore, Favorite {
  final String? id;
  final String? name;
  final String? description;
  final String? instructions;
  final String? imageUrl;
  final String? eventUrl;

  final String? timezone;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final bool? allDay;

  final Event2Type? eventType;
  final ExploreLocation? location;
  final Event2OnlineDetails? onlineDetails;

  final Event2Grouping? grouping;
  final Map<String, dynamic>? attributes;

  Event2AuthorizationContext? authorizationContext;
  Event2Context? context;

  final bool? canceled;
  final bool? published;
  final Event2UserRole? userRole;

  final bool? free;
  final String? cost;

  final Event2RegistrationDetails? registrationDetails;
  final Event2AttendanceDetails? attendanceDetails;
  final Event2SurveyDetails? surveyDetails;

  final String? sponsor;
  final String? speaker;
  final List<Event2Contact>? contacts;

  final Event2Source? source;
  final Map<String, dynamic>? data;
  final List<Event2NotificationSetting>? notificationSettings;

  String? assignedImageUrl;

  Event2({
    this.id, this.name, this.description, this.instructions, this.imageUrl, this.eventUrl,
    this.timezone, this.startTimeUtc, this.endTimeUtc, this.allDay,
    this.eventType, this.location, this.onlineDetails, 
    this.grouping, this.attributes, this.authorizationContext, this.context,
    this.canceled, this.published, this.userRole,
    this.free, this.cost,
    this.registrationDetails, this.attendanceDetails, this.surveyDetails,
    this.sponsor, this.speaker, this.contacts,
    this.source, this.data, this.notificationSettings
  });

  factory Event2.fromOther(Event2? event, {
    String? name, String? description, String? instructions, String? imageUrl, String? eventUrl,
    String? timezone, DateTime? startTimeUtc, DateTime? endTimeUtc, bool? allDay,
    Event2Type? eventType, ExploreLocation? location, Event2OnlineDetails? onlineDetails,
    Event2Grouping? grouping, Map<String, dynamic>? attributes, Event2AuthorizationContext? authorizationContext, Event2Context? context,
    bool? canceled, bool? published, Event2UserRole? userRole,
    bool? free, String? cost,
    Event2RegistrationDetails? registrationDetails, Event2AttendanceDetails? attendanceDetails, Event2SurveyDetails? surveyDetails,
    String? sponsor, String? speaker, List<Event2Contact>? contacts,
    Event2Source? source, Map<String, dynamic>? data, List<Event2NotificationSetting>? notificationSettings,
  }) => Event2(
    name: name ?? event?.name,
    description: description ?? event?.description,
    instructions: instructions ?? event?.instructions,
    imageUrl: imageUrl ?? event?.imageUrl,
    eventUrl: eventUrl ?? event?.eventUrl,

    timezone: timezone ?? event?.timezone,
    startTimeUtc: startTimeUtc ?? event?.startTimeUtc,
    endTimeUtc: endTimeUtc ?? event?.endTimeUtc,
    allDay: allDay ?? event?.allDay,

    eventType: eventType ?? event?.eventType,
    location: location ?? event?.location,
    onlineDetails: onlineDetails ?? event?.onlineDetails,

    grouping: grouping ?? event?.grouping,
    attributes: attributes ?? event?.attributes?.duplicatedAttributes,
    authorizationContext: authorizationContext ?? ((event?.authorizationContext != null) ? Event2AuthorizationContext.fromOther(event?.authorizationContext) : null),
    context: context ?? ((event?.context != null) ? Event2Context.fromOther(event?.context) : null),

    canceled: canceled ?? event?.canceled,
    published: published ?? event?.published,
    userRole: userRole ?? event?.userRole,

    free: free ?? event?.free,
    cost: cost ?? event?.cost,

    registrationDetails: registrationDetails ?? Event2RegistrationDetails.fromOther(event?.registrationDetails) ,
    attendanceDetails: attendanceDetails ?? Event2AttendanceDetails.fromOther(event?.attendanceDetails) ,
    surveyDetails: surveyDetails ?? Event2SurveyDetails.fromOther(event?.surveyDetails),

    sponsor: sponsor ?? event?.sponsor,
    speaker: speaker ?? event?.speaker,
    contacts: contacts ?? ListUtils.from(event?.contacts),

    source: source ?? event?.source,
    data: data ?? MapUtils.from(event?.data),
    notificationSettings: notificationSettings ?? ListUtils.from(event?.notificationSettings),
  );

  // JSON serialization

  static Event2? fromJson(Map<String, dynamic>? json) => (json != null) ? Event2(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      description: JsonUtils.stringValue(json['description']),
      instructions: JsonUtils.stringValue(json['instructions']),
      imageUrl: JsonUtils.stringValue(json['image_url']),
      eventUrl: JsonUtils.stringValue(json['event_url']),

      timezone: JsonUtils.stringValue(json['timezone']),
      startTimeUtc: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['start'])),
      endTimeUtc: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['end'])),
      allDay: JsonUtils.boolValue(json['all_day']),

      eventType: event2TypeFromString(JsonUtils.stringValue(json['event_type'])),
      location: ExploreLocation.fromJson(JsonUtils.mapValue(json['location'])),
      onlineDetails: Event2OnlineDetails.fromJson(JsonUtils.mapValue(json['online_details'])),

      grouping: Event2Grouping.fromJson(JsonUtils.mapValue(json['grouping'])),
      attributes: JsonUtils.mapValue(json['attributes']),
      authorizationContext: Event2AuthorizationContext.fromJson(JsonUtils.mapValue(json['authorization_context'])),
      context: Event2Context.fromJson(JsonUtils.mapValue(json['context'])),

      canceled: JsonUtils.boolValue(json['canceled']),
      published: JsonUtils.boolValue(json['published']),
      userRole: event2UserRoleFromString(JsonUtils.stringValue(json['role'])),

      free: JsonUtils.boolValue(json['free']),
      cost: JsonUtils.stringValue(json['cost']),

      registrationDetails: Event2RegistrationDetails.fromJson(JsonUtils.mapValue(json['registration_details'])),
      attendanceDetails: Event2AttendanceDetails.fromJson(JsonUtils.mapValue(json['attendance_details'])),
      surveyDetails: Event2SurveyDetails.fromJson(JsonUtils.mapValue(json['survey_details'])),
      notificationSettings: Event2NotificationSetting.listFromJson(JsonUtils.listValue(json['notification_settings'])),

      sponsor: JsonUtils.stringValue(json['sponsor']),
      speaker: JsonUtils.stringValue(json['speaker']),
      contacts: Event2Contact.listFromJson(JsonUtils.listValue(json['contacts'])),

      source: event2SourceFromString(JsonUtils.stringValue(json['source'])),
      data: JsonUtils.mapValue(json['data']),

    ) : null;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'id', value: id);
    JsonUtils.addNonNullValue(json: json, key: 'name', value: name);
    JsonUtils.addNonNullValue(json: json, key: 'description', value: description);
    JsonUtils.addNonNullValue(json: json, key: 'instructions', value: instructions);
    JsonUtils.addNonNullValue(json: json, key: 'image_url', value: imageUrl);
    JsonUtils.addNonNullValue(json: json, key: 'event_url', value: eventUrl);

    JsonUtils.addNonNullValue(json: json, key: 'timezone', value: timezone);
    JsonUtils.addNonNullValue(json: json, key: 'start', value: DateTimeUtils.dateTimeToSecondsSinceEpoch(startTimeUtc));
    JsonUtils.addNonNullValue(json: json, key: 'end', value: DateTimeUtils.dateTimeToSecondsSinceEpoch(endTimeUtc));
    JsonUtils.addNonNullValue(json: json, key: 'all_day', value: allDay);

    JsonUtils.addNonNullValue(json: json, key: 'event_type', value: event2TypeToString(eventType));
    JsonUtils.addNonNullValue(json: json, key: 'location', value: location?.toJson());
    JsonUtils.addNonNullValue(json: json, key: 'online_details', value: onlineDetails?.toJson());

    JsonUtils.addNonNullValue(json: json, key: 'grouping', value: grouping?.toJson());
    JsonUtils.addNonNullValue(json: json, key: 'attributes', value: attributes);

    JsonUtils.addNonNullValue(json: json, key: 'authorization_context', value: authorizationContext?.toJson());
    JsonUtils.addNonNullValue(json: json, key: 'context', value: context?.toJson());

    //TBD: DD - the backend crashes if the field is missing. Leave it until it is fixed
    // Start
    JsonUtils.addNonNullValue(json: json, key: 'private', value: isPrivate);
    // End

    JsonUtils.addNonNullValue(json: json, key: 'canceled', value: canceled);
    JsonUtils.addNonNullValue(json: json, key: 'published', value: published);
    JsonUtils.addNonNullValue(json: json, key: 'role', value: event2UserRoleToString(userRole));

    JsonUtils.addNonNullValue(json: json, key: 'free', value: free);
    JsonUtils.addNonNullValue(json: json, key: 'cost', value: cost);

    JsonUtils.addNonNullValue(json: json, key: 'registration_details', value: registrationDetails?.toJson());
    JsonUtils.addNonNullValue(json: json, key: 'attendance_details', value: attendanceDetails?.toJson());
    JsonUtils.addNonNullValue(json: json, key: 'survey_details', value: surveyDetails?.toJson());
    JsonUtils.addNonNullValue(json: json, key: 'notification_settings', value: Event2NotificationSetting.listToJson(notificationSettings));

    JsonUtils.addNonNullValue(json: json, key: 'sponsor', value: sponsor);
    JsonUtils.addNonNullValue(json: json, key: 'speaker', value: speaker);
    JsonUtils.addNonNullValue(json: json, key: 'contacts', value: Event2Contact.listToJson(contacts));

    JsonUtils.addNonNullValue(json: json, key: 'source', value: event2SourceToString(source));
    JsonUtils.addNonNullValue(json: json, key: 'data', value: data);

    return json;
  }

  // Equality

  @override
  bool operator==(Object other) =>
    (other is Event2) &&
    (id == other.id) &&
    (name == other.name) &&
    (description == other.description) &&
    (instructions == other.instructions) &&
    (imageUrl == other.imageUrl) &&
    (eventUrl == other.eventUrl) &&
    
    (timezone == other.timezone) &&
    (startTimeUtc == other.startTimeUtc) &&
    (endTimeUtc == other.endTimeUtc) &&
    (allDay == other.allDay) &&

    (eventType == other.eventType) &&
    (location == other.location) &&
    (onlineDetails == other.onlineDetails) &&

    (grouping == other.grouping) &&
    (const DeepCollectionEquality().equals(attributes, other.attributes)) &&
    (authorizationContext == other.authorizationContext) &&
    (context == other.context) &&

    (canceled == other.canceled) &&
    (published == other.published) &&
    (userRole == other.userRole) &&

    (free == other.free) &&
    (cost == other.cost) &&

    Event2RegistrationDetails.equals(registrationDetails, other.registrationDetails) &&
    //(registrationDetails == other.registrationDetails) &&
    (attendanceDetails == other.attendanceDetails) &&
    (surveyDetails == other.surveyDetails) &&
    (notificationSettings == other.notificationSettings) &&

    (sponsor == other.sponsor) &&
    (speaker == other.speaker) &&
    (const DeepCollectionEquality().equals(contacts, other.contacts)) &&
    (source == other.source) &&
    (data == other.data);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (instructions?.hashCode ?? 0) ^
    (imageUrl?.hashCode ?? 0) ^
    (eventUrl?.hashCode ?? 0) ^

    (timezone?.hashCode ?? 0) ^
    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0) ^
    (allDay?.hashCode ?? 0) ^

    (eventType?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (onlineDetails?.hashCode ?? 0) ^

    (grouping?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(attributes)) ^
    (authorizationContext?.hashCode ?? 0) ^
    (context?.hashCode ?? 0) ^

    (canceled?.hashCode ?? 0) ^
    (published?.hashCode ?? 0) ^
    (userRole?.hashCode ?? 0) ^

    (free?.hashCode ?? 0) ^
    (cost?.hashCode ?? 0) ^

    (registrationDetails?.hashCode ?? 0) ^
    (attendanceDetails?.hashCode ?? 0) ^
    (surveyDetails?.hashCode ?? 0) ^
    (notificationSettings?.hashCode ?? 0) ^

    (sponsor?.hashCode ?? 0) ^
    (speaker?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(contacts)) ^

    (source?.hashCode ?? 0) ^
    (data?.hashCode ?? 0);

  // Attributes

  bool get isOnline => ((eventType == Event2Type.online) || (eventType == Event2Type.hybrid));
  bool get isInPerson => ((eventType == Event2Type.inPerson) || (eventType == Event2Type.hybrid));

  bool get isSuperEvent => (grouping?.type == Event2GroupingType.superEvent) && (grouping?.superEventId == null) && (id != null);
  bool get isSuperEventChild => (grouping?.type == Event2GroupingType.superEvent) && (grouping?.superEventId != null);
  bool get isRecurring => (grouping?.type == Event2GroupingType.recurrence) && (grouping?.recurrenceId != null);

  bool get isSportEvent => (source == Event2Source.sports_bb);

  bool get isPublic => authorizationContext?.isPublic ?? true;
  bool get isGroupMembersOnly => authorizationContext?.isGroupMembersOnly ?? false;
  bool get isGuestListOnly => authorizationContext?.isGuestListOnly ?? false;
  bool get isPrivate => isGroupMembersOnly || isGuestListOnly;
  bool get isGroupEvent => (context?.isGroupEvent == true);
  Set<String>? get groupIds => context?.groupIds;

  // JSON list searialization

  static List<Event2>? listFromJson(List<dynamic>? jsonList) {
    List<Event2>? result;
    if (jsonList != null) {
      result = <Event2>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event2.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event2>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (Event2 contentEntry in contentList) {
        jsonList.add(contentEntry.toJson());
      }
    }
    return jsonList;
  }

  // List lookup

  static int? indexInList(List<Event2>? contentList, { String? id}) {
    if (contentList != null) {
      for (int index = 0; index < contentList.length; index++) {
        Event2 contentEntry = contentList[index];
        if ((id != null) && (contentEntry.id == id)) {
          return index;
        }
      }
    }
    return null;
  }

  static Event2? findInList(List<Event2>? contentList, { String? id}) {
    int? index = indexInList(contentList, id: id);
    return ((contentList != null) && (index != null)) ? contentList[index] : null;
  }

  // Explore
  @override String?   get exploreId               => id;
  @override String?   get exploreTitle            => name;
  @override String?   get exploreDescription      => description;
  @override DateTime? get exploreDateTimeUtc      => startTimeUtc;
  @override String?   get exploreImageURL         => StringUtils.isNotEmpty(imageUrl) ? imageUrl : assignedImageUrl;
  @override ExploreLocation? get exploreLocation  { return location; }

  // Favorite
  static const String favoriteKeyName = "event2Ids";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;

  // Survey
  static const String followUpSurveyType = "event_follow_up";
}

///////////////////////////////
/// Event2Context

class Event2Context {
  final List<Event2ContextItem>? items;

  Event2Context({this.items});

  static Event2Context? fromJson(Map<String, dynamic>? json) => (json != null) ?
    Event2Context(items: Event2ContextItem.listFromJson(JsonUtils.listValue(json['items']))) : null;

  factory Event2Context.fromOther(Event2Context? other, {List<Event2ContextItem>? items}) => Event2Context(
    items: items ?? ListUtils.from(other?.items)
  );

  factory Event2Context.fromIdentifiers({List<String>? identifiers}) {
    List<Event2ContextItem>? items;
    if (identifiers != null) {
      items = <Event2ContextItem>[];
      for (String identifier in identifiers) {
        items.add(Event2ContextItem(name: Event2ContextItemName.group_member, identifier: identifier));
      }
    }
    return Event2Context(items: items);
  }

  Map<String, dynamic> toJson() => {'items': Event2ContextItem.listToJson(items)};

  bool get isGroupEvent =>
      (CollectionUtils.isNotEmpty(items) && (items!.firstWhereOrNull((item) => (item.name == Event2ContextItemName.group_member)) != null));

  Set<String>? get groupIds {
    Set<String>? groupIds;
    if (isGroupEvent) {
      groupIds = <String>{};
      for (Event2ContextItem item in items!) {
        if ((item.name == Event2ContextItemName.group_member) && StringUtils.isNotEmpty(item.identifier)) {
          groupIds.add(item.identifier!);
        }
      }
    }
    return groupIds;
  }

  @override
  bool operator ==(other) => (other is Event2Context) && const DeepCollectionEquality().equals(other.items, items);

  @override
  int get hashCode => (const DeepCollectionEquality().hash(items));
}

///////////////////////////////
/// Event2AuthorizationContext

class Event2AuthorizationContext {
  final Event2AuthorizationContextStatus? status;
  final List<Event2ContextItem>? items;
  final Event2ExternalAdmins? externalAdmins;

  Event2AuthorizationContext({this.status, this.items, this.externalAdmins});

  static Event2AuthorizationContext? fromJson(Map<String, dynamic>? json) => (json != null) ? Event2AuthorizationContext(
    status: event2AuthorizationContextStatusFromString(JsonUtils.stringValue(json['authorization_status'])),
    items: Event2ContextItem.listFromJson(JsonUtils.listValue(json['items'])),
    externalAdmins: Event2ExternalAdmins.fromJson(JsonUtils.mapValue(json['external_admins']))
  ) : null;

  factory Event2AuthorizationContext.fromOther(Event2AuthorizationContext? other, {
    Event2AuthorizationContextStatus? status,
    List<Event2ContextItem>? items,
    Event2ExternalAdmins? externalAdmins,
  }) => Event2AuthorizationContext(
    status: status ?? other?.status,
    items: items ?? ListUtils.from(other?.items),
    externalAdmins: externalAdmins ?? other?.externalAdmins,
  );

  factory Event2AuthorizationContext.none({Event2ExternalAdmins? externalAdmins}) =>
      Event2AuthorizationContext(status: Event2AuthorizationContextStatus.none, externalAdmins: externalAdmins);

  factory Event2AuthorizationContext.groupMember({List<String>? groupIds, Event2ExternalAdmins? externalAdmins}) {
    List<Event2ContextItem>? items;
    if (groupIds != null) {
      items = <Event2ContextItem>[];
      for (String groupId in groupIds) {
        items.add(Event2ContextItem(name: Event2ContextItemName.group_member, identifier: groupId));
      }
    }
    return Event2AuthorizationContext(status: Event2AuthorizationContextStatus.active, items: items, externalAdmins: externalAdmins);
  }

  factory Event2AuthorizationContext.registeredUser({Event2ExternalAdmins? externalAdmins}) => Event2AuthorizationContext(
      status: Event2AuthorizationContextStatus.active,
      items: [Event2ContextItem(name: Event2ContextItemName.registered_user)],
      externalAdmins: externalAdmins);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'authorization_status', value: event2AuthorizationContextStatusToString(status));
    JsonUtils.addNonNullValue(json: json, key: 'items', value: Event2ContextItem.listToJson(items));
    JsonUtils.addNonNullValue(json: json, key: 'external_admins', value: externalAdmins?.toJson());
    return json;
  }

  bool get isPublic => ((status == null) || status == Event2AuthorizationContextStatus.none);

  bool get isGuestListOnly =>
      ((status == Event2AuthorizationContextStatus.active) && CollectionUtils.isNotEmpty(items) &&
          (items!.firstWhereOrNull((item) => (item.name == Event2ContextItemName.registered_user)) != null));

  bool get isGroupMembersOnly =>
      ((status == Event2AuthorizationContextStatus.active) && CollectionUtils.isNotEmpty(items) &&
          (items!.firstWhereOrNull((item) => (item.name == Event2ContextItemName.group_member)) != null));

  @override
  bool operator ==(other) => (other is Event2AuthorizationContext) &&
      (other.status == status) &&
      const DeepCollectionEquality().equals(other.items, items) &&
      (other.externalAdmins == externalAdmins);

  @override
  int get hashCode => (status?.hashCode ?? 0) ^ (const DeepCollectionEquality().hash(items)) ^ (externalAdmins?.hashCode ?? 0);
}

///////////////////////////////
/// Event2ExternalAdmins

class Event2ExternalAdmins {
  final List<String>? groupIds;

  Event2ExternalAdmins({this.groupIds});

  static Event2ExternalAdmins? fromJson(Map<String, dynamic>? json) => (json != null) ? Event2ExternalAdmins(
      groupIds: JsonUtils.listStringsValue(json['groups-bb_groups-ids'])
  ) : null;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'groups-bb_groups-ids', value: groupIds);
    return json;
  }

  @override
  bool operator ==(other) => (other is Event2ExternalAdmins) && const DeepCollectionEquality().equals(other.groupIds, groupIds);

  @override
  int get hashCode => (const DeepCollectionEquality().hash(groupIds));
}

///////////////////////////////
/// Event2ContextItem

class Event2ContextItem {
  final Event2ContextItemName? name;
  final String? identifier;

  Event2ContextItem({this.name, this.identifier});

  static Event2ContextItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Event2ContextItem(
        name: event2ContextItemNameFromString(JsonUtils.stringValue(json['name'])),
        identifier: JsonUtils.stringValue(json['identifier']));
  }

  Map<String, dynamic> toJson() => {'name': event2ContextItemNameToString(name), 'identifier': StringUtils.ensureNotEmpty(identifier)};

  @override
  bool operator ==(other) => (other is Event2ContextItem) && (other.name == name) && (other.identifier == identifier);

  @override
  int get hashCode => (name?.hashCode ?? 0) ^ (identifier?.hashCode ?? 0);

  static List<Event2ContextItem>? listFromJson(List<dynamic>? jsonList) {
    List<Event2ContextItem>? result;
    if (jsonList != null) {
      result = <Event2ContextItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event2ContextItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event2ContextItem>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (Event2ContextItem contentEntry in contentList) {
        ListUtils.add(jsonList, contentEntry.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////////
/// Event2AuthorizationContextStatus

enum Event2AuthorizationContextStatus { active, none }

Event2AuthorizationContextStatus? event2AuthorizationContextStatusFromString(String? value) {
  if (value == 'NONE') {
    return Event2AuthorizationContextStatus.none;
  }
  else if (value == 'ACTIVE') {
    return Event2AuthorizationContextStatus.active;
  }
  else {
    return null;
  }
}

String? event2AuthorizationContextStatusToString(Event2AuthorizationContextStatus? value) {
  switch (value) {
    case Event2AuthorizationContextStatus.none: return 'NONE';
    case Event2AuthorizationContextStatus.active: return 'ACTIVE';
    default: return null;
  }
}

///////////////////////////////
/// Event2ContextItemName

enum Event2ContextItemName { group_member, registered_user }

Event2ContextItemName? event2ContextItemNameFromString(String? value) {
  if (value == 'groups-bb_group') {
    return Event2ContextItemName.group_member;
  }
  else if (value == 'registered-people') {
    return Event2ContextItemName.registered_user;
  }
  else {
    return null;
  }
}

String? event2ContextItemNameToString(Event2ContextItemName? value) {
  switch (value) {
    case Event2ContextItemName.group_member: return 'groups-bb_group';
    case Event2ContextItemName.registered_user: return 'registered-people';
    default: return null;
  }
}

///////////////////////////////
/// Event2OnlineDetails

class Event2OnlineDetails {
  final String? url;
  final String? meetingId;
  final String? meetingPasscode;

  Event2OnlineDetails({this.url, this.meetingId, this.meetingPasscode});

  static Event2OnlineDetails? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? Event2OnlineDetails(
      url: JsonUtils.stringValue(json['url']),
      meetingId: JsonUtils.stringValue(json['meeting_id']),
      meetingPasscode: JsonUtils.stringValue(json['meeting_passcode'])
    ) : null;

  Map<String, dynamic> toJson() => {
    'url': url,
    'meeting_id': meetingId,
    'meeting_passcode': meetingPasscode
  };

  @override
  bool operator==(Object other) =>
    (other is Event2OnlineDetails) &&
    (url == other.url) &&
    (meetingId == other.meetingId) &&
    (meetingPasscode == other.meetingPasscode);

  @override
  int get hashCode =>
    (url?.hashCode ?? 0) ^
    (meetingId?.hashCode ?? 0) ^
    (meetingPasscode?.hashCode ?? 0);
}

///////////////////////////////
/// Event2RegistrationDetails

class Event2RegistrationDetails {
  final Event2RegistrationType? type;
  final String? label;
  final String? externalLink;
  final int? eventCapacity;
  final List<String>? registrants; // external IDs

  Event2RegistrationDetails({this.type, this.label, this.externalLink, this.eventCapacity, this.registrants });

  factory Event2RegistrationDetails.empty() => Event2RegistrationDetails(type: Event2RegistrationType.none);

  static Event2RegistrationDetails? fromOther(Event2RegistrationDetails? other, {
    Event2RegistrationType? type,
    String? label, String? externalLink,
    int? eventCapacity,
    List<String>? registrants,
  }) =>
    (other != null) ? Event2RegistrationDetails(
      type: type ?? other.type,
      label: label ?? other.label,
      externalLink: externalLink ?? other.externalLink,
      eventCapacity: eventCapacity ?? other.eventCapacity,
      registrants: registrants ?? ListUtils.from(other.registrants),
    ) : null;

  static Event2RegistrationDetails? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? Event2RegistrationDetails(
      type: event2RegistrationTypeFromString(JsonUtils.stringValue(json['type'])),
      label: JsonUtils.stringValue(json['label']),
      externalLink: JsonUtils.stringValue(json['external_link']),
      eventCapacity: JsonUtils.intValue(json['max_event_capacity']),
      registrants: JsonUtils.listStringsValue(json['registrants_external_ids']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'type': event2RegistrationTypeToString(type),
    'label': label,
    'external_link': externalLink,
    'max_event_capacity': eventCapacity,
    'registrants_external_ids': registrants,
  };

  @override
  bool operator==(Object other) =>
    (other is Event2RegistrationDetails) &&
    (type == other.type) &&
    (label == other.label) &&
    (externalLink == other.externalLink) &&
    (eventCapacity == other.eventCapacity) &&
    (const DeepCollectionEquality().equals(registrants, other.registrants));

  @override
  int get hashCode =>
    (type?.hashCode ?? 0) ^
    (label?.hashCode ?? 0) ^
    (externalLink?.hashCode ?? 0) ^
    (eventCapacity?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(registrants));

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
    (type == Event2RegistrationType.internal) ||
    (type == Event2RegistrationType.external);

  static bool equals(Event2RegistrationDetails? details1, Event2RegistrationDetails? details2) =>
    ((details1 == null) && (details2 == null)) ||
    ((details1 != null) && (details2 != null) && (details1 == details2)) ||
    (details1?.type == Event2RegistrationType.none) ||
    (details2?.type == Event2RegistrationType.none);
}

///////////////////////////////
/// Event2RegistrationType

enum Event2RegistrationType { none, internal, external }

Event2RegistrationType? event2RegistrationTypeFromString(String? value) {
  if (value == 'none') {
    return Event2RegistrationType.none;
  }
  else if (value == 'internal') {
    return Event2RegistrationType.internal;
  }
  else if (value == 'external') {
    return Event2RegistrationType.external;
  }
  else {
    return null;
  }
}

String? event2RegistrationTypeToString(Event2RegistrationType? value) {
  switch (value) {
    case Event2RegistrationType.none: return 'none';
    case Event2RegistrationType.internal: return 'internal';
    case Event2RegistrationType.external: return 'external';
    default: return null;
  }
}

///////////////////////////////
/// Event2AttendanceDetails

class Event2AttendanceDetails {
  final bool? scanningEnabled;
  final bool? manualCheckEnabled;
  final bool? selfCheckEnabled;
  final bool? selfCheckLimitedToRegisteredOnly;
  final List<String>? attendanceTakers; // external IDs

  Event2AttendanceDetails({this.scanningEnabled, this.manualCheckEnabled, this.selfCheckEnabled, this.selfCheckLimitedToRegisteredOnly, this.attendanceTakers});

  static Event2AttendanceDetails? fromOther(Event2AttendanceDetails? other, {
    bool? scanningEnabled,
    bool? manualCheckEnabled,
    bool? selfCheckEnabled,
    bool? selfCheckLimitedToRegisteredOnly,
    List<String>? attendanceTakers,
  }) =>
    (other != null) ? Event2AttendanceDetails(
      scanningEnabled: scanningEnabled ?? other.scanningEnabled,
      manualCheckEnabled: manualCheckEnabled ?? other.manualCheckEnabled,
      selfCheckEnabled: selfCheckEnabled ?? other.selfCheckEnabled,
      selfCheckLimitedToRegisteredOnly: selfCheckLimitedToRegisteredOnly ?? other.selfCheckLimitedToRegisteredOnly,
      attendanceTakers: attendanceTakers ?? other.attendanceTakers,
    ) : null;

  static Event2AttendanceDetails? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? Event2AttendanceDetails(
      scanningEnabled: JsonUtils.boolValue(json['is_id_scanning_enabled']),
      manualCheckEnabled: JsonUtils.boolValue(json['is_manual_attendance_check_enabled']),
      selfCheckEnabled: JsonUtils.boolValue(json['is_self_check_enabled']),
      selfCheckLimitedToRegisteredOnly: JsonUtils.boolValue(json['is_self_check_limited_to_registered_only']),
      attendanceTakers: JsonUtils.listStringsValue(json['attendance_takers_external_ids']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'is_id_scanning_enabled': scanningEnabled,
    'is_manual_attendance_check_enabled': manualCheckEnabled,
    'is_self_check_enabled': selfCheckEnabled,
    'is_self_check_limited_to_registered_only': selfCheckLimitedToRegisteredOnly,
    'attendance_takers_external_ids': attendanceTakers,
  };

  @override
  bool operator==(Object other) =>
    (other is Event2AttendanceDetails) &&
    (scanningEnabled == other.scanningEnabled) &&
    (manualCheckEnabled == other.manualCheckEnabled) &&
    (selfCheckEnabled == other.selfCheckEnabled) &&
    (selfCheckLimitedToRegisteredOnly == other.selfCheckLimitedToRegisteredOnly) &&
    (const DeepCollectionEquality().equals(attendanceTakers, other.attendanceTakers));

  @override
  int get hashCode =>
    (scanningEnabled?.hashCode ?? 0) ^
    (manualCheckEnabled?.hashCode ?? 0) ^
    (selfCheckEnabled?.hashCode ?? 0) ^
    (selfCheckLimitedToRegisteredOnly?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(attendanceTakers));

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
    (scanningEnabled == true) || 
    (manualCheckEnabled == true) ||
    (selfCheckEnabled == true);
}

///////////////////////////////
/// Event2SurveyDetails

class Event2SurveyDetails {
  //TODO: remove survey ID from calendar BB
  final int? hoursAfterEvent;

  Event2SurveyDetails({this.hoursAfterEvent});

  static Event2SurveyDetails? fromOther(Event2SurveyDetails? other, {
    int? hoursAfterEvent
  }) => (other != null) ? Event2SurveyDetails(
    hoursAfterEvent: hoursAfterEvent ?? other.hoursAfterEvent,
  ) : null;

  static Event2SurveyDetails? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? Event2SurveyDetails(
      hoursAfterEvent: JsonUtils.intValue(json['hours_after_event']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'hours_after_event': hoursAfterEvent,
  };

  @override
  bool operator==(Object other) =>
    (other is Event2SurveyDetails) &&
    (hoursAfterEvent == other.hoursAfterEvent);

  @override
  int get hashCode =>
    (hoursAfterEvent?.hashCode ?? 0);

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
    (hoursAfterEvent != null) &&
    ((hoursAfterEvent ?? 0) >= 0);
}


///////////////////////////////
/// Event2Grouping

class Event2Grouping {
  static final String _ignoreFieldValue = 'ignore';
  static final String _noneFieldValue = 'none';

  final Event2GroupingType? type;
  final String? superEventId;
  final String? recurrenceId;
  final dynamic displayAsIndividual;

  Event2Grouping({this.type, this.superEventId, this.recurrenceId, this.displayAsIndividual});

  factory Event2Grouping.superEvent(String? id) => Event2Grouping(
    type: Event2GroupingType.superEvent,
    superEventId: id,
  );

  factory Event2Grouping.recurrence(String? id, {bool? individual}) => Event2Grouping(
    type: Event2GroupingType.recurrence,
    recurrenceId: id,
    displayAsIndividual: individual,
  );

  static List<Event2Grouping> superEvents({String? superEventId}) => <Event2Grouping>[
    Event2Grouping(
      type: Event2GroupingType.superEvent,
      superEventId: (superEventId != null) ? superEventId : _noneFieldValue,
      recurrenceId: _ignoreFieldValue,
      displayAsIndividual: _ignoreFieldValue
    )];

  static List<Event2Grouping> recurringEvents({String? groupId, bool? individual}) => <Event2Grouping>[
    Event2Grouping(
      type: Event2GroupingType.recurrence,
      superEventId: _ignoreFieldValue,
      recurrenceId: (groupId != null) ? groupId : _ignoreFieldValue,
      displayAsIndividual: (individual != null) ? individual.toString() : _ignoreFieldValue)
    ];

  static List<Event2Grouping> individualEvents() => <Event2Grouping>[
    // Events without grouping type
    Event2Grouping(type: Event2GroupingType.none, superEventId: _ignoreFieldValue, recurrenceId: _ignoreFieldValue, displayAsIndividual: _ignoreFieldValue),
    // Main Super Events
    Event2Grouping(type: Event2GroupingType.superEvent, superEventId: _noneFieldValue, recurrenceId: _ignoreFieldValue, displayAsIndividual: _ignoreFieldValue),
    // Sub Events when display as individual is true
    Event2Grouping(type: Event2GroupingType.superEvent, superEventId: _ignoreFieldValue, recurrenceId: _ignoreFieldValue, displayAsIndividual: 'true'), //explicitly String
    // Recurring events which shows as individuals - displayAsIndividual: true
    Event2Grouping(type: Event2GroupingType.recurrence, superEventId: _noneFieldValue, recurrenceId: _ignoreFieldValue, displayAsIndividual: 'true'),
    // Recurring events which have missing displayAsIndividual value
    Event2Grouping(type: Event2GroupingType.recurrence, superEventId: _noneFieldValue, recurrenceId: _ignoreFieldValue, displayAsIndividual: _noneFieldValue)
  ];

  static Event2Grouping? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? Event2Grouping(
      type: event2GroupingTypeFromString(JsonUtils.stringValue(json['grouping_type'])) ,
      superEventId: JsonUtils.stringValue(json['super_event_id']),
      recurrenceId: JsonUtils.stringValue(json['group_id']),
      displayAsIndividual: JsonUtils.boolValue(json['display_as_individual']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'grouping_type': event2GroupingTypeToString(type),
    'super_event_id': superEventId,
    'group_id': recurrenceId,
    'display_as_individual': (displayAsIndividual is bool) ? displayAsIndividual : displayAsIndividual?.toString(),
  };

  static List<dynamic>? listToJson(List<Event2Grouping>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  @override
  bool operator==(Object other) =>
    (other is Event2Grouping) &&
    (type == other.type) &&
    (displayAsIndividual == other.displayAsIndividual) &&
    (superEventId == other.superEventId) &&
    (recurrenceId == other.recurrenceId);

  @override
  int get hashCode =>
    (type?.hashCode ?? 0) ^
    (displayAsIndividual?.hashCode ?? 0) ^
    (superEventId?.hashCode ?? 0) ^
    (recurrenceId?.hashCode ?? 0);
}

///////////////////////////////
/// Event2Contact

class Event2Contact {
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? organization;

  Event2Contact({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.organization});

  static Event2Contact? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event2Contact(
      firstName: JsonUtils.stringValue(json['first_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      email: JsonUtils.stringValue(json['email']),
      phone: JsonUtils.stringValue(json['phone']),
      organization: JsonUtils.stringValue(json['organization']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "phone": phone,
      "organization": organization
    };
  }

  @override
  bool operator ==(other) =>
      (other is Event2Contact) &&
      (other.firstName == firstName) &&
      (other.lastName == lastName) &&
      (other.email == email) &&
      (other.phone == phone) &&
      (other.organization == organization);

  @override
  int get hashCode =>
      (firstName?.hashCode ?? 0) ^
      (lastName?.hashCode ?? 0) ^
      (email?.hashCode ?? 0) ^
      (phone?.hashCode ?? 0) ^
      (organization?.hashCode ?? 0);

  static List<Event2Contact>? listFromJson(List<dynamic>? jsonList) {
    List<Event2Contact>? result;
    if (jsonList != null) {
      result = <Event2Contact>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event2Contact.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event2Contact>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////////
/// Event2PersonIdentifier

class Event2PersonIdentifier {
  final String? accountId;
  final String? externalId;

  Event2PersonIdentifier({
    this.accountId,
    this.externalId,});

  String? get netId => externalId;

  static Event2PersonIdentifier? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event2PersonIdentifier(
      accountId: JsonUtils.stringValue(json['account_id']),
      externalId: JsonUtils.stringValue(json['external_id']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "account_id": accountId,
      "external_id": externalId,
    };
  }

  Map<String, dynamic> toNotNullJson() {
    Map<String, dynamic> map = {};
    if(accountId != null)
      map["account_id"] = accountId;
    if(externalId != null)
      map["external_id"] = externalId;

    return map;
  }

  @override
  bool operator ==(other) =>
      (other is Event2PersonIdentifier) &&
      (other.accountId == accountId) &&
      (other.externalId == externalId);

  @override
  int get hashCode =>
      (accountId?.hashCode ?? 0) ^
      (externalId?.hashCode ?? 0);

  static List<Event2PersonIdentifier>? listFromJson(List<dynamic>? jsonList) {
    List<Event2PersonIdentifier>? result;
    if (jsonList != null) {
      result = <Event2PersonIdentifier>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event2PersonIdentifier.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event2PersonIdentifier>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static List<dynamic>? listToNotNullJson(List<Event2PersonIdentifier>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (Event2PersonIdentifier contentEntry in contentList) {
        jsonList.add(contentEntry.toNotNullJson());
      }
    }
    return jsonList;
  }
}

///////////////////////////////
/// Event2Person - registrant or attendee

class Event2Person {
  final String? id;
  final Event2PersonIdentifier? identifier;
  final Event2UserRole? role;
  final Event2UserRegistrationType? registrationType;
  final int? time;

  Event2Person({
    this.id,
    this.identifier,
    this.role,
    this.registrationType,
    this.time});

  static Event2Person? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event2Person(
      id: JsonUtils.stringValue(json['id']),
      identifier: Event2PersonIdentifier.fromJson(JsonUtils.mapValue(json['identifier'])),
      role: event2UserRoleFromString(JsonUtils.stringValue(json['role'])),
      registrationType: event2UserRegistrationTypeFromString(JsonUtils.stringValue(json['registration_type'])),
      time: JsonUtils.intValue(json['time']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "identifier": identifier?.toJson(),
      "role": event2UserRoleToString(role),
      "registration_type": event2UserRegistrationTypeToString(registrationType),
      "time": time
    };
  }

  @override
  bool operator ==(other) =>
      (other is Event2Person) &&
      (other.id == id) &&
      (other.identifier == identifier) &&
      (other.role == role) &&
      (other.registrationType == registrationType) &&
      (other.time == time);

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (identifier?.hashCode ?? 0) ^
      (role?.hashCode ?? 0) ^
      (registrationType?.hashCode ?? 0) ^
      (time?.hashCode ?? 0);

  static List<Event2Person>? listFromJson(List<dynamic>? jsonList) {
    List<Event2Person>? result;
    if (jsonList != null) {
      result = <Event2Person>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event2Person.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event2Person>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static Set<String>? netIdsFromList(List<Event2Person>? contentList) {
    Set<String>? result;
    if (contentList != null) {
      result = <String>{};
      for (Event2Person contentEntry in contentList) {
        if (contentEntry.identifier?.netId != null) {
          result.add(contentEntry.identifier!.netId!);
        }
      }
    }
    return result;
  }

  static int? countInList(List<Event2Person>? contentList, { Event2UserRole? role, Event2UserRegistrationType? registrationType}) {
    if (contentList != null) {
      int count = 0;
      for (Event2Person contentEntry in contentList) {
        if (((role == null) || (contentEntry.role == role)) &&
            ((registrationType == null) || (contentEntry.registrationType == registrationType))
           ) {
          count = count + 1;
        }
      }
      return count;
    }
    return null;
  }

  static int? findInList(List<Event2Person>? contentList, { String? netId }) {
    if (contentList != null) {
      for (int index = 0; index < contentList.length; index++) {
        if ((netId != null) && (contentList[index].identifier?.netId == netId)) {
          return index;
        }
      }
    }
    return null;
  }

  static bool containsInList(List<Event2Person>? contentList, { String? netId }) =>
    (findInList(contentList, netId: netId) != null);
}

///////////////////////////////
/// Event2UserRole

enum Event2UserRole { admin, participant, attendanceTaker }

Event2UserRole? event2UserRoleFromString(String? value) {
  if (value == 'admin') {
    return Event2UserRole.admin;
  }
  else if (value == 'participant') {
    return Event2UserRole.participant;
  }
  else if (value == 'attendance-taker') {
    return Event2UserRole.attendanceTaker;
  }
  else {
    return null;
  }
}

String? event2UserRoleToString(Event2UserRole? value) {
  switch (value) {
    case Event2UserRole.admin: return 'admin';
    case Event2UserRole.participant: return 'participant';
    case Event2UserRole.attendanceTaker: return 'attendance-taker';
    default: return null;
  }
}

///////////////////////////////
/// Event2UserRegistrationType

enum Event2UserRegistrationType { self, registrants, creator }

Event2UserRegistrationType? event2UserRegistrationTypeFromString(String? value) {
  if (value == 'self') {
    return Event2UserRegistrationType.self;
  }
  else if (value == 'registrants-list') {
    return Event2UserRegistrationType.registrants;
  }
  else if (value == 'creator') {
    return Event2UserRegistrationType.creator;
  }
  else {
    return null;
  }
}

String? event2UserRegistrationTypeToString(Event2UserRegistrationType? value) {
  switch (value) {
    case Event2UserRegistrationType.self: return 'self';
    case Event2UserRegistrationType.registrants: return 'registrants-list';
    case Event2UserRegistrationType.creator: return 'creator';
    default: return null;
  }
}

///////////////////////////////
/// Event2Type

enum Event2Type { inPerson, online, hybrid }

Event2Type? event2TypeFromString(String? value) {
  if (value == 'in-person') {
    return Event2Type.inPerson;
  }
  else if (value == 'online') {
    return Event2Type.online;
  }
  else if (value == 'hybrid') {
    return Event2Type.hybrid;
  }
  else {
    return null;
  }
}

String? event2TypeToString(Event2Type? value) {
  switch (value) {
    case Event2Type.inPerson: return 'in-person';
    case Event2Type.online: return 'online';
    case Event2Type.hybrid: return 'hybrid';
    default: return null;
  }
}

///////////////////////////////
/// Event2TimeFilter

enum Event2TimeFilter { past, upcoming, today, tomorrow, thisWeek, thisWeekend, nextWeek, nextWeekend, thisMonth, nextMonth, customRange }

extension Event2TimeFilterImpl on Event2TimeFilter {

  String toJson() {
    switch (this) {
      case Event2TimeFilter.past: return 'past';
      case Event2TimeFilter.upcoming: return 'upcoming';
      case Event2TimeFilter.today: return 'today';
      case Event2TimeFilter.tomorrow: return 'tomorrow';
      case Event2TimeFilter.thisWeek: return 'this_week';
      case Event2TimeFilter.thisWeekend: return 'this_weekend';
      case Event2TimeFilter.nextWeek: return 'next_week';
      case Event2TimeFilter.nextWeekend: return 'next_weekend';
      case Event2TimeFilter.thisMonth: return 'this_month';
      case Event2TimeFilter.nextMonth: return 'next_month';
      case Event2TimeFilter.customRange: return 'custom_range';
    }
  }

  static Event2TimeFilter? fromJson(String? value) {
    switch (value) {
      case 'past': return Event2TimeFilter.past;
      case 'upcoming': return Event2TimeFilter.upcoming;
      case 'today': return Event2TimeFilter.today;
      case 'tomorrow': return Event2TimeFilter.tomorrow;
      case 'this_week': return Event2TimeFilter.thisWeek;
      case 'this_weekend': return Event2TimeFilter.thisWeekend;
      case 'next_week': return Event2TimeFilter.nextWeek;
      case 'next_weekend': return Event2TimeFilter.nextWeekend;
      case 'this_month': return Event2TimeFilter.thisMonth;
      case 'next_month': return Event2TimeFilter.nextMonth;
      case 'custom_range': return Event2TimeFilter.customRange;
      default: return null;
    }
  }

  static Event2TimeFilter? fromAttributeSelection(dynamic attributeSelection) {
    if (attributeSelection is List) {
      for (dynamic entry in attributeSelection) {
        if (entry is Event2TimeFilter) {
          return entry;
        }
      }
    }
    else if (attributeSelection is Event2TimeFilter) {
      return attributeSelection;
    }
    return null;
  }
}

///////////////////////////////
/// Event2TypeFilter

enum Event2TypeFilter { free, paid, inPerson, online, hybrid, public, private, nearby, superEvent, favorite, admin }

enum Event2TypeGroup { cost, format, access, limits }

const Map<Event2TypeFilter, Event2TypeGroup> eventTypeFilterGroups = <Event2TypeFilter, Event2TypeGroup>{
  Event2TypeFilter.free: Event2TypeGroup.cost,
  Event2TypeFilter.paid: Event2TypeGroup.cost,
  Event2TypeFilter.inPerson: Event2TypeGroup.format,
  Event2TypeFilter.online: Event2TypeGroup.format,
  Event2TypeFilter.hybrid: Event2TypeGroup.format,
  Event2TypeFilter.public: Event2TypeGroup.access,
  Event2TypeFilter.private: Event2TypeGroup.access,
  Event2TypeFilter.nearby: Event2TypeGroup.limits,
  Event2TypeFilter.superEvent: Event2TypeGroup.limits,
  Event2TypeFilter.favorite: Event2TypeGroup.limits,
  Event2TypeFilter.admin: Event2TypeGroup.limits,
};

extension Event2TypeFilterImpl on Event2TypeFilter {

  String toJson() {
    switch (this) {
      case Event2TypeFilter.free: return 'free';
      case Event2TypeFilter.paid: return 'paid';
      case Event2TypeFilter.inPerson: return 'in-person';
      case Event2TypeFilter.online: return 'online';
      case Event2TypeFilter.hybrid: return 'hybrid';
      case Event2TypeFilter.public: return 'public';
      case Event2TypeFilter.private: return 'private';
      case Event2TypeFilter.nearby: return 'nearby';
      case Event2TypeFilter.superEvent: return 'super-event';
      case Event2TypeFilter.favorite: return 'favorite';
      case Event2TypeFilter.admin: return 'admin';
    }
  }

  static Event2TypeFilter? fromJson(String? value) {
    switch (value) {
      case 'free': return Event2TypeFilter.free;
      case 'paid': return Event2TypeFilter.paid;
      case 'in-person': return Event2TypeFilter.inPerson;
      case 'online': return Event2TypeFilter.online;
      case 'hybrid': return Event2TypeFilter.hybrid;
      case 'public': return Event2TypeFilter.public;
      case 'private': return Event2TypeFilter.private;
      case 'nearby': return Event2TypeFilter.nearby;
      case 'super-event': return Event2TypeFilter.superEvent;
      case 'favorite': return Event2TypeFilter.favorite;
      case 'admin': return Event2TypeFilter.admin;
      default: return null;
    }
  }

}

extension Event2TypeFilterListImpl on Iterable<Event2TypeFilter> {

  List<String> toJson() {
    List<String> list = <String>[];
    for (Event2TypeFilter value in this) {
      list.add(value.toJson());
    }
    return list;
  }

  static List<Event2TypeFilter>? listFromJson(List<String>? values) {
    if (values != null) {
      List<Event2TypeFilter> list = <Event2TypeFilter>[];
      for (String value in values) {
        Event2TypeFilter? entry = Event2TypeFilterImpl.fromJson(value);
        if (entry != null) {
          list.add(entry);
        }
      }
      return list;
    }
    return null;
  }

  static List<Event2TypeFilter>? fromAttributeSelection(dynamic attributeSelection) {
    if (attributeSelection is List) {
      return JsonUtils.listValue<Event2TypeFilter>(attributeSelection);
    }
    else if (attributeSelection is Event2TypeFilter) {
      return <Event2TypeFilter>[attributeSelection];
    }
    else {
      return null;
    }
  }
}

///////////////////////////////
/// Event2SortType

enum Event2SortType { dateTime, alphabetical, proximity }

Event2SortType? event2SortTypeFromString(String? value) {
  if (value == 'date_time') {
    return Event2SortType.dateTime;
  }
  else if (value == 'alphabetical') {
    return Event2SortType.alphabetical;
  }
  else if (value == 'proximity') {
    return Event2SortType.proximity;
  }
  else {
    return null;
  }
}

String? event2SortTypeToString(Event2SortType? value) {
  switch (value) {
    case Event2SortType.dateTime: return 'date_time';
    case Event2SortType.alphabetical: return 'alphabetical';
    case Event2SortType.proximity: return 'proximity';
    default: return null;
  }
}

String? event2SortTypeToOption(Event2SortType? value) {
  // sort_by: name, start_time, end_time, proximity. Default: start_time 
  switch (value) {
    case Event2SortType.dateTime: return 'start_time';
    case Event2SortType.alphabetical: return 'name';
    case Event2SortType.proximity: return 'proximity';
    default: return null;
  }
}

///////////////////////////////
/// Event2SortOrder

enum Event2SortOrder { ascending, descending }

Event2SortOrder? event2SortOrderFromString(String? value) {
  if (value == 'ascending') {
    return Event2SortOrder.ascending;
  }
  else if (value == 'descending') {
    return Event2SortOrder.descending;
  }
  else {
    return null;
  }
}

String? event2SortOrderToString(Event2SortOrder? value) {
  switch (value) {
    case Event2SortOrder.ascending: return 'ascending';
    case Event2SortOrder.descending: return 'descending';
    default: return null;
  }
}

String? event2SortOrderToOption(Event2SortOrder? value) {
  switch (value) {
    case Event2SortOrder.ascending: return 'asc';
    case Event2SortOrder.descending: return 'desc';
    default: return null;
  }
}

///////////////////////////////
/// Event2GroupingType

enum Event2GroupingType { superEvent, recurrence, none }

Event2GroupingType? event2GroupingTypeFromString(String? value) {
  if (value == 'super_events') {
    return Event2GroupingType.superEvent;
  }
  else if (value == 'repeatable') {
    return Event2GroupingType.recurrence;
  }
  else if (value == 'none') {
    return Event2GroupingType.none;
  }
  else {
    return null;
  }
}

String? event2GroupingTypeToString(Event2GroupingType? value) {
  switch (value) {
    case Event2GroupingType.superEvent: return 'super_events';
    case Event2GroupingType.recurrence: return 'repeatable';
    case Event2GroupingType.none: return 'none';
    default: return null;
  }
}

///////////////////////////////
/// Event2Source

enum Event2Source { events_bb, sports_bb }

Event2Source? event2SourceFromString(String? value) {
  if (value == 'events_bb') {
    return Event2Source.events_bb;
  }
  else if (value == 'sports_bb') {
    return Event2Source.sports_bb;
  }
  else {
    return null;
  }
}

String? event2SourceToString(Event2Source? value) {
  switch (value) {
    case Event2Source.events_bb: return 'events_bb';
    case Event2Source.sports_bb: return 'sports_bb';
    default: return null;
  }
}

///////////////////////////////
/// Events2ListResult

class Events2ListResult {
  final List<Event2>? events;
  final int? totalCount;
  
  Events2ListResult({this.events, this.totalCount});

  static Events2ListResult? fromJson(Map<String, dynamic>? json) => (json != null) ? Events2ListResult(
    events: Event2.listFromJson(JsonUtils.listValue(json['result'])),
    totalCount: JsonUtils.intValue(json['total_count']),
  ) : null;

  Map<String, dynamic> toJson() => {
    'result': Event2.listToJson(events),
    'total_count': totalCount,
  };

  static Events2ListResult? fromResponseJson(dynamic json) {
    if (json is Map) {
      return Events2ListResult.fromJson(JsonUtils.mapValue(json));
    }
    else if (json is List) {
      return Events2ListResult(events: Event2.listFromJson(JsonUtils.listValue(json)));
    }
    else {
      return null;
    }
  }

  static List<Event2>? listFromResponseJson(dynamic json) {
    if (json is Map) {
      return Events2ListResult.fromJson(JsonUtils.mapValue(json))?.events;
    }
    else if (json is List) {
      return Event2.listFromJson(JsonUtils.listValue(json));
    }
    else {
      return null;
    }
  }


  // Equality

  @override
  bool operator==(Object other) =>
    (other is Events2ListResult) &&
    (const DeepCollectionEquality().equals(events, other.events)) &&
    (totalCount == other.totalCount);

  @override
  int get hashCode =>
    (const DeepCollectionEquality().hash(events)) ^
    (totalCount?.hashCode ?? 0);
}

///////////////////////////////
/// Events2NotificationSettings
class Event2NotificationSetting {
  final String? id;
  final bool sendToFavorited;
  final bool sendToRegistered;
  final bool sendToPublishedInGroups;
  final String? sendTimezone;
  final DateTime? sendDateTimeUtc;
  final String? subject;
  final String? body;

  Event2NotificationSetting({this.id, this.sendToFavorited = false, this.sendToRegistered = false, this.sendToPublishedInGroups = false, this.sendDateTimeUtc, this.sendTimezone, this.subject, this.body});

  static Event2NotificationSetting? fromJson(Map<String, dynamic>? json) => (json != null) ? Event2NotificationSetting(
      id: JsonUtils.stringValue(json['id']),
      sendToFavorited: JsonUtils.boolValue(json['send_to_favorited']) ?? false,
      sendToRegistered: JsonUtils.boolValue(json['send_to_registrered']) ?? false,
      sendToPublishedInGroups: JsonUtils.boolValue(json['send_to_published_in_groups']) ?? false,
      sendDateTimeUtc: DateTimeUtils.dateTimeFromSecondsSinceEpoch(JsonUtils.intValue(json['send_date_time']), isUtc: true),
      sendTimezone: JsonUtils.stringValue(json['send_timezone']),
      subject: JsonUtils.stringValue(json['subject']),
      body: JsonUtils.stringValue(json['body'])
  ) : null;

  factory Event2NotificationSetting.fromOther(Event2NotificationSetting? other, {
    String? id,
    bool? sendToFavorited,
    bool? sendToRegistered,
    bool? sendToPublishedInGroups,
    String? sendTimezone,
    DateTime? sendDateTimeUtc,
    String? subject,
    String? body,
  }) => Event2NotificationSetting(
      id: id ?? other?.id,
      sendToFavorited: sendToFavorited ?? other?.sendToFavorited ?? false,
      sendToRegistered: sendToRegistered ?? other?.sendToRegistered ?? false,
      sendToPublishedInGroups: sendToPublishedInGroups ?? other?.sendToPublishedInGroups ?? false,
      sendDateTimeUtc: sendDateTimeUtc ?? other?.sendDateTimeUtc,
      sendTimezone: sendTimezone ?? other?.sendTimezone,
      subject: subject ?? other?.subject,
      body: body ?? other?.body,
  );

  static List<Event2NotificationSetting>? listFromJson(List<dynamic>? jsonList) {
    List<Event2NotificationSetting>? result;
    if (jsonList != null) {
      result = <Event2NotificationSetting>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event2NotificationSetting.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<Event2NotificationSetting>? listFromOther(List<Event2NotificationSetting>? values) {
    List<Event2NotificationSetting>? result;
    if (values != null) {
      result = <Event2NotificationSetting>[];
      for (Event2NotificationSetting value in values) {
        ListUtils.add(result, Event2NotificationSetting.fromOther(value));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<dynamic>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        ListUtils.add(jsonList, contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'send_to_favorited': sendToFavorited,
    'send_to_registrered': sendToRegistered,
    'send_to_published_in_groups': sendToPublishedInGroups,
    'send_timezone': sendTimezone,
    'send_date_time': DateTimeUtils.dateTimeToSecondsSinceEpoch(sendDateTimeUtc),
    'subject': subject,
    'body': body
  };

  @override
  bool operator ==(other) =>
      (other is Event2NotificationSetting) &&
          (id == other.id) &&
          (sendToFavorited == other.sendToFavorited) &&
          (sendToRegistered == other.sendToRegistered) &&
          (sendToPublishedInGroups == other.sendToPublishedInGroups) &&
          (sendTimezone == other.sendTimezone) &&
          (sendDateTimeUtc == other.sendDateTimeUtc) &&
          (subject == other.subject) &&
          (body == other.body);

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (sendToFavorited.hashCode) ^
      (sendToRegistered.hashCode) ^
      (sendToPublishedInGroups.hashCode) ^
      (sendTimezone?.hashCode ?? 0) ^
      (sendDateTimeUtc?.hashCode ?? 0) ^
      (subject?.hashCode ?? 0) ^
      (body?.hashCode ?? 0);

  bool get hasAudience => (sendToFavorited || sendToRegistered || sendToPublishedInGroups);
}