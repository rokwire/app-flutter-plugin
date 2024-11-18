/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Post {
  static String _dateFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  final String? id;
  final PostStatus? status;
  final PostReportStatus? reportStatus;

  final AuthorizationContext? authorizationContext;
  final SocialContext? context;

  final String? body;
  final String? subject;
  final String? imageUrl;

  final List<PostNotification>? notifications;

  final DateTime? dateActivatedUtc;
  final DateTime? dateCreatedUtc;
  final DateTime? dateUpdatedUtc;

  Post(
      {this.id,
      this.status,
      this.reportStatus,
      this.authorizationContext,
      this.context,
      this.body,
      this.subject,
      this.imageUrl,
      this.notifications,
      this.dateActivatedUtc,
      this.dateCreatedUtc,
      this.dateUpdatedUtc});

  static Post? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return Post(
      id: JsonUtils.stringValue(json['id']),
      status: postStatusFromString(JsonUtils.stringValue(json['status'])),
      reportStatus: postReportStatusFromString(JsonUtils.stringValue(json['report_status'])),
      authorizationContext: AuthorizationContext.fromJson(JsonUtils.mapValue(json['authorization_context'])),
      context: SocialContext.fromJson(JsonUtils.mapValue(json['context'])),
      body: JsonUtils.stringValue(json['body']),
      subject: JsonUtils.stringValue(json['subject']),
      imageUrl: JsonUtils.stringValue(json['image_url']),
      notifications: PostNotification.listFromJson(JsonUtils.listValue(json['notifications'])),
      dateActivatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['activation_date']), format: _dateFormat, isUtc: true),
      dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), format: _dateFormat, isUtc: true),
      dateUpdatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_updated']), format: _dateFormat, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization_context': authorizationContext?.toJson(),
      'context': context?.toJson(),
      'body': body,
      'subject': subject,
      'image_url': imageUrl,
      'notifications': PostNotification.listToJson(notifications),
      'activation_date': DateTimeUtils.utcDateTimeToString(dateActivatedUtc),
    };
  }

  @override
  bool operator ==(other) =>
      (other is Post) &&
      (other.id == id) &&
      (other.status == status) &&
      (other.reportStatus == reportStatus) &&
      (other.authorizationContext == authorizationContext) &&
      (other.context == context) &&
      (other.body == body) &&
      (other.subject == subject) &&
      (other.imageUrl == imageUrl) &&
      const DeepCollectionEquality().equals(other.notifications, notifications) &&
      (other.dateActivatedUtc == dateActivatedUtc) &&
      (other.dateCreatedUtc == dateCreatedUtc) &&
      (other.dateUpdatedUtc == dateUpdatedUtc);

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (status?.hashCode ?? 0) ^
      (reportStatus?.hashCode ?? 0) ^
      (authorizationContext?.hashCode ?? 0) ^
      (context?.hashCode ?? 0) ^
      (body?.hashCode ?? 0) ^
      (subject?.hashCode ?? 0) ^
      (imageUrl?.hashCode ?? 0) ^
      (const DeepCollectionEquality().hash(notifications)) ^
      (dateActivatedUtc?.hashCode ?? 0) ^
      (dateCreatedUtc?.hashCode ?? 0) ^
      (dateUpdatedUtc?.hashCode ?? 0);

  static List<Post>? listFromJson(List<dynamic>? jsonList) {
    List<Post>? items;
    if (jsonList != null) {
      items = <Post>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Post.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<Post>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Post? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }

  bool get isUpdated => (dateUpdatedUtc != null) && (dateCreatedUtc != dateUpdatedUtc);
}

class AuthorizationContext {
  AuthorizationContextStatus? status;
  List<ContextItem>? items;

  AuthorizationContext({this.status, this.items});

  static AuthorizationContext? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AuthorizationContext(
        status: authorizationContextStatusFromString(JsonUtils.stringValue(json['authorization_status'])),
        items: ContextItem.listFromJson(JsonUtils.listValue(json['items'])));
  }

  static AuthorizationContext fromPostType({PostType? type, List<String>? groupIds}) {
    List<ContextItem>? items;
    if (groupIds != null) {
      items = <ContextItem>[];
      String? memberAccountId = Auth2().accountId;
      List<String>? membersAccountIds = (memberAccountId != null) ? [memberAccountId] : null;
      for (String groupId in groupIds) {
        ContextItemMembersType? membersType = _getMemberTypeBy(type: type);
        ContextItemMembers members = ContextItemMembers(type: membersType, members: membersAccountIds);
        items.add(ContextItem(name: ContextItemName.groups_bb_group, identifier: groupId, members: members));
      }
    }
    AuthorizationContextStatus status = _getAuthStatusBy(type: type);
    return AuthorizationContext(status: status, items: items);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'authorization_status', value: authorizationContextStatusToString(status));
    JsonUtils.addNonNullValue(json: json, key: 'items', value: ContextItem.listToJson(items));
    return json;
  }

  @override
  bool operator ==(other) =>
      (other is AuthorizationContext) && (other.status == status) && const DeepCollectionEquality().equals(other.items, items);

  @override
  int get hashCode => (status?.hashCode ?? 0) ^ (const DeepCollectionEquality().hash(items));

  static ContextItemMembersType? _getMemberTypeBy({PostType? type}) {
    switch (type) {
      case PostType.post:
        return ContextItemMembersType.all;
      case PostType.direct_message:
        return ContextItemMembersType.listed_accounts;
      default:
        return null;
    }
  }

  static AuthorizationContextStatus _getAuthStatusBy({PostType? type}) {
    // All post auth statuses are "active" for now because they are part of a group
    switch (type) {
      case PostType.post:
        return AuthorizationContextStatus.active;
      case PostType.direct_message:
        return AuthorizationContextStatus.active;
      default:
        return AuthorizationContextStatus.active;
    }
  }
}

enum PostType { post, direct_message }

class SocialContext {
  List<ContextItem>? items;

  SocialContext({this.items});

  static SocialContext? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SocialContext(items: ContextItem.listFromJson(JsonUtils.listValue(json['items'])));
  }

  static SocialContext? fromIdentifier(String? identifier) => (identifier != null) ? SocialContext.fromIdentifiers([identifier]) : null;

  static SocialContext? fromIdentifiers(List<String>? identifiers) {
    if (CollectionUtils.isEmpty(identifiers)) {
      return null;
    }
    List<ContextItem>? items = <ContextItem>[];
    for (String identifier in identifiers!) {
      items.add(ContextItem(name: ContextItemName.groups_bb_group, identifier: identifier));
    }
    return SocialContext(items: items);
  }

  Map<String, dynamic> toJson() => {'items': ContextItem.listToJson(items)};

  bool get isGroupPost =>
      (CollectionUtils.isNotEmpty(items) && (items!.firstWhereOrNull((item) => (item.name == ContextItemName.groups_bb_group)) != null));

  Set<String>? get groupIds {
    Set<String>? groupIds;
    if (isGroupPost) {
      groupIds = <String>{};
      for (ContextItem item in items!) {
        if ((item.name == ContextItemName.groups_bb_group) && StringUtils.isNotEmpty(item.identifier)) {
          groupIds.add(item.identifier!);
        }
      }
    }
    return groupIds;
  }

  @override
  bool operator ==(other) => (other is SocialContext) && const DeepCollectionEquality().equals(other.items, items);

  @override
  int get hashCode => (const DeepCollectionEquality().hash(items));
}

class ContextItem {
  final ContextItemName? name;
  final ContextItemMembers? members;
  final String? identifier;

  ContextItem({this.name, this.members, this.identifier});

  static ContextItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ContextItem(
        name: contextItemNameFromString(JsonUtils.stringValue(json['name'])),
        members: ContextItemMembers.fromJson(JsonUtils.mapValue(json['members'])),
        identifier: JsonUtils.stringValue(json['identifier']));
  }

  Map<String, dynamic> toJson() =>
      {'name': contextItemNameToString(name), 'members': members?.toJson(), 'identifier': StringUtils.ensureNotEmpty(identifier)};

  @override
  bool operator ==(other) =>
      (other is ContextItem) && (other.name == name) && (other.members == members) && (other.identifier == identifier);

  @override
  int get hashCode => (name?.hashCode ?? 0) ^ (members?.hashCode ?? 0) ^ (identifier?.hashCode ?? 0);

  static List<ContextItem>? listFromJson(List<dynamic>? jsonList) {
    List<ContextItem>? result;
    if (jsonList != null) {
      result = <ContextItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, ContextItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<ContextItem>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (ContextItem contentEntry in contentList) {
        ListUtils.add(jsonList, contentEntry.toJson());
      }
    }
    return jsonList;
  }
}

class ContextItemMembers {
  ContextItemMembersType? type;
  List<String>? members;

  ContextItemMembers({this.type, this.members});

  static ContextItemMembers? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ContextItemMembers(
        type: contextItemMembersTypeFromString(JsonUtils.stringValue(json['type'])),
        members: JsonUtils.stringListValue(json['members']));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'type', value: contextItemMembersTypeToString(type));
    JsonUtils.addNonNullValue(json: json, key: 'members', value: members);
    return json;
  }

  @override
  bool operator ==(other) =>
      (other is ContextItemMembers) && (other.type == type) && const DeepCollectionEquality().equals(other.members, members);

  @override
  int get hashCode => (type?.hashCode ?? 0) ^ (const DeepCollectionEquality().hash(members));
}

enum ContextItemMembersType { all, listed_accounts }

ContextItemMembersType? contextItemMembersTypeFromString(String? value) {
  switch (value) {
    case 'all':
      return ContextItemMembersType.all;
    case 'listed-accounts':
      return ContextItemMembersType.listed_accounts;
    default:
      return null;
  }
}

String? contextItemMembersTypeToString(ContextItemMembersType? type) {
  switch (type) {
    case ContextItemMembersType.all:
      return 'all';
    case ContextItemMembersType.listed_accounts:
      return 'listed-accounts';
    default:
      return null;
  }
}

enum AuthorizationContextStatus { active, none }

AuthorizationContextStatus? authorizationContextStatusFromString(String? value) {
  switch (value) {
    case 'NONE':
      return AuthorizationContextStatus.none;
    case 'ACTIVE':
      return AuthorizationContextStatus.active;
    default:
      return null;
  }
}

String? authorizationContextStatusToString(AuthorizationContextStatus? value) {
  switch (value) {
    case AuthorizationContextStatus.none:
      return 'NONE';
    case AuthorizationContextStatus.active:
      return 'ACTIVE';
    default:
      return null;
  }
}

enum ContextItemName { groups_bb_group }

ContextItemName? contextItemNameFromString(String? value) {
  switch (value) {
    case 'groups-bb_group':
      return ContextItemName.groups_bb_group;
    default:
      return null;
  }
}

String? contextItemNameToString(ContextItemName? value) {
  switch (value) {
    case ContextItemName.groups_bb_group:
      return 'groups-bb_group';
    default:
      return null;
  }
}

class PostNotification {
  final PostNotificationPolicyType? policyType;
  final PostNotificationType? type;
  final bool? usePostData;

  PostNotification({this.policyType, this.type, this.usePostData});

  static PostNotification? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PostNotification(
        policyType: postNotificationPolicyTypeFromString(JsonUtils.stringValue(json['policy_type'])),
        type: postNotificationTypeFromString(JsonUtils.stringValue(json['type'])),
        usePostData: JsonUtils.boolValue(json['use_post_data']));
  }

  Map<String, dynamic> toJson() {
    return {
      'policy_type': postNotificationPolicyTypeToString(policyType),
      'type': postNotificationTypeToString(type),
      'use_post_data': usePostData
    };
  }

  @override
  bool operator ==(other) =>
      (other is PostNotification) && (other.policyType == policyType) && (other.type == type) && (other.usePostData == usePostData);

  @override
  int get hashCode => (policyType?.hashCode ?? 0) ^ (type?.hashCode ?? 0) ^ (usePostData?.hashCode ?? 0);

  static List<PostNotification>? listFromJson(List<dynamic>? jsonList) {
    List<PostNotification>? items;
    if (jsonList != null) {
      items = <PostNotification>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, PostNotification.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<PostNotification>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (PostNotification? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }
}

enum PostNotificationType { post_published }

String? postNotificationTypeToString(PostNotificationType? type) {
  switch (type) {
    case PostNotificationType.post_published:
      return 'post-published';
    default:
      return null;
  }
}

PostNotificationType? postNotificationTypeFromString(String? value) {
  switch (value) {
    case 'post-published':
      return PostNotificationType.post_published;
    default:
      return null;
  }
}

enum PostNotificationPolicyType { all }

String? postNotificationPolicyTypeToString(PostNotificationPolicyType? policyType) {
  switch (policyType) {
    case PostNotificationPolicyType.all:
      return 'all';
    default:
      return null;
  }
}

PostNotificationPolicyType? postNotificationPolicyTypeFromString(String? value) {
  switch (value) {
    case 'all':
      return PostNotificationPolicyType.all;
    default:
      return null;
  }
}

enum PostStatus { draft, active, reported_as_abuse, confirmed_as_abuse }

String? postStatusToString(PostStatus? status) {
  switch (status) {
    case PostStatus.active:
      return 'active';
    case PostStatus.draft:
      return 'draft';
    case PostStatus.reported_as_abuse:
      return 'reported-as-abuse';
    case PostStatus.confirmed_as_abuse:
      return 'confirmed-as-abuse';
    default:
      return null;
  }
}

PostStatus? postStatusFromString(String? value) {
  switch (value) {
    case 'active':
      return PostStatus.active;
    case 'draft':
      return PostStatus.draft;
    case 'reported-as-abuse':
      return PostStatus.reported_as_abuse;
    case 'confirmed-as-abuse':
      return PostStatus.confirmed_as_abuse;
    default:
      return null;
  }
}

enum PostReportStatus { reported_as_abuse, confirmed_as_abuse }

String? postReportStatusToString(PostReportStatus? status) {
  switch (status) {
    case PostReportStatus.reported_as_abuse:
      return 'reported-as-abuse';
    case PostReportStatus.confirmed_as_abuse:
      return 'confirmed-as-abuse';
    default:
      return null;
  }
}

PostReportStatus? postReportStatusFromString(String? value) {
  switch (value) {
    case 'reported-as-abuse':
      return PostReportStatus.reported_as_abuse;
    case 'confirmed-as-abuse':
      return PostReportStatus.confirmed_as_abuse;
    default:
      return null;
  }
}
