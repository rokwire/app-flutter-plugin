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
	String?                       id;
	Map<String, dynamic>?         attributes;
	String?                       type;
	String?                       title;
  String?                       description;
  GroupPrivacy?                 privacy;

  DateTime?                     dateCreatedUtc;
  DateTime?                     dateUpdatedUtc;
  DateTime?                     dateManagedMembershipUpdatedUtc;
  DateTime?                     dateMembershipUpdatedUtc;

  bool?                         certified;
  bool?                         hiddenForSearch;
  bool?                         canJoinAutomatically;
  bool?                         onlyAdminsCanCreatePolls;

  bool?                         authManEnabled;
  String?                       authManGroupName;

  bool?                         attendanceGroup;
  
  bool?                         researchProject;
  bool?                         researchOpen;
  String?                       researchConsentDetails;
  String?                       researchConsentStatement;
  Map<String, dynamic>?         researchProfile; 

  String?                        imageURL;
  String?                        webURL;
  Member?                        currentMember;
  List<String>?                  tags;
  List<GroupMembershipQuestion>? questions;
  GroupMembershipQuest?          membershipQuest; // MD: Looks as deprecated. Consider and remove if need!
  GroupSettings?                 settings;

  Group({
	  this.id, this.attributes, this.type, this.title, this.description, this.privacy, 
    this.dateCreatedUtc, this.dateUpdatedUtc, this.dateManagedMembershipUpdatedUtc, this.dateMembershipUpdatedUtc,
    this.certified, this.hiddenForSearch, this.canJoinAutomatically, this.onlyAdminsCanCreatePolls,
    this.authManEnabled, this.authManGroupName, this.attendanceGroup,
    this.researchProject, this.researchOpen, this.researchConsentDetails, this.researchConsentStatement, this.researchProfile,
    this.imageURL, this.webURL, this.currentMember, this.tags, this.questions, this.membershipQuest, this.settings
    });

  static Group? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Group(
      id                             : JsonUtils.stringValue(json['id']),
      attributes                     : JsonUtils.mapValue(json['attributes']),
      type                           : JsonUtils.stringValue(json['type']),
      title                          : JsonUtils.stringValue(json['title']),
      description                    : JsonUtils.stringValue(json['description']),
      privacy                        : groupPrivacyFromString(JsonUtils.stringValue(json['privacy'])),

      dateCreatedUtc                   : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_created'])),
      dateUpdatedUtc                   : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_updated'])),
      dateManagedMembershipUpdatedUtc  : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_managed_membership_updated'])),
      dateMembershipUpdatedUtc         : groupUtcDateTimeFromString(JsonUtils.stringValue(json['date_membership_updated'])),
      
      certified                      : JsonUtils.boolValue(json['certified']),
      hiddenForSearch                : JsonUtils.boolValue(json['hidden_for_search']),
      canJoinAutomatically           : JsonUtils.boolValue(json['can_join_automatically']),
      onlyAdminsCanCreatePolls       : JsonUtils.boolValue(json['only_admins_can_create_polls']),

      authManEnabled                 : JsonUtils.boolValue(json['authman_enabled']),
      authManGroupName               : JsonUtils.stringValue(json['authman_group']),
      
      attendanceGroup                : JsonUtils.boolValue(json['attendance_group']),

      researchProject                : JsonUtils.boolValue(json['research_group']),
      researchOpen                   : JsonUtils.boolValue(json['research_open']),
      researchConsentDetails         : JsonUtils.stringValue(json['research_consent_details']),
      researchConsentStatement       : JsonUtils.stringValue(json['research_consent_statement']),
      researchProfile                : JsonUtils.mapValue(json['research_profile']),
      
      imageURL                       : JsonUtils.stringValue(json['image_url']),
      webURL                         : JsonUtils.stringValue(json['web_url']),
      currentMember                  : Member.fromJson(JsonUtils.mapValue(json['current_member'])),
      tags                           : JsonUtils.listStringsValue(json['tags']),
      questions                      : GroupMembershipQuestion.listFromStringList(JsonUtils.stringListValue(json['membership_questions'])),
      membershipQuest                : GroupMembershipQuest.fromJson(JsonUtils.mapValue(json['membership_quest'])),
      settings                         : GroupSettings.fromJson(JsonUtils.mapValue(json['settings']))
    ) : null;
  }

  static Group? fromOther(Group? other) {
    return (other != null) ? Group(
      id                             : other.id,
      attributes                     : MapUtils.from(other.attributes),
      type                           : other.type,
      title                          : other.title,
      description                    : other.description,
      privacy                        : other.privacy,

      dateCreatedUtc                   : other.dateCreatedUtc,
      dateUpdatedUtc                   : other.dateUpdatedUtc,
      dateManagedMembershipUpdatedUtc  : other.dateManagedMembershipUpdatedUtc,
      dateMembershipUpdatedUtc         : other.dateMembershipUpdatedUtc,

      certified                      : other.certified,
      hiddenForSearch                : other.hiddenForSearch,
      canJoinAutomatically           : other.canJoinAutomatically,
      onlyAdminsCanCreatePolls       : other.onlyAdminsCanCreatePolls,

      authManEnabled                 : other.authManEnabled,
      authManGroupName               : other.authManGroupName,

      attendanceGroup                : other.attendanceGroup,

      researchProject                : other.researchProject,
      researchOpen                   : other.researchOpen,
      researchConsentDetails         : other.researchConsentDetails,
      researchConsentStatement       : other.researchConsentStatement,
      researchProfile                : MapUtils.from(other.researchProfile),

      imageURL                       : other.imageURL,
      webURL                         : other.webURL,
      currentMember                  : other.currentMember,
      tags                           : ListUtils.from(other.tags),
      questions                      : GroupMembershipQuestion.listFromOthers(other.questions),
      membershipQuest                : GroupMembershipQuest.fromOther(other.membershipQuest),
      settings                          : GroupSettings.fromOther(other.settings),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id'                            : id,
      'attributes'                    : attributes,
      'type'                          : type,
      'title'                         : title,
      'description'                   : description,
      'privacy'                       : groupPrivacyToString(privacy),
      
      'date_created'                     : groupUtcDateTimeToString(dateCreatedUtc),
      'date_updated'                     : groupUtcDateTimeToString(dateUpdatedUtc),
      'date_managed_membership_updated'  : groupUtcDateTimeToString(dateManagedMembershipUpdatedUtc),
      'date_membership_updated'          : groupUtcDateTimeToString(dateMembershipUpdatedUtc),
      
      'certified'                     : certified,
      'hidden_for_search'             : hiddenForSearch,
      'can_join_automatically'        : canJoinAutomatically,
      'only_admins_can_create_polls'  : onlyAdminsCanCreatePolls,

      'authman_enabled'               : authManEnabled,
      'authman_group'                 : authManGroupName,

      'attendance_group'              : attendanceGroup,

      'research_group'                : researchProject,
      'research_open'                 : researchOpen,
      'research_consent_details'      : researchConsentDetails,
      'research_consent_statement'    : researchConsentStatement,
      'research_profile'              : researchProfile,

      'image_url'                     : imageURL,
      'web_url'                       : webURL,
      'current_member'                : currentMember?.toJson(),
      'tags'                          : tags,
      'membership_questions'          : GroupMembershipQuestion.listToStringList(questions),
      'membership_quest'              : membershipQuest?.toJson(),
      'settings'                                : settings?.toJson()
    };
  }

  @override
  bool operator ==(dynamic other) =>
    (other is Group) &&
      (other.id == id) &&
      (const DeepCollectionEquality().equals(other.attributes, attributes)) &&
      (other.type == type) &&
      (other.title == title) &&
      (other.description == description) &&
      (other.privacy == privacy) &&

      (other.dateCreatedUtc == dateCreatedUtc) &&
      (other.dateUpdatedUtc == dateUpdatedUtc) &&
      (other.dateManagedMembershipUpdatedUtc == dateManagedMembershipUpdatedUtc) &&
      (other.dateMembershipUpdatedUtc == dateMembershipUpdatedUtc) &&

      (other.certified == certified) &&
      (other.hiddenForSearch == hiddenForSearch) &&
      (other.canJoinAutomatically == canJoinAutomatically) &&
      (other.onlyAdminsCanCreatePolls == onlyAdminsCanCreatePolls) &&
      
      (other.authManEnabled == authManEnabled) &&
      (other.authManGroupName == authManGroupName) &&

      (other.attendanceGroup == attendanceGroup) &&

      (other.researchProject == researchProject) &&
      (other.researchOpen == researchOpen) &&
      (other.researchConsentDetails == researchConsentDetails) &&
      (other.researchConsentStatement == researchConsentStatement) &&
      (const DeepCollectionEquality().equals(other.researchProfile, researchProfile)) &&

      (other.imageURL == imageURL) &&
      (other.webURL == webURL) &&
      (other.currentMember == currentMember) &&
      (const DeepCollectionEquality().equals(other.tags, tags)) &&
      (const DeepCollectionEquality().equals(other.questions, questions)) &&
      (other.membershipQuest == membershipQuest) &&
      (other.settings == settings);


  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(attributes)) ^
    (type?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (privacy?.hashCode ?? 0) ^

    (dateCreatedUtc?.hashCode ?? 0) ^
    (dateUpdatedUtc?.hashCode ?? 0) ^
    (dateManagedMembershipUpdatedUtc?.hashCode ?? 0) ^
    (dateMembershipUpdatedUtc?.hashCode ?? 0) ^

    (certified?.hashCode ?? 0) ^
    (hiddenForSearch?.hashCode ?? 0) ^
    (onlyAdminsCanCreatePolls?.hashCode ?? 0) ^
    (canJoinAutomatically?.hashCode ?? 0) ^

    (authManEnabled?.hashCode ?? 0) ^
    (authManGroupName?.hashCode ?? 0) ^

    (attendanceGroup?.hashCode ?? 0) ^

    (researchProject?.hashCode ?? 0) ^
    (researchOpen?.hashCode ?? 0) ^
    (researchConsentDetails?.hashCode ?? 0) ^
    (researchConsentStatement?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(researchProfile)) ^

    (imageURL?.hashCode ?? 0) ^
    (webURL?.hashCode ?? 0) ^
    (currentMember?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(tags)) ^
    (const DeepCollectionEquality().hash(questions)) ^
    (membershipQuest?.hashCode ?? 0)^
    (settings?.hashCode ?? 0);

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

  static List<Group>? listFromJson(List<dynamic>? json, {bool Function(Group element)? filter}) {
    List<Group>? values;
    if (json != null) {
      values = <Group>[];
      for (dynamic entry in json) {
        Group? group = Group.fromJson(JsonUtils.mapValue(entry));
        if ((group != null) && ((filter == null) || filter(group))) {
          values.add(group);
        }
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
  String?            netId;
	String?            name;
	String?            email;
  GroupMemberStatus? status;
  String?            officerTitle;

  List<GroupMembershipAnswer>?    answers;
  MemberNotificationsPreferences? notificationsPreferences;

  DateTime?          dateAttendedUtc;
  DateTime?          dateCreatedUtc;
  DateTime?          dateUpdatedUtc;

  Member({
    this.id, this.userId, this.externalId, this.name, this.email, this.status, this.officerTitle,
    this.dateAttendedUtc, this.dateCreatedUtc, this.dateUpdatedUtc,
    this.answers, this.notificationsPreferences, this.netId
  });

  static Member? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Member(
      id          : JsonUtils.stringValue(json['id']),
      userId      : JsonUtils.stringValue(json['user_id']),
      externalId  : JsonUtils.stringValue(json['external_id']),
      netId  : JsonUtils.stringValue(json['net_id']),
      name        : JsonUtils.stringValue(json['name']),
      email       : JsonUtils.stringValue(json['email']),
      status      : groupMemberStatusFromString(JsonUtils.stringValue(json['status'])),
      officerTitle : JsonUtils.stringValue(json['officerTitle']),
      
      answers                  : GroupMembershipAnswer.listFromJson(JsonUtils.listValue(json['member_answers'])),
      notificationsPreferences : MemberNotificationsPreferences.fromJson(JsonUtils.mapValue(json['notifications_preferences'])),

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
      netId             : other.netId,
      name            : other.name,
      status          : other.status,
      officerTitle    : other.officerTitle,

      answers                  : GroupMembershipAnswer.listFromOther(other.answers),
      notificationsPreferences : other.notificationsPreferences,

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
    json['net_id']                = netId;
    json['name']                = name;
    json['email']               = email;
    json['status']              = groupMemberStatusToString(status);
    json['officerTitle']        = officerTitle;

    json['answers']                   = GroupMembershipAnswer.listToJson(answers);
    json['notifications_preferences'] = notificationsPreferences?.toJson();

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
      (other.netId == netId) &&
      (other.name == name) &&
      (other.email == email) &&
      (other.status == status) &&
      (other.officerTitle == officerTitle) &&
      (other.notificationsPreferences == notificationsPreferences) &&
      (other.dateAttendedUtc == dateAttendedUtc) &&
      (other.dateCreatedUtc == dateCreatedUtc) &&
      (other.dateUpdatedUtc == dateUpdatedUtc) &&
      const DeepCollectionEquality().equals(other.answers, answers);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (userId?.hashCode ?? 0) ^
    (externalId?.hashCode ?? 0) ^
    (netId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (email?.hashCode ?? 0) ^
    (status?.hashCode ?? 0) ^
    (officerTitle?.hashCode ?? 0) ^
    (notificationsPreferences?.hashCode ?? 0) ^
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
// MemberNotificationsPreferences

class MemberNotificationsPreferences {
  bool? overridePreferences;
  bool? muteAll;
  bool? muteInvitations;
  bool? mutePosts;
  bool? muteEvents;
  bool? mutePolls;

  MemberNotificationsPreferences({this.overridePreferences, this.muteAll, this.muteInvitations, this.mutePosts, this.muteEvents, 
    this.mutePolls});

  static MemberNotificationsPreferences? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return MemberNotificationsPreferences(
        overridePreferences: JsonUtils.boolValue(json['override_preferences']),
        muteAll: JsonUtils.boolValue(json['all_mute']),
        muteInvitations: JsonUtils.boolValue(json['invitations_mute']),
        mutePosts: JsonUtils.boolValue(json['posts_mute']),
        muteEvents: JsonUtils.boolValue(json['events_mute']),
        mutePolls: JsonUtils.boolValue(json['polls_mute']));
  }

  Map<String, dynamic> toJson() {
    return {
      'override_preferences': overridePreferences,
      'all_mute': muteAll,
      'invitations_mute': muteInvitations,
      'posts_mute': mutePosts,
      'events_mute': muteEvents,
      'polls_mute': mutePolls
    };
  }

  @override
  bool operator ==(other) =>
      (other is MemberNotificationsPreferences) &&
      (other.overridePreferences == overridePreferences) &&
      (other.muteAll == muteAll) &&
      (other.muteInvitations == muteInvitations) &&
      (other.mutePosts == mutePosts) &&
      (other.muteEvents == muteEvents) &&
      (other.mutePolls == mutePolls);

  @override
  int get hashCode =>
      (overridePreferences?.hashCode ?? 0) ^
      (muteAll?.hashCode ?? 0) ^
      (muteInvitations?.hashCode ?? 0) ^
      (mutePosts?.hashCode ?? 0) ^
      (muteEvents?.hashCode ?? 0) ^
      (mutePolls?.hashCode ?? 0);
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

//////////////////////////////
//Group Settings

class GroupSettings { //TBD move the rest setting in this section
  MemberInfoPreferences? memberInfoPreferences;
  MemberPostPreferences? memberPostPreferences;

  GroupSettings({this.memberInfoPreferences, this.memberPostPreferences});

  static GroupSettings? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return GroupSettings(
      memberInfoPreferences: MemberInfoPreferences.fromJson(JsonUtils.mapValue(json['member_info_preferences'])),
      memberPostPreferences: MemberPostPreferences.fromJson(JsonUtils.mapValue(json['post_preferences'])),
    );
  }

  static GroupSettings? fromOther(GroupSettings? other) {
    return (other != null) ? GroupSettings(
      memberInfoPreferences: MemberInfoPreferences.fromOther(other.memberInfoPreferences),
      memberPostPreferences: MemberPostPreferences.fromOther(other.memberPostPreferences)
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      "member_info_preferences": memberInfoPreferences?.toJson(),
      "post_preferences": memberPostPreferences?.toJson(),
    };
  }

  @override
  bool operator ==(other) =>
      (other is GroupSettings) &&
          (other.memberInfoPreferences == memberInfoPreferences) &&
          (other.memberPostPreferences == memberPostPreferences);


  @override
  int get hashCode =>
      (memberInfoPreferences?.hashCode ?? 0) ^
      (memberPostPreferences?.hashCode ?? 0);
}

/////////////////////////////
//Group Settings - Member Info Preferences

class MemberInfoPreferences {
  bool? allowMemberInfo;
  bool? viewMemberNetId;
  bool? viewMemberName;
  bool? viewMemberEmail;
  bool? viewMemberPhone;

  MemberInfoPreferences({this.allowMemberInfo, this.viewMemberNetId, this.viewMemberName, this.viewMemberEmail, this.viewMemberPhone});

  static MemberInfoPreferences? fromJson(Map<String, dynamic>? json) {
    if(json == null){
      return null;
    }

    return MemberInfoPreferences(
       allowMemberInfo : JsonUtils.boolValue(json[ 'allow_member_info']),
       viewMemberNetId : JsonUtils.boolValue(json[ 'can_view_member_net_id']),
       viewMemberName : JsonUtils.boolValue(json['can_view_member_name']),
       viewMemberEmail : JsonUtils.boolValue(json[ 'can_view_member_email']),
       viewMemberPhone : JsonUtils.boolValue(json[ 'can_view_member_phone']),
    );
  }

  static MemberInfoPreferences? fromOther(MemberInfoPreferences? other) {
    if(other == null){
      return null;
    }

    return MemberInfoPreferences(
       allowMemberInfo : other.allowMemberInfo,
       viewMemberNetId : other.viewMemberNetId,
       viewMemberName : other.viewMemberName,
       viewMemberEmail : other.viewMemberEmail,
       viewMemberPhone : other.viewMemberPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_member_info'             : allowMemberInfo,
      'can_view_member_net_id'   : viewMemberNetId,
      'can_view_member_name'    : viewMemberName,
      'can_view_member_email'     : viewMemberEmail,
      'can_view_member_phone'    : viewMemberPhone,
    };
  }

  @override
  bool operator ==(other) =>
      (other is MemberInfoPreferences) &&
          (other.allowMemberInfo == allowMemberInfo) &&
          (other.viewMemberNetId == viewMemberNetId) &&
          (other.viewMemberName == viewMemberName) &&
          (other.viewMemberEmail == viewMemberEmail) &&
          (other.viewMemberPhone == viewMemberPhone);


  @override
  int get hashCode =>
      (allowMemberInfo?.hashCode ?? 0) ^
      (viewMemberNetId?.hashCode ?? 0) ^
      (viewMemberName?.hashCode ?? 0) ^
      (viewMemberEmail?.hashCode ?? 0) ^
      (viewMemberPhone?.hashCode ?? 0);
}

/////////////////////////////
//Group Settings - Member Info Preferences

class MemberPostPreferences {
  bool? allowSendPost;
  bool? sendPostToSpecificMembers;
  bool? sendPostToAdmins;
  bool? sendPostToAll;
  bool? sendPostReplies;
  bool? sendPostReactions;

  MemberPostPreferences({this.allowSendPost, this.sendPostToSpecificMembers, this.sendPostToAdmins, this.sendPostToAll, this.sendPostReplies, this.sendPostReactions});

  static MemberPostPreferences? fromJson(Map<String, dynamic>? json) {
    if(json == null){
      return null;
    }

    return MemberPostPreferences(
        allowSendPost : JsonUtils.boolValue(json['allow_send_post']),
        sendPostToSpecificMembers : JsonUtils.boolValue(json['can_send_post_to_specific_members']),
        sendPostToAdmins : JsonUtils.boolValue(json['can_send_post_to_admins']),
        sendPostToAll : JsonUtils.boolValue(json['can_send_post_to_all']),
        sendPostReplies : JsonUtils.boolValue(json['can_send_post_replies']),
        sendPostReactions : JsonUtils.boolValue(json['can_send_post_reactions']));
  }

  static MemberPostPreferences? fromOther(MemberPostPreferences? other) {
    if(other == null){
      return null;
    }

    return MemberPostPreferences(
        allowSendPost : other.allowSendPost,
        sendPostToSpecificMembers : other.sendPostToSpecificMembers,
        sendPostToAdmins : other.sendPostToAdmins,
        sendPostToAll : other.sendPostToAll,
        sendPostReplies : other.sendPostReplies,
        sendPostReactions : other.sendPostReactions);
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_send_post' : allowSendPost ,
      'can_send_post_to_specific_members' : sendPostToSpecificMembers,
      'can_send_post_to_admins' : sendPostToAdmins,
      'can_send_post_to_all' : sendPostToAll,
      'can_send_post_replies' : sendPostReplies,
      'can_send_post_reactions' : sendPostReactions
    };
  }

  @override
  bool operator ==(other) =>
      (other is MemberPostPreferences) &&
          (other.allowSendPost == allowSendPost) &&
          (other.sendPostToSpecificMembers == sendPostToSpecificMembers) &&
          (other.sendPostToAdmins == sendPostToAdmins) &&
          (other.sendPostToAll == sendPostToAll) &&
          (other.sendPostReplies == sendPostReplies) &&
          (other.sendPostReactions == sendPostReactions);


  @override
  int get hashCode =>
      (allowSendPost?.hashCode ?? 0) ^
      (sendPostToSpecificMembers?.hashCode ?? 0) ^
      (sendPostToAdmins?.hashCode ?? 0) ^
      (sendPostToAll?.hashCode ?? 0) ^
      (sendPostReplies?.hashCode ?? 0) ^
      (sendPostReactions?.hashCode ?? 0);
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

