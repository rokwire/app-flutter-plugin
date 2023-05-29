/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// Event

class Event with Explore, Favorite {
  String? id;
  String? title;
  String? description;
  String? imageURL;

  ExploreLocation? location;
  
  int? convergeScore;
  String? convergeUrl;

  String? sourceEventId;
  String? startDateString;
  String? endDateString;
  DateTime? startDateGmt;
  DateTime? endDateGmt;
  
  String? category;
  String? subCategory;
  String? sponsor;
  String? titleUrl;
  List<String>? targetAudience;
  String? icalUrl;
  String? outlookUrl;
  String? speaker;
  String? registrationLabel;
  String? registrationUrl;
  String? cost;
  List<Contact>? contacts;
  List<String>? tags;
  DateTime? modifiedDate;
  String? submissionResult;
  String? eventId;
  bool? allDay;
  bool? recurringFlag;
  int? recurrenceId;
  List<Event>? recurringEvents;

  bool? isSuperEvent;
  bool? displayOnlyWithSuperEvent;
  bool? isVirtual;
  String? virtualEventUrl;
  bool? isInPerson;
  List<Map<String, dynamic>>? subEventsMap;
  String? track;
  List<Event>? _subEvents;
  List<Event>? _featuredEvents;

  String? randomImageURL;

  String? createdByGroupId;
  bool? isGroupPrivate;

  bool? isEventFree;

  static const String dateTimeFormat = 'E, dd MMM yyyy HH:mm:ss v';
  static const String serverRequestDateTimeFormat =  'yyyy/MM/ddTHH:mm:ss';


  @override
  bool operator ==(other) =>
      (other is Event) &&
      (other.id == id) &&
      (other.title == title) &&
      (other.description == description) &&
      (other.imageURL == imageURL) &&

      (other.location == location) &&

      (other.convergeScore == convergeScore) &&
      (other.convergeUrl == convergeUrl) &&

      (other.sourceEventId == sourceEventId) &&
      (other.startDateString == startDateString) &&
      (other.endDateString == endDateString) &&
      (other.startDateGmt == startDateGmt) &&
      (other.endDateGmt == endDateGmt) &&
      
      (other.category == category) &&
      (other.subCategory == subCategory) &&
      (other.sponsor == sponsor) &&
      (other.titleUrl == titleUrl) &&
      (const DeepCollectionEquality().equals(other.targetAudience, targetAudience)) &&
      (other.icalUrl == icalUrl) &&
      (other.outlookUrl == outlookUrl) &&
      (other.speaker == speaker) &&
      (other.registrationLabel == registrationLabel) &&
      (other.registrationUrl == registrationUrl) &&
      (other.cost == cost) &&
      (const DeepCollectionEquality().equals(other.contacts, contacts)) &&
      (const DeepCollectionEquality().equals(other.tags, tags)) &&
      (other.modifiedDate == modifiedDate) &&
      (other.submissionResult == submissionResult) &&
      (other.eventId == eventId) &&
      (other.allDay == allDay) &&
      (other.recurringFlag == recurringFlag) &&
      (other.recurrenceId == recurrenceId) &&
      (const DeepCollectionEquality().equals(other.recurringEvents, recurringEvents)) &&
      
      (other.isSuperEvent == isSuperEvent) &&
      (other.displayOnlyWithSuperEvent == displayOnlyWithSuperEvent) &&
      (other.isVirtual == isVirtual) &&
      (other.virtualEventUrl == virtualEventUrl) &&
      (other.isInPerson == isInPerson) &&
      (const DeepCollectionEquality().equals(other.subEventsMap, subEventsMap)) &&
      (other.track == track) &&
//    (const DeepCollectionEquality().equals(other._subEvents, _subEvents)) &&
//    (const DeepCollectionEquality().equals(other._featuredEvents, _featuredEvents)) &&
      (other.createdByGroupId == createdByGroupId) &&
      (other.isGroupPrivate == isGroupPrivate) &&
      (other.isEventFree == isEventFree);

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (title?.hashCode ?? 0) ^
      (description?.hashCode ?? 0) ^
      (imageURL?.hashCode ?? 0) ^

      (location?.hashCode ?? 0) ^

      (convergeScore?.hashCode ?? 0) ^
      (convergeUrl?.hashCode ?? 0) ^

      (sourceEventId?.hashCode ?? 0) ^
      (startDateString?.hashCode ?? 0) ^
      (endDateString?.hashCode ?? 0) ^
      (startDateGmt?.hashCode ?? 0) ^
      (endDateGmt?.hashCode ?? 0) ^
      
      (category?.hashCode ?? 0) ^
      (subCategory?.hashCode ?? 0) ^
      (sponsor?.hashCode ?? 0) ^
      (titleUrl?.hashCode ?? 0) ^
      const DeepCollectionEquality().hash(targetAudience) ^
      (icalUrl?.hashCode ?? 0) ^
      (outlookUrl?.hashCode ?? 0) ^
      (speaker?.hashCode ?? 0) ^
      (registrationLabel?.hashCode ?? 0) ^
      (registrationUrl?.hashCode ?? 0) ^
      (cost?.hashCode ?? 0) ^
      const DeepCollectionEquality().hash(contacts) ^
      const DeepCollectionEquality().hash(tags) ^
      (modifiedDate?.hashCode ?? 0) ^
      (submissionResult?.hashCode ?? 0) ^
      (eventId?.hashCode ?? 0) ^
      (allDay?.hashCode ?? 0) ^
      (recurringFlag?.hashCode ?? 0) ^
      (recurrenceId?.hashCode ?? 0) ^
      const DeepCollectionEquality().hash(recurringEvents) ^

      (isSuperEvent?.hashCode ?? 0) ^
      (displayOnlyWithSuperEvent?.hashCode ?? 0) ^
      (isVirtual?.hashCode ?? 0) ^
      (virtualEventUrl?.hashCode ?? 0) ^
      (isInPerson?.hashCode ?? 0) ^
      const DeepCollectionEquality().hash(subEventsMap) ^
      (track?.hashCode ?? 0) ^
//    const DeepCollectionEquality().hash(_subEvents) ^
//    const DeepCollectionEquality().hash(_featuredEvents) ^
      (createdByGroupId?.hashCode ?? 0) ^
      (isGroupPrivate?.hashCode ?? 0) ^
      (isEventFree?.hashCode ?? 0);

  Event({Map<String, dynamic>? json, Event? other}) {
    if (json != null) {
      _initFromJson(json);
    }
    else if (other != null) {
      _initFromOther(other);
    }
  }

  void _initFromJson(Map<String, dynamic> json) {
    dynamic targetAudienceJson = json['targetAudience'];
    List<String>? targetAudience = targetAudienceJson != null ? List.from(targetAudienceJson) : null;
    
    dynamic tagsJson = json['tags'];
    List<String>? tags = tagsJson != null ? List.from(tagsJson) : null;
    
    List<Contact>? contacts = Contact.listFromJson(json['contacts']);
    
    List<Event>? recurringEvents = Event.listFromJson(json['recurringEvents']);

    List<dynamic>? subEventsJson = json['subEvents'];
    List<Map<String, dynamic>>? subEventsMap = _constructSubEventsMap(subEventsJson);

    id = json["id"];
    title = json['title'];
    description = json['longDescription']; /*Back compatibility keep until we use longDescription */
    imageURL = json['imageURL'];
    location = ExploreLocation.fromJson(json['location']);
    eventId = json['eventId'];
    startDateString = json['startDate'];
    endDateString = json['endDate'];
    startDateGmt = DateTimeUtils.dateTimeFromString(json['startDate'], format: dateTimeFormat, isUtc: true);
    endDateGmt = DateTimeUtils.dateTimeFromString(json['endDate'], format: dateTimeFormat, isUtc: true);
    category = json['category'];
    subCategory = json['subCategory'];
    sponsor = json['sponsor'];
    titleUrl = json['titleURL'];
    this.targetAudience = targetAudience;
    icalUrl = json['icalUrl'];
    outlookUrl = json['outlookUrl'];
    speaker = json['speaker'];
    registrationLabel = json['registrationLabel'];
    if (StringUtils.isNotEmpty(json['registrationUrl'])) {
      registrationUrl = json['registrationUrl'];
    }
    else if (StringUtils.isNotEmpty(json['registrationURL'])) {
      registrationUrl = json['registrationURL'];
    }
    cost = json['cost'];
    this.contacts = contacts;
    this.tags = tags;
    modifiedDate = DateTimeUtils.dateTimeFromString(json['modifiedDate']);
    submissionResult = json['submissionResult'];
    allDay = json['allDay'] ?? false;
    recurringFlag = json['recurringFlag'] ?? false;
    recurrenceId = json['recurrenceId'];
    this.recurringEvents = recurringEvents;
    convergeScore = json['converge_score'];
    convergeUrl = json['converge_url'];
    isSuperEvent = json['isSuperEvent'] ?? false;
    displayOnlyWithSuperEvent = json['displayOnlyWithSuperEvent'] ?? false;
    this.subEventsMap = subEventsMap;
    track = json['track'];
    isVirtual = json['isVirtual'];
    virtualEventUrl = json['virtualEventUrl'];
    isInPerson = json['isInPerson'];
    createdByGroupId = json["createdByGroupId"];
    isGroupPrivate = json["isGroupPrivate"] ?? false;
    isEventFree = json["isEventFree"] ?? false;
  }

  void _initFromOther(Event? other) {
    id = other?.id;
    title = other?.title;
    description = other?.description;
    imageURL = other?.imageURL;
    location = other?.location;
    eventId = other?.eventId;
    startDateString = other?.startDateString;
    endDateString = other?.endDateString;
    startDateGmt = other?.startDateGmt;
    endDateGmt = other?.endDateGmt;
    category = other?.category;
    subCategory = other?.subCategory;
    sponsor = other?.sponsor;
    titleUrl = other?.titleUrl;
    targetAudience = other?.targetAudience;
    icalUrl = other?.icalUrl;
    outlookUrl = other?.outlookUrl;
    speaker = other?.speaker;
    registrationLabel = other?.registrationLabel;
    registrationUrl = other?.registrationUrl;
    cost = other?.cost;
    contacts = other?.contacts;
    tags = other?.tags;
    modifiedDate = other?.modifiedDate;
    submissionResult = other?.submissionResult;
    allDay = other?.allDay;
    recurringFlag = other?.recurringFlag;
    recurrenceId = other?.recurrenceId;
    recurringEvents = other?.recurringEvents;
    convergeScore = other?.convergeScore;
    convergeUrl = other?.convergeUrl;
    isSuperEvent = other?.isSuperEvent;
    displayOnlyWithSuperEvent = other?.displayOnlyWithSuperEvent;
    subEventsMap = other?.subEventsMap;
    track = other?.track;
    isVirtual = other?.isVirtual;
    virtualEventUrl = other?.virtualEventUrl;
    isInPerson = other?.isInPerson;
    createdByGroupId = other?.createdByGroupId;
    isGroupPrivate = other?.isGroupPrivate;
    isEventFree = other?.isEventFree;
  }

  static Event? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Event(json: json) : null;
  }

  static Event? fromOther(Event? other) {
    return (other != null) ? Event(other: other) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "longDescription": description,
      "imageURL": imageURL,
      "location": location?.toJson(),

      "eventId" : eventId,
      "startDate": startDateString,
      "startDateLocal": AppDateTime().formatDateTime(
          startDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true),
      "endDate": endDateString,
      "endDateLocal": AppDateTime().formatDateTime(
          endDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true),
      "category": category,
      "subCategory": subCategory,
      "sponsor": sponsor??"", // Required for CreateEvent
      "titleURL": titleUrl,
      "targetAudience": targetAudience,
      "icalUrl": icalUrl,
      "outlookUrl": outlookUrl,
      "speaker": speaker,
      "registrationLabel": registrationLabel,
      "registrationUrl": registrationUrl,
      "cost": cost,
      "contacts": _encodeContacts(),
      "tags": tags,
      "modifiedDate": AppDateTime().formatDateTime(modifiedDate, ignoreTimeZone: true),
      "submissionResult": submissionResult,
      "allDay": allDay,
      "recurringFlag": recurringFlag,
      "recurrenceId": recurrenceId,
      "recurringEvents": _encodeRecurringEvents(),
      "converge_score": convergeScore,
      "converge_url": convergeUrl,
      "isSuperEvent": isSuperEvent,
      "displayOnlyWithSuperEvent": displayOnlyWithSuperEvent,
      "subEvents": subEventsMap,
      "track": track,
      'isVirtual': isVirtual,
      'virtualEventUrl': virtualEventUrl,
      'isInPerson': isInPerson,
      'createdByGroupId': createdByGroupId,
      'isGroupPrivate': isGroupPrivate,
      'isEventFree': isEventFree,
    };
  }

  //add only not null values
  Map<String, dynamic> toNotNullJson(){
    Map<String, dynamic> result = {};
    if(id!=null) {
      result["id"]= id;
    }
    if(title!=null) {
      result["title"] = title;
    }
    if(description!=null) {
      result["longDescription"] = description;
    }
    if(imageURL!=null) {
      result["imageURL"] = imageURL;
    }
    if(location!=null) {
      Map<String, dynamic> locationJson = {};
      if(location!.locationId!=null) {
        locationJson["locationId"] = location!.locationId;
      }
      if(location!.name!=null) {
        locationJson["name"] = location!.name;
      }
      if(location!.building!=null) {
        locationJson["building"] = location!.building;
      }
      if(location!.address!=null) {
        locationJson["address"] = location!.address;
      }
      if(location!.city!=null) {
        locationJson[ "city"] = location!.city;
      }
      if(location!.state!=null){
      locationJson["state"]= location!.state;
      }
      if(location!.zip!=null){
      locationJson[ "zip"]= location!.zip;
      }
      if(location!.latitude!=null){
      locationJson["latitude"]= location!.latitude;
      }
      if(location!.longitude!=null){
      locationJson["longitude"]= location!.longitude;
      }
      if(location!.floor!=null){
      locationJson["floor"]= location!.floor;
      }
      if(location!.description!=null){
      locationJson["description"]= location!.description;
      }

      result["location"] = locationJson;
    }

    if(eventId!=null) {
      result["eventId"] = eventId;
    }
    if(startDateString!=null) {
      result["startDate"] = startDateString;
    }
    if(startDateLocal!=null) {
      result["startDateLocal"] = AppDateTime().formatDateTime(
          startDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true);
    }
    if(endDateString!=null) {
      result["endDate"] = endDateString;
    }
    if(endDateLocal!=null) {
      result["endDateLocal"] = AppDateTime().formatDateTime(
          endDateLocal, format: AppDateTime.iso8601DateTimeFormat,
          ignoreTimeZone: true);
    }
    if(category!=null) {
      result["category"] = category;
    }
    if(subCategory!=null) {
      result["subCategory"] = subCategory;
    }
    if(sponsor!=null) {
      result["sponsor"] = sponsor;
    }
    // Required for CreateEvent
    if(titleUrl!=null) {
      result["titleURL"]= titleUrl;
    }
    if(targetAudience!=null) {
      result["targetAudience"] = targetAudience;
    }
    if(icalUrl!=null) {
      result["icalUrl"] = icalUrl;
    }
    if(outlookUrl!=null) {
      result["outlookUrl"] = outlookUrl;
    }
    if(speaker!=null) {
      result["speaker"] = speaker;
    }
    if(registrationLabel!=null) {
      result["registrationLabel"] = registrationLabel;
    }
    if(registrationUrl!=null) {
      result["registrationUrl"] = registrationUrl;
    }
    if(cost!=null) {
      result["cost"] = cost;
    }
    if(contacts!=null && contacts!.isNotEmpty) {
      result["contacts"] = _encodeContacts();
    }
    if(tags!=null) {
      result["tags"] = tags;
    }
    if(modifiedDate!=null) {
      result["modifiedDate"] = AppDateTime().formatDateTime(modifiedDate, ignoreTimeZone: true);
    }
    if(submissionResult!=null) {
      result["submissionResult"] = submissionResult;
    }
    if(allDay!=null) {
      result["allDay"] = allDay;
    }
    if(recurringFlag!=null) {
      result["recurringFlag"] = recurringFlag;
    }
    if(recurrenceId!=null) {
      result["recurrenceId"] = recurrenceId;
    }
    if(isRecurring && CollectionUtils.isNotEmpty(recurringEvents)) {
      result["recurringEvents"] = _encodeRecurringEvents();
    }
    if(convergeScore!=null) {
      result["converge_score"] = convergeScore;
    }
    if(convergeUrl!=null) {
      result["converge_url"] = convergeUrl;
    }
    if(isSuperEvent!=null) {
      result["isSuperEvent"] = isSuperEvent;
    }
    if(displayOnlyWithSuperEvent!=null) {
      result["displayOnlyWithSuperEvent"] = displayOnlyWithSuperEvent;
    }
    if(subEventsMap!=null) {
      result["subEvents"] = subEventsMap;
    }
    if(track!=null) {
      result["track"] = track;
    }
    if(isVirtual!=null) {
      result['isVirtual']= isVirtual;
    }
    if(virtualEventUrl!=null) {
      result['virtualEventUrl']= virtualEventUrl;
    }
    if(isInPerson!=null) {
      result['isInPerson']= isInPerson;
    }
    if(createdByGroupId!=null) {
      result['createdByGroupId']= createdByGroupId;
    }
    if(isGroupPrivate!=null) {
      result['isGroupPrivate']= isGroupPrivate;
    }
    if(isEventFree!=null) {
      result['isEventFree']= isEventFree;
    }

    return result;
  }

  static List<Event>? listFromJson(List<dynamic>? jsonList) {
    List<Event>? result;
    if (jsonList != null) {
      result = <Event>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, Event.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<Event>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  List<dynamic> _encodeContacts(){
    List<dynamic> result = [];
    if(contacts!=null && contacts!.isNotEmpty) {
      for (var contact in contacts!) {
        result.add(contact.toJson());
      }
    }

    return result;
  }

  List<dynamic>? _encodeRecurringEvents() {
    if (!isRecurring) {
      return null;
    }
    List<dynamic> eventsList = [];
    for (var event in recurringEvents!) {
      eventsList.add(event.toJson());
    }
    return eventsList;
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  int compareTo(Explore other) {
    return (other is Event) ?
      SortUtils.compare(convergeScore, other.convergeScore, descending: true) : //Descending order by score
      super.compareTo(other); 
  }

  bool get isGameEvent {
    bool isAthletics = (category == "Athletics" || category == "Recreation");
    bool hasGameId = StringUtils.isNotEmpty(speaker);
    bool hasRegistrationFlag = StringUtils.isNotEmpty(registrationLabel);
    return isAthletics && hasGameId && hasRegistrationFlag;
  }

  bool get isRecurring {
    return (recurringFlag == true) && (recurringEvents?.isNotEmpty ?? false);
  }

  void addRecurrentEvent(Event event) {
    recurringEvents ??= <Event>[];
    recurringEvents!.add(event);
  }

  void sortRecurringEvents() {
    if (isRecurring) {
      recurringEvents!.sort((Event? first, Event? second) {
        DateTime? firstStartDate = first?.startDateGmt;
        DateTime? secondStartDate = second?.startDateGmt;
        if (firstStartDate != null && secondStartDate != null) {
          return firstStartDate.compareTo(secondStartDate);
        } else if (firstStartDate != null) {
          return -1;
        } else if (secondStartDate != null) {
          return 1;
        } else {
          return 0;
        }
      });
    }
  }

  List<Event>? get subEvents {
    return _subEvents;
  }

  void addSubEvent(Event event) {
    if (isSuperEvent != true) {
      return;
    }
    _subEvents ??= <Event>[];
    _subEvents!.add(event);
  }

  List<Event>? get featuredEvents {
    return _featuredEvents;
  }

  void addFeaturedEvent(Event event) {
    if (isSuperEvent != true) {
      return;
    }
    _featuredEvents ??= <Event>[];
    _featuredEvents!.add(event);
  }

  bool get isComposite {
    return isRecurring || (isSuperEvent == true);
  }

  bool get isMultiEvent {
    return isComposite || isMoreThanOneDay;
  }

  bool get isMoreThanOneDay {
    int eventDays = (endDateGmt?.difference(startDateGmt!).inDays ?? 0).abs();
    return (eventDays >= 1);
  }

  bool get isNotTheSameYear {
    int startYear = startDateGmt?.year ?? 0;
    int endYear = endDateGmt?.year ?? 0;
    return (startYear != endYear);
  }

  static List<Map<String, dynamic>>? _constructSubEventsMap(List<dynamic>? subEventsJson) {
    if (subEventsJson == null || subEventsJson.isEmpty) {
      return null;
    }
    List<Map<String, dynamic>> subEvents = <Map<String, dynamic>>[];
    for (dynamic eventDynamic in subEventsJson) {
      if (eventDynamic is Map<String, dynamic>) {
        subEvents.add(eventDynamic);
      }
    }
    return subEvents;
  }

  // Explore
  @override String?   get exploreId               { return id ?? eventId; }
  @override String?   get exploreTitle            { return title; }
  @override String?   get exploreDescription      { return description; }
  @override DateTime? get exploreStartDateUtc     { return startDateGmt; }
  @override String?   get exploreImageURL         { return StringUtils.isNotEmpty(imageURL) ? imageURL : randomImageURL; }
  @override ExploreLocation? get exploreLocation  { return location; }

  DateTime? get startDateLocal     { return AppDateTime().getUniLocalTimeFromUtcTime(startDateGmt); }
  DateTime? get endDateLocal       { return AppDateTime().getUniLocalTimeFromUtcTime(endDateGmt); }

  // Favorite
  static const String favoriteKeyName = "eventIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
}

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
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        organization: json['organization']) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
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

//////////////////////////////
/// EventCategory

class EventCategory {

  final String? name;
  final List<String>? subCategories;

  EventCategory({this.name, this.subCategories});

  static EventCategory? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? EventCategory(
      name: json['category'],
      subCategories: JsonUtils.listStringsValue(json['subcategories'])
    ) : null;
  }

  toJson(){
    return{
      'category': name,
      'subcategories': subCategories
    };
  }

  static List<EventCategory>? listFromJson(List<dynamic>? jsonList) {
    List<EventCategory>? result;
    if (jsonList is List) {
      result = <EventCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, EventCategory.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

}

enum EventTimeFilter{today, thisWeekend, next7Day, next30Days, upcoming,}


