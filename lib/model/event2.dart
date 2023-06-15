import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2 with Explore, Favorite {
  final String? id;
  final String? name;
  final String? description;
  final String? instructions;
  final String? imageUrl;

  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final bool? allDay;

  final Map<String, dynamic>? attributes;
  final ExploreLocation? location;
  final EventUserRole? userRole;

  final bool? required;
  final bool? canceled;
  final bool? private;
  final bool? free;

  final bool? online;
  final OnlineDetails? onlineDetails;
  final String? registrationUrl;

  final String? sponsor;
  final String? speaker;
  final List<Contact>? contacts;

  String? assignedImageUrl;

  Event2({
    this.id, this.name, this.description, this.instructions, this.imageUrl,
    this.startTimeUtc, this.endTimeUtc, this.allDay,
    this.attributes, this.location, this.userRole,
    this.required, this.canceled, this.private, this.free,
    this.online, this.onlineDetails, this.registrationUrl, 
    this.sponsor, this.speaker, this.contacts
  });

  static Event2? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? Event2(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      description: JsonUtils.stringValue(json['description']),
      instructions: JsonUtils.stringValue(json['instructions']),
      imageUrl: JsonUtils.stringValue(json['image_url']),

      startTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start'])),
      endTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end'])),
      allDay: JsonUtils.boolValue(json['all_day']),

      attributes: JsonUtils.mapValue(json['attributes']),
      location: ExploreLocation.fromJson(JsonUtils.mapValue(json['location'])),
      userRole: eventUserRoleFromString(JsonUtils.stringValue(json['role'])),

      required: JsonUtils.boolValue(json['required']),
      canceled: JsonUtils.boolValue(json['canceled']),
      private: JsonUtils.boolValue(json['private']),
      free: JsonUtils.boolValue(json['free']),

      online: JsonUtils.boolValue(json['online']),
      onlineDetails: OnlineDetails.fromJson(JsonUtils.mapValue(json['online_details'])),
      registrationUrl: JsonUtils.stringValue(json['registration_url']),

      sponsor: JsonUtils.stringValue(json['sponsor']),
      speaker: JsonUtils.stringValue(json['speaker']),
      contacts: Contact.listFromJson(JsonUtils.listValue(json['contacts'])),

    ) : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'instructions': instructions,
    'image_url': imageUrl,

    'start': DateTimeUtils.utcDateTimeToString(startTimeUtc),
    'end': DateTimeUtils.utcDateTimeToString(endTimeUtc),
    'all_day': allDay,

    'attributes': attributes,
    'location': location?.toJson(),
    'role': eventUserRoleToString(userRole),

    'required': required,
    'canceled': canceled,
    'private': private,
    'free': free,

    'online': online,
    'online_details': onlineDetails?.toJson(),
    'registration_url': registrationUrl,

    'sponsor': sponsor,
    'speaker': speaker,
    'contacts': Contact.listToJson(contacts),
  };

  @override
  bool operator==(dynamic other) =>
    (other is Event2) &&
    (id == other.id) &&
    (name == other.name) &&
    (description == other.description) &&
    (instructions == other.instructions) &&
    (imageUrl == other.imageUrl) &&
    
    (startTimeUtc == other.startTimeUtc) &&
    (endTimeUtc == other.endTimeUtc) &&
    (allDay == other.allDay) &&

    (const DeepCollectionEquality().equals(attributes, other.attributes)) &&
    (location == other.location) &&
    (userRole == other.userRole) &&

    (required == other.required) &&
    (canceled == other.canceled) &&
    (private == other.private) &&
    (free == other.free) &&

    (online == other.online) &&
    (onlineDetails == other.onlineDetails) &&
    (registrationUrl == other.registrationUrl) &&

    (sponsor == other.sponsor) &&
    (speaker == other.speaker) &&
    (const DeepCollectionEquality().equals(contacts, other.contacts));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (instructions?.hashCode ?? 0) ^
    (imageUrl?.hashCode ?? 0) ^

    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0) ^
    (allDay?.hashCode ?? 0) ^

    (const DeepCollectionEquality().hash(attributes)) ^
    (location?.hashCode ?? 0) ^
    (userRole?.hashCode ?? 0) ^

    (required?.hashCode ?? 0) ^
    (canceled?.hashCode ?? 0) ^
    (private?.hashCode ?? 0) ^
    (free?.hashCode ?? 0) ^

    (online?.hashCode ?? 0) ^
    (onlineDetails?.hashCode ?? 0) ^
    (registrationUrl?.hashCode ?? 0) ^

    (sponsor?.hashCode ?? 0) ^
    (speaker?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(contacts));

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
}

///////////////////////////////
/// OnlineDetails

class OnlineDetails {
  final String? url;
  final String? meetingId;
  final String? meetingPasscode;

  OnlineDetails({this.url, this.meetingId, this.meetingPasscode});

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'meeting_id': meetingId,
      'meeting_passcode': meetingPasscode
    };
  }

  static OnlineDetails? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return OnlineDetails(
        url: JsonUtils.stringValue(json['url']),
        meetingId: JsonUtils.stringValue(json['meeting_id']),
        meetingPasscode: JsonUtils.stringValue(json['meeting_passcode']));
  }

  @override
  bool operator==(dynamic other) =>
    (other is OnlineDetails) &&
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
/// Contact

class Contact {
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? organization;

  Contact({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.organization});

  static Contact? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Contact(
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
      (other is Contact) &&
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

  static List<Contact>? listFromJson(List<dynamic>? jsonList) {
    List<Contact>? result;
    if (jsonList != null) {
      result = <Contact>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Contact.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Contact>? contentList) {
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
/// EventUserRole

enum EventUserRole { admin, participant }

EventUserRole? eventUserRoleFromString(String? value) {
  if (value == 'admin') {
    return EventUserRole.admin;
  }
  else if (value == 'participant') {
    return EventUserRole.participant;
  }
  else {
    return null;
  }
}

String? eventUserRoleToString(EventUserRole? value) {
  switch (value) {
    case EventUserRole.admin: return 'admin';
    case EventUserRole.participant: return 'participant';
    default: return null;
  }
}

///////////////////////////////
/// EventTimeFilter

enum EventTimeFilter { upcoming, today, tomorrow, thisWeek, thisWeekend, thisMonth, customRange }

EventTimeFilter? eventTimeFilterFromString(String? value) {
  if (value == 'upcoming') {
    return EventTimeFilter.upcoming;
  }
  else if (value == 'today') {
    return EventTimeFilter.today;
  }
  else if (value == 'tomorrow') {
    return EventTimeFilter.tomorrow;
  }
  else if (value == 'this_week') {
    return EventTimeFilter.thisWeek;
  }
  else if (value == 'this_weekend') {
    return EventTimeFilter.thisWeekend;
  }
  else if (value == 'this_month') {
    return EventTimeFilter.thisMonth;
  }
  else if (value == 'custom_range') {
    return EventTimeFilter.customRange;
  }
  else {
    return null;
  }
}

String? eventTimeFilterToString(EventTimeFilter? value) {
  switch (value) {
    case EventTimeFilter.upcoming: return 'upcoming';
    case EventTimeFilter.today: return 'today';
    case EventTimeFilter.tomorrow: return 'tomorrow';
    case EventTimeFilter.thisWeek: return 'this_week';
    case EventTimeFilter.thisWeekend: return 'this_weekend';
    case EventTimeFilter.thisMonth: return 'this_month';
    case EventTimeFilter.customRange: return 'custom_range';
    default: return null;
  }
}

///////////////////////////////
/// EventTypeFilter

enum EventTypeFilter { free, paid, inPerson, online, public, private, nearby }

const Map<EventTypeFilter, String> eventTypeFilterGroups = <EventTypeFilter, String>{
  EventTypeFilter.free: 'cost',
  EventTypeFilter.paid: 'cost',
  EventTypeFilter.inPerson: 'type',
  EventTypeFilter.online: 'type',
  EventTypeFilter.public: 'discoverability',
  EventTypeFilter.private: 'discoverability',
  EventTypeFilter.nearby: 'proximity',
};

EventTypeFilter? eventTypeFilterFromString(String? value) {
  if (value == 'free') {
    return EventTypeFilter.free;
  }
  else if (value == 'paid') {
    return EventTypeFilter.paid;
  }
  else if (value == 'inPerson') {
    return EventTypeFilter.inPerson;
  }
  else if (value == 'online') {
    return EventTypeFilter.online;
  }
  else if (value == 'public') {
    return EventTypeFilter.public;
  }
  else if (value == 'private') {
    return EventTypeFilter.private;
  }
  else if (value == 'nearby') {
    return EventTypeFilter.nearby;
  }
  else {
    return null;
  }
}

String? eventTypeFilterToString(EventTypeFilter? value) {
  switch (value) {
    case EventTypeFilter.free: return 'free';
    case EventTypeFilter.paid: return 'paid';
    case EventTypeFilter.inPerson: return 'in_person';
    case EventTypeFilter.online: return 'online';
    case EventTypeFilter.public: return 'public';
    case EventTypeFilter.private: return 'private';
    case EventTypeFilter.nearby: return 'nearby';
    default: return null;
  }
}

List<EventTypeFilter>? eventTypeFilterListFromStringList(List<String>? values) {
  if (values != null) {
    List<EventTypeFilter> list = <EventTypeFilter>[];
    for (String value in values) {
      EventTypeFilter? entry = eventTypeFilterFromString(value);
      if (entry != null) {
        list.add(entry);
      }
    }
    return list;
  }
  return null;
}

List<String>? eventTypeFilterListToStringList(List<EventTypeFilter>? values) {
  if (values != null) {
    List<String> list = <String>[];
    for (EventTypeFilter value in values) {
      String? entry = eventTypeFilterToString(value);
      if (entry != null) {
        list.add(entry);
      }
    }
    return list;
  }
  return null;
}

List<EventTypeFilter>? eventTypeFilterListFromSelection(dynamic selection) {
  if (selection is List) {
    return JsonUtils.listValue<EventTypeFilter>(selection);
  }
  else if (selection is EventTypeFilter) {
    return <EventTypeFilter>[selection];
  }
  else {
    return null;
  }
}


///////////////////////////////
/// EventSortType

enum EventSortType { dateTime, alphabetical, proximity }

EventSortType? eventSortTypeFromString(String? value) {
  if (value == 'date_time') {
    return EventSortType.dateTime;
  }
  else if (value == 'alphabetical') {
    return EventSortType.alphabetical;
  }
  else if (value == 'proximity') {
    return EventSortType.proximity;
  }
  else {
    return null;
  }
}

String? eventSortTypeToString(EventSortType? value) {
  switch (value) {
    case EventSortType.dateTime: return 'date_time';
    case EventSortType.alphabetical: return 'alphabetical';
    case EventSortType.proximity: return 'proximity';
    default: return null;
  }
}

String? eventSortTypeToOption(EventSortType? value) {
  // sort_by: name, start_time, end_time, proximity. Default: start_time 
  switch (value) {
    case EventSortType.dateTime: return 'start_time';
    case EventSortType.alphabetical: return 'name';
    case EventSortType.proximity: return 'proximity';
    default: return null;
  }
}

///////////////////////////////
/// EventSortOrder

enum EventSortOrder { ascending, descending }

EventSortOrder? eventSortOrderFromString(String? value) {
  if (value == 'ascending') {
    return EventSortOrder.ascending;
  }
  else if (value == 'descending') {
    return EventSortOrder.descending;
  }
  else {
    return null;
  }
}

String? eventSortOrderToString(EventSortOrder? value) {
  switch (value) {
    case EventSortOrder.ascending: return 'ascending';
    case EventSortOrder.descending: return 'descending';
    default: return null;
  }
}

String? eventSortOrderToOption(EventSortOrder? value) {
  switch (value) {
    case EventSortOrder.ascending: return 'asc';
    case EventSortOrder.descending: return 'desc';
    default: return null;
  }
}
