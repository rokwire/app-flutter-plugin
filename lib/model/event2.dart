import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2 {
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