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
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:intl/intl.dart';

//////////////////////////////
// Group

class Group {
	String?             id;
	String?             category;
	String?             type;
	String?             title;
  String?             description;
  GroupPrivacy?       privacy;
  DateTime?           dateCreatedUtc;
  DateTime?           dateUpdatedUtc;

  bool?               certified;
  bool?               hiddenForSearch;
  bool?               canJoinAutomatically;
  bool?               onlyAdminsCanCreatePolls;

  bool?               authManEnabled;
  String?             authManGroupName;

  bool?               attendanceGroup;
  
  bool?               researchGroup;
  bool?               researchOpen;
  String?             researchDescription;
  Map<String, dynamic>? researchProfile; 

  String?             imageURL;
  String?             webURL;
  Member?             currentMember;
  List<String>?       tags;
  List<GroupMembershipQuestion>? questions;
  GroupMembershipQuest? membershipQuest; // MD: Looks as deprecated. Consider and remove if need!

  Group({
	  this.id, this.category, this.type, this.title, this.description, this.privacy, this.dateCreatedUtc, this.dateUpdatedUtc,
    this.certified, this.hiddenForSearch, this.canJoinAutomatically, this.onlyAdminsCanCreatePolls,
    this.authManEnabled, this.authManGroupName, this.attendanceGroup,
    this.researchGroup, this.researchOpen, this.researchDescription, this.researchProfile,
    this.imageURL, this.webURL, this.currentMember, this.tags, this.questions, this.membershipQuest,
    });

  static Group? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Group(
      id                : JsonUtils.stringValue(json['id']),
      category          : JsonUtils.stringValue(json['category']),
      type              : JsonUtils.stringValue(json['type']),
      title             : JsonUtils.stringValue(json['title']),
      description       : JsonUtils.stringValue(json['description']),
      privacy           : groupPrivacyFromString(JsonUtils.stringValue(json['privacy'])),
      dateCreatedUtc    : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_created'])),
      dateUpdatedUtc    : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_updated'])),
      
      certified         : JsonUtils.boolValue(json['certified']),
      hiddenForSearch   : JsonUtils.boolValue(json['hidden_for_search']),
      canJoinAutomatically : JsonUtils.boolValue(json['can_join_automatically']),
      onlyAdminsCanCreatePolls : JsonUtils.boolValue(json['only_admins_can_create_polls']),

      authManEnabled    : JsonUtils.boolValue(json['authman_enabled']),
      authManGroupName  : JsonUtils.stringValue(json['authman_group']),
      
      attendanceGroup   : JsonUtils.boolValue(json['attendance_group']),

      researchGroup     : JsonUtils.boolValue(json['research_group']),
      researchOpen      : JsonUtils.boolValue(json['research_open']),
      researchDescription: JsonUtils.stringValue(json['research_description']),
      researchProfile   : JsonUtils.mapValue(json['research_profile']),
      
      imageURL          : JsonUtils.stringValue(json['image_url']),
      webURL            : JsonUtils.stringValue(json['web_url']),
      currentMember     : Member.fromJson(JsonUtils.mapValue(json['current_member'])),
      tags              : JsonUtils.listStringsValue(json['tags']),
      questions         : GroupMembershipQuestion.listFromStringList(JsonUtils.stringListValue(json['membership_questions'])),
      membershipQuest   : GroupMembershipQuest.fromJson(JsonUtils.mapValue(json['membership_quest'])),
    ) : null;
  }

  static Group? fromOther(Group? other) {
    return (other != null) ? Group(
      id                : other.id,
      category          : other.category,
      type              : other.type,
      title             : other.title,
      description       : other.description,
      privacy           : other.privacy,
      dateCreatedUtc    : other.dateCreatedUtc,
      dateUpdatedUtc    : other.dateUpdatedUtc,

      certified         : other.certified,
      hiddenForSearch   : other.hiddenForSearch,
      canJoinAutomatically : other.canJoinAutomatically,
      onlyAdminsCanCreatePolls : other.onlyAdminsCanCreatePolls,

      authManEnabled    : other.authManEnabled,
      authManGroupName  : other.authManGroupName,

      attendanceGroup   : other.attendanceGroup,

      researchGroup     : other.researchGroup,
      researchOpen      : other.researchOpen,
      researchDescription: other.researchDescription,
      researchProfile   : MapUtils.from(other.researchProfile),

      imageURL          : other.imageURL,
      webURL            : other.webURL,
      currentMember     : other.currentMember,
      tags              : ListUtils.from(other.tags),
      questions         : GroupMembershipQuestion.listFromOthers(other.questions),
      membershipQuest   : GroupMembershipQuest.fromOther(other.membershipQuest),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id'                            : id,
      'category'                      : category,
      'type'                          : type,
      'title'                         : title,
      'description'                   : description,
      'privacy'                       : groupPrivacyToString(privacy),
      'date_created'                  : groupUtcDateTimeToString(dateCreatedUtc),
      'date_updated'                  : groupUtcDateTimeToString(dateUpdatedUtc),
      
      'certified'                     : certified,
      'hidden_for_search'             : hiddenForSearch,
      'can_join_automatically'        : canJoinAutomatically,
      'only_admins_can_create_polls'  : onlyAdminsCanCreatePolls,

      'authman_enabled'               : authManEnabled,
      'authman_group'                 : authManGroupName,

      'attendance_group'              : attendanceGroup,

      'research_group'                : researchGroup,
      'research_open'                 : researchOpen,
      'research_description'          : researchDescription,
      'research_profile'              : researchProfile,

      'image_url'                     : imageURL,
      'web_url'                       : webURL,
      'current_member'                : currentMember?.toJson(),
      'tags'                          : tags,
      'membership_questions'          : GroupMembershipQuestion.listToStringList(questions),
      'membership_quest'              : membershipQuest?.toJson(),
    };
  }

  @override
  bool operator ==(dynamic other) =>
    (other is Group) &&
      (other.id == id) &&
      (other.category == category) &&
      (other.type == type) &&
      (other.title == title) &&
      (other.description == description) &&
      (other.privacy == privacy) &&
      (other.dateCreatedUtc == dateCreatedUtc) &&
      (other.dateUpdatedUtc == dateUpdatedUtc) &&

      (other.certified == certified) &&
      (other.hiddenForSearch == hiddenForSearch) &&
      (other.canJoinAutomatically == canJoinAutomatically) &&
      (other.onlyAdminsCanCreatePolls == onlyAdminsCanCreatePolls) &&
      
      (other.authManEnabled == authManEnabled) &&
      (other.authManGroupName == authManGroupName) &&

      (other.attendanceGroup == attendanceGroup) &&

      (other.researchGroup == researchGroup) &&
      (other.researchOpen == researchOpen) &&
      (other.researchDescription == researchDescription) &&
      (const DeepCollectionEquality().equals(other.researchProfile, researchProfile)) &&

      (other.imageURL == imageURL) &&
      (other.webURL == webURL) &&
      (other.currentMember == currentMember) &&
      (const DeepCollectionEquality().equals(other.tags, tags)) &&
      (const DeepCollectionEquality().equals(other.questions, questions)) &&
      (other.membershipQuest == membershipQuest);


  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (category?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (privacy?.hashCode ?? 0) ^
    (dateCreatedUtc?.hashCode ?? 0) ^
    (dateUpdatedUtc?.hashCode ?? 0) ^

    (certified?.hashCode ?? 0) ^
    (hiddenForSearch?.hashCode ?? 0) ^
    (onlyAdminsCanCreatePolls?.hashCode ?? 0) ^
    (canJoinAutomatically?.hashCode ?? 0) ^

    (authManEnabled?.hashCode ?? 0) ^
    (authManGroupName?.hashCode ?? 0) ^

    (attendanceGroup?.hashCode ?? 0) ^

    (researchGroup?.hashCode ?? 0) ^
    (researchOpen?.hashCode ?? 0) ^
    (researchDescription?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(researchProfile)) ^

    (imageURL?.hashCode ?? 0) ^
    (webURL?.hashCode ?? 0) ^
    (currentMember?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(tags)) ^
    (const DeepCollectionEquality().hash(questions)) ^
    (membershipQuest?.hashCode ?? 0);

  bool get currentUserIsAdmin{
    return (currentMember?.isAdmin ?? false);
  }

  bool get currentUserIsPendingMember{
    return (currentMember?.isPendingMember ?? false);
  }

  bool get currentUserIsMember{
    return (currentMember?.isMember ?? false);
  }

  bool get currentUserIsMemberOrAdmin{
    return (currentMember?.isMemberOrAdmin ?? false);
  }

  bool get currentUserIsMemberOrAdminOrPending{
    return (currentMember?.isMemberOrAdminOrPending ?? false);
  }

  bool get currentUserCanJoin {
    return (currentMember == null) && (authManEnabled != true);
  }

  bool get syncAuthmanAllowed {
    return (currentUserIsAdmin == true) && (authManEnabled == true);
  }

  ///
  /// Show hidden group only if the user is admin
  ///
  ///
  bool get isVisible {
    return !(hiddenForSearch ?? false) || currentUserIsAdmin;
  }

  static List<Group>? listFromJson(List<dynamic>? json) {
    List<Group>? values;
    if (json != null) {
      values = <Group>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Group.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Group>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Group value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupPrivacy

enum GroupPrivacy { private, public }

GroupPrivacy? groupPrivacyFromString(String? value) {
  if (value != null) {
    if (value == 'private') {
      return GroupPrivacy.private;
    }
    else if (value == 'public') {
      return GroupPrivacy.public;
    }
  }
  return null;
}

String? groupPrivacyToString(GroupPrivacy? value) {
  if (value != null) {
    if (value == GroupPrivacy.private) {
      return 'private';
    }
    else if (value == GroupPrivacy.public) {
      return 'public';
    }
  }
  return null;
}

//////////////////////////////
// GroupStats

class GroupStats {
  final int? totalCount;
  final int? membersCount;
  final int? adminsCount;
  final int? pendingCount;
  final int? rejectedCount;
  final int? attendedCount;

  GroupStats({this.totalCount, this.membersCount, this.adminsCount, this.pendingCount, this.rejectedCount, this.attendedCount});

  static GroupStats? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupStats(
        totalCount: JsonUtils.intValue(json['total_count']),
        membersCount: JsonUtils.intValue(json['member_count']),
        adminsCount: JsonUtils.intValue(json['admins_count']),
        pendingCount: JsonUtils.intValue(json['pending_count']),
        rejectedCount: JsonUtils.intValue(json['rejected_count']),
        attendedCount: JsonUtils.intValue(json['attendance_count'])
      ) : null;
  }

  int get activeMembersCount {
    return (membersCount ?? 0) + (adminsCount ?? 0);
  }
}

//////////////////////////////
// Member

class Member {
	String?            id;
  String?            userId;
  String?            externalId;
	String?            name;
	String?            email;
  GroupMemberStatus? status;
  String?            officerTitle;
  
  List<GroupMembershipAnswer>? answers;

  DateTime?          dateAttendedUtc;
  DateTime?          dateCreatedUtc;
  DateTime?          dateUpdatedUtc;

  Member({
    this.id, this.userId, this.externalId, this.name, this.email, this.status, this.officerTitle,
    this.dateAttendedUtc, this.dateCreatedUtc, this.dateUpdatedUtc,
    this.answers,
  });

  static Member? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Member(
      id          : JsonUtils.stringValue(json['id']),
      userId      : JsonUtils.stringValue(json['user_id']),
      externalId  : JsonUtils.stringValue(json['external_id']),
      name        : JsonUtils.stringValue(json['name']),
      email       : JsonUtils.stringValue(json['email']),
      status      : groupMemberStatusFromString(JsonUtils.stringValue(json['status'])),
      officerTitle : JsonUtils.stringValue(json['officerTitle']),
      
      answers : GroupMembershipAnswer.listFromJson(JsonUtils.listValue(json['member_answers'])),

      dateAttendedUtc : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_attended'])),
      dateCreatedUtc  : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_created'])),
      dateUpdatedUtc  : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_updated'])),
    ) : null;
  }

  static Member? fromOther(Member? other) {
    return (other != null) ? Member(
      id              : other.id,
      userId          : other.userId,
      externalId      : other.externalId,
      name            : other.name,
      status          : other.status,
      officerTitle    : other.officerTitle,

      answers         : GroupMembershipAnswer.listFromOther(other.answers),

      dateAttendedUtc : other.dateAttendedUtc,
      dateCreatedUtc  : other.dateCreatedUtc,
      dateUpdatedUtc  : other.dateUpdatedUtc,
    ) : null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id']                  = id;
    json['user_id']             = userId;
    json['external_id']         = externalId;
    json['name']                = name;
    json['email']               = email;
    json['status']              = groupMemberStatusToString(status);
    json['officerTitle']        = officerTitle;

    json['answers']             = GroupMembershipAnswer.listToJson(answers);

    json['date_attended']       = groupUtcDateTimeToString(dateAttendedUtc);
    json['date_created']        = groupUtcDateTimeToString(dateCreatedUtc);
    json['date_updated']        = groupUtcDateTimeToString(dateUpdatedUtc);

    return json;
  }

  String get displayName {
    String displayName = '';
    if (StringUtils.isNotEmpty(name)) {
      displayName += name!;
    }
    if (StringUtils.isNotEmpty(email)) {
      if (StringUtils.isNotEmpty(displayName)) {
        displayName += ' ';
      }
      displayName += email!;
    }
    if (StringUtils.isNotEmpty(externalId)) {
      if (StringUtils.isNotEmpty(displayName)) {
        displayName += ' ';
      }
      displayName += externalId!;
    }
    return displayName;
  }

  String get displayShortName {
    if (StringUtils.isNotEmpty(name)) {
      return name!;
    }
    if (StringUtils.isNotEmpty(email)) {
      return email!;
    }
    if (StringUtils.isNotEmpty(externalId)) {
      return externalId!;
    }
    return "";
  }


  @override
  bool operator ==(dynamic other) =>
    (other is Member) &&
      (other.id == id) &&
      (other.userId == userId) &&
      (other.externalId == externalId) &&
      (other.name == name) &&
      (other.email == email) &&
      (other.status == status) &&
      (other.officerTitle == officerTitle) &&
      (other.dateAttendedUtc == dateAttendedUtc) &&
      (other.dateCreatedUtc == dateCreatedUtc) &&
      (other.dateUpdatedUtc == dateUpdatedUtc) &&
      const DeepCollectionEquality().equals(other.answers, answers);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (userId?.hashCode ?? 0) ^
    (externalId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (email?.hashCode ?? 0) ^
    (status?.hashCode ?? 0) ^
    (officerTitle?.hashCode ?? 0) ^
    (dateAttendedUtc?.hashCode ?? 0) ^
    (dateCreatedUtc?.hashCode ?? 0) ^
    (dateUpdatedUtc?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(answers));

  bool get isAdmin          => status == GroupMemberStatus.admin;
  bool get isMember         => status == GroupMemberStatus.member;
  bool get isPendingMember  => status == GroupMemberStatus.pending;
  bool get isRejected       => status == GroupMemberStatus.rejected;

  bool get isMemberOrAdmin  => isMember || isAdmin;
  bool get isMemberOrAdminOrPending  => isMemberOrAdmin || isPendingMember;

  static List<Member>? listFromJson(List<dynamic>? json) {
    List<Member>? values;
    if (json != null) {
      values = <Member>[];
      for (dynamic entry in json) {
        ListUtils.add(values, Member.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Member>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Member? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//////////////////////////////
// GroupMemberStatus

enum GroupMemberStatus { pending, member, admin, rejected }

GroupMemberStatus? groupMemberStatusFromString(String? value) {
  if (value != null) {
    if (value == 'pending') {
      return GroupMemberStatus.pending;
    } else if (value == 'member') {
      return GroupMemberStatus.member;
    } else if (value == 'admin') {
      return GroupMemberStatus.admin;
    } else if (value == 'rejected') {
      return GroupMemberStatus.rejected;
    }
  }
  return null;
}

String? groupMemberStatusToString(GroupMemberStatus? value) {
  if (value != null) {
    if (value == GroupMemberStatus.pending) {
      return 'pending';
    } else if (value == GroupMemberStatus.member) {
      return 'member';
    } else if (value == GroupMemberStatus.admin) {
      return 'admin';
    } else if (value == GroupMemberStatus.rejected) {
      return 'rejected';
    }
  }
  return null;
}

//////////////////////////////
// GroupMembershipQuest

class GroupMembershipQuest {
  List<GroupMembershipStep>? steps;

  GroupMembershipQuest({this.steps});

  static GroupMembershipQuest? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupMembershipQuest(
      steps : GroupMembershipStep.listFromJson(JsonUtils.listValue(json['steps'])),
    ) : null;
  }

  static GroupMembershipQuest? fromOther(GroupMembershipQuest? other) {
    return (other != null) ? GroupMembershipQuest(
      steps : GroupMembershipStep.listFromOthers(other.steps),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'steps' : GroupMembershipStep.listToJson(steps),
    };
  }

  @override
  bool operator ==(other) =>
    (other is GroupMembershipQuest) &&
      const DeepCollectionEquality().equals(other.steps, steps);

  @override
  int get hashCode =>
    (const DeepCollectionEquality().hash(steps));
}

//////////////////////////////
// GroupMembershipStep

class GroupMembershipStep {
	String?       description;
  List<String>? eventIds;

  GroupMembershipStep({this.description, this.eventIds});

  static GroupMembershipStep? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GroupMembershipStep(
      description : JsonUtils.stringValue(json['description']),
      eventIds    : JsonUtils.stringListValue(json['eventIds']),
    ) : null;
  }

  static GroupMembershipStep? fromOther(GroupMembershipStep? other) {
    return (other != null) ? GroupMembershipStep(
  	  description : other.description,
      eventIds    : ListUtils.from(other.eventIds),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'eventIds': eventIds,
    };
  }

  @override
  bool operator ==(other) =>
    (other is GroupMembershipStep) &&
      (other.description == description) &&
      const DeepCollectionEquality().equals(other.eventIds, eventIds);

  @override
  int get hashCode =>
    (description?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(eventIds));

  static List<GroupMembershipStep>? listFromJson(List<dynamic>? json) {
    List<GroupMembershipStep>? values;
    if (json != null) {
      values = <GroupMembershipStep>[];
      for (dynamic entry in json) {
        ListUtils.add(values, GroupMembershipStep.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<GroupMembershipStep>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (GroupMembershipStep? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }

  static List<GroupMembershipStep>? listFromOthers(List<GroupMembershipStep>? others) {
    List<GroupMembershipStep>? values;
    if (others != null) {
      values = <GroupMembershipStep>[];
      for (GroupMembershipStep? other in others) {
          ListUtils.add(values, GroupMembershipStep.fromOther(other));
      }
    }
    return values;
  }
}

//////////////////////////////
// GroupMembershipQuestion

class GroupMembershipQuestion {
	String?       question;

  GroupMembershipQuestion({this.question});

  static GroupMembershipQuestion? fromString(String? question) {
    return (question != null) ? GroupMembershipQuestion(question: question) : null;
  }

  String? toStirng() {
    return question;
  }

  @override
  bool operator ==(other) =>
    (other is GroupMembershipQuestion) &&
      (other.question == question);

  @override
  int get hashCode =>
    (question?.hashCode ?? 0);

  static List<GroupMembershipQuestion>? listFromOthers(List<GroupMembershipQuestion>? others) {
    List<GroupMembershipQuestion>? values;
    if (others != null) {
      values = <GroupMembershipQuestion>[];
      for (GroupMembershipQuestion? other in others) {
        ListUtils.add(values, GroupMembershipQuestion.fromString(other!.question));
      }
    }
    return values;
  }

  static List<GroupMembershipQuestion>? listFromStringList(List<String>? strings) {
    List<GroupMembershipQuestion>? values;
    if (strings != null) {
      values = <GroupMembershipQuestion>[];
      for (String string in strings) {
        ListUtils.add(values, GroupMembershipQuestion.fromString(string));
      }
    }
    return values;
  }

  static List<String>? listToStringList(List<GroupMembershipQuestion>? values) {
    List<String>? strings;
    if (values != null) {
      strings = <String>[];
      for (GroupMembershipQuestion value in values) {
        ListUtils.add(strings, value.question);
      }
    }
    return strings;
  }
}

//////////////////////////////
// GroupMembershipQuestionAnswer

class GroupMembershipAnswer {
  String?       question;
  String?       answer;

  GroupMembershipAnswer({this.question, this.answer});

  static GroupMembershipAnswer? fromJson(Map<String, dynamic>? json){
    return (json != null) ? GroupMembershipAnswer(
      question: JsonUtils.stringValue(json["question"]),
      answer: JsonUtils.stringValue(json["answer"]),
    ) : null;
  }

  static GroupMembershipAnswer? fromOther(GroupMembershipAnswer? other){
    return (other != null) ? GroupMembershipAnswer(
      question: other.question,
      answer: other.answer,
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "answer": answer,
    };
  }

  @override
  bool operator ==(other) =>
    (other is GroupMembershipAnswer) &&
      (other.question == question) &&
      (other.answer == answer);

  @override
  int get hashCode =>
    (question?.hashCode ?? 0) ^
    (answer?.hashCode ?? 0);

  static List<GroupMembershipAnswer>? listFromJson(List<dynamic>? json) {
    List<GroupMembershipAnswer>? values;
    if (json != null) {
      values = <GroupMembershipAnswer>[];
      for (dynamic entry in json) {
        ListUtils.add(values, GroupMembershipAnswer.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<GroupMembershipAnswer>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (GroupMembershipAnswer value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }

  static List<GroupMembershipAnswer>? listFromOther(List<GroupMembershipAnswer>? values) {
    List<GroupMembershipAnswer>? result;
    if (values != null) {
      result = <GroupMembershipAnswer>[];
      for (GroupMembershipAnswer value in values) {
        ListUtils.add(result, GroupMembershipAnswer.fromOther(value));
      }
    }
    return result;
  }
}

//////////////////////////////
// GroupPost

class GroupPost {
  final String? id;
  final String? parentId;
  final Member? member;
  final String? subject;
  final String? body;
  final DateTime? dateCreatedUtc;
  final DateTime? dateUpdatedUtc;
  final bool? private;
  final List<GroupPost>? replies;
  final List<Member>? members;
  final String? imageUrl;
  final Map<String, List<String>> reactions;

  GroupPost({this.id, this.parentId, this.member, this.subject, this.body, this.dateCreatedUtc, this.dateUpdatedUtc, this.private, this.imageUrl, this.replies, this.members, this.reactions = const {}});

  static GroupPost? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    Map<String, List<String>> reactions = {};
    Map<String, dynamic>? reactionsRaw = JsonUtils.mapValue(json['reactions']);
    if (reactionsRaw != null) {
      for (MapEntry<String, dynamic> reaction in reactionsRaw.entries) {
        List<String>? ids = JsonUtils.listStringsValue(reaction.value);
        if (ids != null) {
          reactions[reaction.key] = ids;
        }
      }
    }

    return GroupPost(
        id: json['id'],
        parentId: json['parent_id'],
        member: Member.fromJson(json['member']),
        subject: json['subject'],
        body: json['body'],
        dateCreatedUtc: groupUtcDateTimeFromString(json['date_created']),
        dateUpdatedUtc: groupUtcDateTimeFromString(json['date_updated']),
        private: json['private'],
        imageUrl: JsonUtils.stringValue(json["image_url"]),
        replies: GroupPost.fromJsonList(json['replies']),
        members: Member.listFromJson(json['to_members']),
        reactions: reactions,
      );

  }

  Map<String, dynamic> toJson({bool create = false, bool update = false}) {
    // MV: This does not look well at all!
    Map<String, dynamic> json = {'body': body, 'private': private};
    if ((parentId != null) && create) {
      json['parent_id'] = parentId;
    }
    if ((id != null) && update) {
      json['id'] = id;
    }
    if (subject != null) {
      json['subject'] = subject;
    }
    if(imageUrl!=null){
      json['image_url'] = imageUrl;
    }
    if(members!=null){
      json['to_members'] = Member.listToJson(members);
    }
    return json;
  }

  bool get isUpdated {
    return (dateUpdatedUtc != null) && (dateCreatedUtc != dateUpdatedUtc);
  }

  static List<GroupPost>? fromJsonList(List<dynamic>? jsonList) {
    List<GroupPost>? posts;
    if (jsonList != null) {
      posts = <GroupPost>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(posts, GroupPost.fromJson(jsonEntry));
      }
    }
    return posts;
  }
}

//Model for editable post data. Helping to keep GroupPost immutable. Internal use
class PostDataModel {
  String? body;
  String? subject;
  String? imageUrl;
  List<Member>? members;

  PostDataModel({this.body, this.subject, this.imageUrl, this.members});
}

//////////////////////////////
// GroupPostNudge

class GroupPostNudge {
  final String? id;
  final dynamic groupNames;
  final String? subject;
  final String? body;
  final bool? canPoll;

  GroupPostNudge({this.id, this.groupNames, this.subject, this.body, this.canPoll});

  static GroupPostNudge? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GroupPostNudge(
        id: JsonUtils.stringValue(json['id']),
        groupNames: json['group_name'],
        subject: JsonUtils.stringValue(json['subject']),
        body: JsonUtils.stringValue(json['body']),
        canPoll: JsonUtils.boolValue(json['can_poll']));
  }

  static List<GroupPostNudge>? fromJsonList(List<dynamic>? jsonList) {
    List<GroupPostNudge>? templates;
    if (jsonList != null) {
      templates = <GroupPostNudge>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(templates, GroupPostNudge.fromJson(jsonEntry));
      }
    }
    return templates;
  }
}

//////////////////////////////
// GroupError

class GroupError {
  int?       code;
  String?    text;

  GroupError({this.code, this.text});

  static GroupError? fromJson(Map<String, dynamic>? json){
    return json != null ? GroupError(
      code: JsonUtils.intValue(json['code']),
      text: JsonUtils.stringValue(json['text'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "text": text,
    };
  }
}

DateTime? groupUtcDateTimeFromString(String? dateTimeString) {
  return DateTimeUtils.dateTimeFromString(dateTimeString, format: "yyyy-MM-ddTHH:mm:ssZ", isUtc: true);
}

String? groupUtcDateTimeToString(DateTime? dateTime) {
  if (dateTime != null) {
    try { return DateFormat("yyyy-MM-ddTHH:mm:ss").format(dateTime) + 'Z'; }
    catch (e) { debugPrint(e.toString()); }
  }
  return null;
}

