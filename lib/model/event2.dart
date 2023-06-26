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
  final RegistrationDetails? registrationDetails;
  final Event2UserRole? userRole;
  final Event2Type? _type;

  final bool? required;
  final bool? canceled;
  final bool? private;
  final bool? free;

  final bool? inPerson;
  final ExploreLocation? location;

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
    this.attributes, this.registrationDetails, this.userRole, Event2Type? type,
    this.required, this.canceled, this.private, this.free,
    this.inPerson, this.location, 
    this.online, this.onlineDetails, this.registrationUrl, 
    this.sponsor, this.speaker, this.contacts
  }) :
  _type = type;

  // JSON serialization

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
      registrationDetails: RegistrationDetails.fromJson(JsonUtils.mapValue(json['registration_details'])),
      userRole: event2UserRoleFromString(JsonUtils.stringValue(json['role'])),
      type: event2TypeFromString(JsonUtils.stringValue(json['type'])),

      required: JsonUtils.boolValue(json['required']),
      canceled: JsonUtils.boolValue(json['canceled']),
      private: JsonUtils.boolValue(json['private']),
      free: JsonUtils.boolValue(json['free']),

      inPerson: JsonUtils.boolValue(json['in_person']),
      location: ExploreLocation.fromJson(JsonUtils.mapValue(json['location'])),

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
    'registration_details': registrationDetails?.toJson(),
    'role': event2UserRoleToString(userRole),
    'type': event2TypeToString(_type),

    'required': required,
    'canceled': canceled,
    'private': private,
    'free': free,

    'in_person': inPerson,
    'location': location?.toJson(),

    'online': online,
    'online_details': onlineDetails?.toJson(),
    'registration_url': registrationUrl,

    'sponsor': sponsor,
    'speaker': speaker,
    'contacts': Contact.listToJson(contacts),
  };

  // Equality

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
    (registrationDetails == other.registrationDetails) &&
    (userRole == other.userRole) &&
    (_type == other._type) &&

    (required == other.required) &&
    (canceled == other.canceled) &&
    (private == other.private) &&
    (free == other.free) &&

    (inPerson == other.inPerson) &&
    (location == other.location) &&

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
    (registrationDetails?.hashCode ?? 0) ^
    (userRole?.hashCode ?? 0) ^
    (_type?.hashCode ?? 0) ^

    (required?.hashCode ?? 0) ^
    (canceled?.hashCode ?? 0) ^
    (private?.hashCode ?? 0) ^
    (free?.hashCode ?? 0) ^

    (inPerson?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^

    (online?.hashCode ?? 0) ^
    (onlineDetails?.hashCode ?? 0) ^
    (registrationUrl?.hashCode ?? 0) ^

    (sponsor?.hashCode ?? 0) ^
    (speaker?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(contacts));

  // Attributes

  Event2Type? get type => _type ??
    event2TypeFromFlags(inPerson: inPerson, online: online);

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

  static OnlineDetails? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? OnlineDetails(
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
/// RegistrationDetails

class RegistrationDetails {
  final String? externalLink;

  RegistrationDetails({this.externalLink});

  static RegistrationDetails? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? RegistrationDetails(
      externalLink: JsonUtils.stringValue(json['external_link']),
    ) : null;

  Map<String, dynamic> toJson() => {
    'external_link': externalLink,
  };

  @override
  bool operator==(dynamic other) =>
    (other is RegistrationDetails) &&
    (externalLink == other.externalLink);

  @override
  int get hashCode =>
    (externalLink?.hashCode ?? 0);
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
/// Event2UserRole

enum Event2UserRole { admin, participant }

Event2UserRole? event2UserRoleFromString(String? value) {
  if (value == 'admin') {
    return Event2UserRole.admin;
  }
  else if (value == 'participant') {
    return Event2UserRole.participant;
  }
  else {
    return null;
  }
}

String? event2UserRoleToString(Event2UserRole? value) {
  switch (value) {
    case Event2UserRole.admin: return 'admin';
    case Event2UserRole.participant: return 'participant';
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

Event2Type? event2TypeFromFlags({ bool? inPerson, bool? online}) {
  if (inPerson == true) {
    return (online == true) ? Event2Type.hybrid : Event2Type.inPerson;
  }
  else if (online == true) {
    return (inPerson == true) ? Event2Type.hybrid : Event2Type.online;
  }
  else {
    return null;
  }
}

///////////////////////////////
/// Event2TimeFilter

enum Event2TimeFilter { upcoming, today, tomorrow, thisWeek, thisWeekend, nextWeek, nextWeekend, thisMonth, nextMonth, customRange }

Event2TimeFilter? event2TimeFilterFromString(String? value) {
  if (value == 'upcoming') {
    return Event2TimeFilter.upcoming;
  }
  else if (value == 'today') {
    return Event2TimeFilter.today;
  }
  else if (value == 'tomorrow') {
    return Event2TimeFilter.tomorrow;
  }
  else if (value == 'this_week') {
    return Event2TimeFilter.thisWeek;
  }
  else if (value == 'this_weekend') {
    return Event2TimeFilter.thisWeekend;
  }
  else if (value == 'next_week') {
    return Event2TimeFilter.nextWeek;
  }
  else if (value == 'next_weekend') {
    return Event2TimeFilter.nextWeekend;
  }
  else if (value == 'this_month') {
    return Event2TimeFilter.thisMonth;
  }
  else if (value == 'next_month') {
    return Event2TimeFilter.nextMonth;
  }
  else if (value == 'custom_range') {
    return Event2TimeFilter.customRange;
  }
  else {
    return null;
  }
}

String? event2TimeFilterToString(Event2TimeFilter? value) {
  switch (value) {
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
    default: return null;
  }
}

Event2TimeFilter? event2TimeFilterListFromSelection(dynamic selection) {
  if (selection is List) {
    for (dynamic entry in selection) {
      if (entry is Event2TimeFilter) {
        return entry;
      }
    }
  }
  else if (selection is Event2TimeFilter) {
    return selection;
  }
  return null;
}

///////////////////////////////
/// Event2TypeFilter

enum Event2TypeFilter { free, paid, inPerson, online, public, private, nearby }

const Map<Event2TypeFilter, String> eventTypeFilterGroups = <Event2TypeFilter, String>{
  Event2TypeFilter.free: 'cost',
  Event2TypeFilter.paid: 'cost',
  Event2TypeFilter.inPerson: 'type',
  Event2TypeFilter.online: 'type',
  Event2TypeFilter.public: 'discoverability',
  Event2TypeFilter.private: 'discoverability',
  Event2TypeFilter.nearby: 'proximity',
};

Event2TypeFilter? event2TypeFilterFromString(String? value) {
  if (value == 'free') {
    return Event2TypeFilter.free;
  }
  else if (value == 'paid') {
    return Event2TypeFilter.paid;
  }
  else if (value == 'inPerson') {
    return Event2TypeFilter.inPerson;
  }
  else if (value == 'online') {
    return Event2TypeFilter.online;
  }
  else if (value == 'public') {
    return Event2TypeFilter.public;
  }
  else if (value == 'private') {
    return Event2TypeFilter.private;
  }
  else if (value == 'nearby') {
    return Event2TypeFilter.nearby;
  }
  else {
    return null;
  }
}

String? event2TypeFilterToString(Event2TypeFilter? value) {
  switch (value) {
    case Event2TypeFilter.free: return 'free';
    case Event2TypeFilter.paid: return 'paid';
    case Event2TypeFilter.inPerson: return 'in_person';
    case Event2TypeFilter.online: return 'online';
    case Event2TypeFilter.public: return 'public';
    case Event2TypeFilter.private: return 'private';
    case Event2TypeFilter.nearby: return 'nearby';
    default: return null;
  }
}

List<Event2TypeFilter>? event2TypeFilterListFromStringList(List<String>? values) {
  if (values != null) {
    List<Event2TypeFilter> list = <Event2TypeFilter>[];
    for (String value in values) {
      Event2TypeFilter? entry = event2TypeFilterFromString(value);
      if (entry != null) {
        list.add(entry);
      }
    }
    return list;
  }
  return null;
}

List<String>? event2TypeFilterListToStringList(List<Event2TypeFilter>? values) {
  if (values != null) {
    List<String> list = <String>[];
    for (Event2TypeFilter value in values) {
      String? entry = event2TypeFilterToString(value);
      if (entry != null) {
        list.add(entry);
      }
    }
    return list;
  }
  return null;
}

List<Event2TypeFilter>? event2TypeFilterListFromSelection(dynamic selection) {
  if (selection is List) {
    return JsonUtils.listValue<Event2TypeFilter>(selection);
  }
  else if (selection is Event2TypeFilter) {
    return <Event2TypeFilter>[selection];
  }
  else {
    return null;
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
