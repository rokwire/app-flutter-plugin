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
import 'package:rokwire_plugin/utils/utils.dart';

class SocialPost {
  static String _dateFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  final String? id;
  final PostStatus? status;

  final SocialAuthorizationContext? authorizationContext;
  final SocialContext? context;

  final String? body;
  final String? subject;
  final String? imageUrl;

  final List<PostNotification>? notifications;

  final DateTime? dateActivatedUtc;
  final DateTime? dateCreatedUtc;
  final DateTime? dateUpdatedUtc;

  SocialPost(
      {this.id,
      this.status,
      this.authorizationContext,
      this.context,
      this.body,
      this.subject,
      this.imageUrl,
      this.notifications,
      this.dateActivatedUtc,
      this.dateCreatedUtc,
      this.dateUpdatedUtc});

  static SocialPost? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return SocialPost(
      id: JsonUtils.stringValue(json['id']),
      status: postStatusFromString(JsonUtils.stringValue(json['status'])),
      authorizationContext: SocialAuthorizationContext.fromJson(JsonUtils.mapValue(json['authorization_context'])),
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
      (other is SocialPost) &&
      (other.id == id) &&
      (other.status == status) &&
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
      (authorizationContext?.hashCode ?? 0) ^
      (context?.hashCode ?? 0) ^
      (body?.hashCode ?? 0) ^
      (subject?.hashCode ?? 0) ^
      (imageUrl?.hashCode ?? 0) ^
      (const DeepCollectionEquality().hash(notifications)) ^
      (dateActivatedUtc?.hashCode ?? 0) ^
      (dateCreatedUtc?.hashCode ?? 0) ^
      (dateUpdatedUtc?.hashCode ?? 0);

  static List<SocialPost>? listFromJson(List<dynamic>? jsonList) {
    List<SocialPost>? items;
    if (jsonList != null) {
      items = <SocialPost>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, SocialPost.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<SocialPost>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (SocialPost? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }
}

class SocialAuthorizationContext {
  SocialAuthorizationContextStatus? status;
  List<SocialContextItem>? items;

  SocialAuthorizationContext({this.status, this.items});

  static SocialAuthorizationContext? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SocialAuthorizationContext(
        status: socialAuthorizationContextStatusFromString(JsonUtils.stringValue(json['authorization_status'])),
        items: SocialContextItem.listFromJson(JsonUtils.listValue(json['items'])));
  }

  factory SocialAuthorizationContext.none() => SocialAuthorizationContext(status: SocialAuthorizationContextStatus.none);

  factory SocialAuthorizationContext.group({List<String>? groupIds}) {
    List<SocialContextItem>? items;
    if (groupIds != null) {
      items = <SocialContextItem>[];
      for (String groupId in groupIds) {
        items.add(SocialContextItem(name: SocialContextItemName.groups_bb_group, identifier: groupId));
      }
    }
    return SocialAuthorizationContext(status: SocialAuthorizationContextStatus.active, items: items);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'authorization_status', value: socialAuthorizationContextStatusToString(status));
    JsonUtils.addNonNullValue(json: json, key: 'items', value: SocialContextItem.listToJson(items));
    return json;
  }

  bool get isPublic => ((status == null) || status == SocialAuthorizationContextStatus.none);

  bool get isGroupMembersOnly => ((status == SocialAuthorizationContextStatus.active) &&
      CollectionUtils.isNotEmpty(items) &&
      (items!.firstWhereOrNull((item) => (item.name == SocialContextItemName.groups_bb_group)) != null));

  @override
  bool operator ==(other) =>
      (other is SocialAuthorizationContext) && (other.status == status) && const DeepCollectionEquality().equals(other.items, items);

  @override
  int get hashCode => (status?.hashCode ?? 0) ^ (const DeepCollectionEquality().hash(items));
}

class SocialContext {
  List<SocialContextItem>? items;

  SocialContext({this.items});

  static SocialContext? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SocialContext(items: SocialContextItem.listFromJson(JsonUtils.listValue(json['items'])));
  }

  factory SocialContext.fromIdentifiers({List<String>? identifiers}) {
    List<SocialContextItem>? items;
    if (identifiers != null) {
      items = <SocialContextItem>[];
      for (String identifier in identifiers) {
        items.add(SocialContextItem(name: SocialContextItemName.groups_bb_group, identifier: identifier));
      }
    }
    return SocialContext(items: items);
  }

  Map<String, dynamic> toJson() => {'items': SocialContextItem.listToJson(items)};

  bool get isGroupPost =>
      (CollectionUtils.isNotEmpty(items) && (items!.firstWhereOrNull((item) => (item.name == SocialContextItemName.groups_bb_group)) != null));

  Set<String>? get groupIds {
    Set<String>? groupIds;
    if (isGroupPost) {
      groupIds = <String>{};
      for (SocialContextItem item in items!) {
        if ((item.name == SocialContextItemName.groups_bb_group) && StringUtils.isNotEmpty(item.identifier)) {
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

class SocialContextItem {
  final SocialContextItemName? name;
  final SocialContextItemMembers? members;
  final String? identifier;

  SocialContextItem({this.name, this.members, this.identifier});

  static SocialContextItem? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SocialContextItem(
        name: socialContextItemNameFromString(JsonUtils.stringValue(json['name'])),
        members: SocialContextItemMembers.fromJson(JsonUtils.mapValue(json['members'])),
        identifier: JsonUtils.stringValue(json['identifier']));
  }

  Map<String, dynamic> toJson() =>
      {'name': socialContextItemNameToString(name), 'members': members?.toJson(), 'identifier': StringUtils.ensureNotEmpty(identifier)};

  @override
  bool operator ==(other) =>
      (other is SocialContextItem) && (other.name == name) && (other.members == members) && (other.identifier == identifier);

  @override
  int get hashCode => (name?.hashCode ?? 0) ^ (members?.hashCode ?? 0) ^ (identifier?.hashCode ?? 0);

  static List<SocialContextItem>? listFromJson(List<dynamic>? jsonList) {
    List<SocialContextItem>? result;
    if (jsonList != null) {
      result = <SocialContextItem>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, SocialContextItem.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<SocialContextItem>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (SocialContextItem contentEntry in contentList) {
        ListUtils.add(jsonList, contentEntry.toJson());
      }
    }
    return jsonList;
  }
}

class SocialContextItemMembers {
  SocialContextItemMembersType? type;
  List<String>? members;

  SocialContextItemMembers({this.type, this.members});

  static SocialContextItemMembers? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SocialContextItemMembers(
        type: socialContextItemMembersTypeFromString(JsonUtils.stringValue(json['type'])),
        members: JsonUtils.stringListValue(json['members']));
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    JsonUtils.addNonNullValue(json: json, key: 'type', value: socialContextItemMembersTypeToString(type));
    JsonUtils.addNonNullValue(json: json, key: 'members', value: members);
    return json;
  }

  @override
  bool operator ==(other) =>
      (other is SocialContextItemMembers) && (other.type == type) && const DeepCollectionEquality().equals(other.members, members);

  @override
  int get hashCode => (type?.hashCode ?? 0) ^ (const DeepCollectionEquality().hash(members));
}

enum SocialContextItemMembersType { all, listed_accounts }

SocialContextItemMembersType? socialContextItemMembersTypeFromString(String? value) {
  switch (value) {
    case 'all':
      return SocialContextItemMembersType.all;
    case 'listed-accounts':
      return SocialContextItemMembersType.listed_accounts;
    default:
      return null;
  }
}

String? socialContextItemMembersTypeToString(SocialContextItemMembersType? type) {
  switch (type) {
    case SocialContextItemMembersType.all:
      return 'all';
    case SocialContextItemMembersType.listed_accounts:
      return 'listed-accounts';
    default:
      return null;
  }
}

enum SocialAuthorizationContextStatus { active, none }

SocialAuthorizationContextStatus? socialAuthorizationContextStatusFromString(String? value) {
  switch (value) {
    case 'NONE':
      return SocialAuthorizationContextStatus.none;
    case 'ACTIVE':
      return SocialAuthorizationContextStatus.active;
    default:
      return null;
  }
}

String? socialAuthorizationContextStatusToString(SocialAuthorizationContextStatus? value) {
  switch (value) {
    case SocialAuthorizationContextStatus.none:
      return 'NONE';
    case SocialAuthorizationContextStatus.active:
      return 'ACTIVE';
    default:
      return null;
  }
}

enum SocialContextItemName { groups_bb_group }

SocialContextItemName? socialContextItemNameFromString(String? value) {
  switch (value) {
    case 'groups-bb_group':
      return SocialContextItemName.groups_bb_group;
    default:
      return null;
  }
}

String? socialContextItemNameToString(SocialContextItemName? value) {
  switch (value) {
    case SocialContextItemName.groups_bb_group:
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
