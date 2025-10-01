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

class Post {
  final String? id;
  final PostStatus? status;
  final PostReportStatus? reportStatus;

  final AuthorizationContext? authorizationContext;
  final SocialContext? context;

  String? body;
  String? subject;
  String? imageUrl;

  final Creator? creator;

  final PostNotification? notification;
  final List<PostNotification>? notifications;

  final PostDetails? details;

  final bool? pinned;

  DateTime? dateActivatedUtc;
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
      this.creator,
      this.notification,
      this.notifications,
      this.details,
      this.pinned,
      this.dateActivatedUtc,
      this.dateCreatedUtc,
      this.dateUpdatedUtc});

  static Post? fromJson(Map<String, dynamic>? json, {PostDetails? details}) {
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
      creator: Creator.fromJson(JsonUtils.mapValue(json['created_by'])),
      notification: PostNotification.fromJson(JsonUtils.mapValue(json['notification'])),
      notifications: PostNotification.listFromJson(JsonUtils.listValue(json['notifications'])),
      details: details,
      pinned: JsonUtils.boolValue(json['pinned']),
      dateActivatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['activation_date']), isUtc: true),
      dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), isUtc: true),
      dateUpdatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_updated']), isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization_context': authorizationContext?.toJson(),
      'context': context?.toJson(),
      'body': body,
      'subject': subject,
      'image_url': imageUrl,
      'notification': notification?.toJson(),
      'pinned': pinned,
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
      (other.creator == creator) &&
      (other.notification == notification) &&
      const DeepCollectionEquality().equals(other.notifications, notifications) &&
      (other.details == details) &&
      (other.pinned == pinned) &&
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
      (creator?.hashCode ?? 0) ^
      (notification?.hashCode ?? 0) ^
      (const DeepCollectionEquality().hash(notifications)) ^
      (details?.hashCode ?? 0) ^
      (pinned?.hashCode ?? 0) ^
      (dateActivatedUtc?.hashCode ?? 0) ^
      (dateCreatedUtc?.hashCode ?? 0) ^
      (dateUpdatedUtc?.hashCode ?? 0);

  static List<Post>? listFrom({List<dynamic>? json, List<PostDetails>? detailsList}) {
    List<Post>? items;
    if (json != null) {
      items = <Post>[];
      for (dynamic jsonEntry in json) {
        String? id = JsonUtils.stringValue(jsonEntry['id']);
        PostDetails? details = PostDetails.findInList(detailsList, postId: id);
        ListUtils.add(items, Post.fromJson(jsonEntry, details: details));
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

  factory Post.forGroup(
      {required String groupId,
      String? subject,
      String? body,
      List<String>? memberAccountIds,
      String? imageUrl,
      DateTime? dateActivatedUtc}) {
    SocialContext context = SocialContext.forGroup(groupId: groupId);
    AuthorizationContext? authContext = AuthorizationContext.forGroups(groupIds: [groupId], memberAccountIds: memberAccountIds);
    return Post(
        subject: subject,
        body: body,
        imageUrl: imageUrl,
        dateActivatedUtc: dateActivatedUtc,
        notification: PostNotification.simple(),
        context: context,
        authorizationContext: authContext);
  }

  factory Post.forGroups(
      {required List<String> groupIds, String? subject, String? body, String? imageUrl, DateTime? dateActivatedUtc}) {
    SocialContext context = SocialContext.forGroups(groupIds: groupIds);
    AuthorizationContext authContext = AuthorizationContext.forGroups(groupIds: groupIds);
    return Post(
        subject: subject,
        body: body,
        imageUrl: imageUrl,
        dateActivatedUtc: dateActivatedUtc,
        notification: PostNotification.simple(),
        context: context,
        authorizationContext: authContext);
  }

  List<String>? getMemberAccountIds({required String groupId}) {
    ContextItem? groupItem = authorizationContext?.getItemFor(name: ContextItemName.groups_bb_group, identifier: groupId);
    return groupItem?.members?.members;
  }

  void setMemberAccountIds({required String groupId, List<String>? accountIds}) {
    ContextItem? groupItem = authorizationContext?.getItemFor(name: ContextItemName.groups_bb_group, identifier: groupId);
    bool hasAccountIds = CollectionUtils.isNotEmpty(accountIds);
    ContextItemMembers itemMembers = ContextItemMembers(
        type: (hasAccountIds ? ContextItemMembersType.listed_accounts : ContextItemMembersType.all), members: accountIds);
    if (groupItem == null) {
      groupItem = ContextItem(name: ContextItemName.groups_bb_group, identifier: groupId, members: itemMembers);
    } else {
      groupItem.members = itemMembers;
    }
  }

  bool get isUpdated => (dateUpdatedUtc != null) && (dateCreatedUtc != dateUpdatedUtc);

  bool get isLinkedToMoreThanOneGroup => ((_groupIds?.length ?? 0) > 1);

  Set<String>? get _groupIds => context?.groupIds;
}

class Creator {
  final String? accountId;
  final String? name;

  Creator({this.accountId, this.name});

  static Creator? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Creator(accountId: JsonUtils.stringValue(json['account_id']), name: JsonUtils.stringValue(json['name']));
  }

  Map<String, dynamic> toJson() => {
    "account_id": accountId,
    "name": name
  };

  @override
  bool operator ==(other) => (other is Creator) && (other.accountId == accountId) && (other.name == name);

  @override
  int get hashCode => (accountId?.hashCode ?? 0) ^ (name?.hashCode ?? 0);
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

  static AuthorizationContext forGroups({List<String>? groupIds, List<String>? memberAccountIds}) {
    List<ContextItem>? items;
    if (groupIds != null) {
      items = <ContextItem>[];
      for (String groupId in groupIds) {
        ContextItemMembersType membersType =
            CollectionUtils.isNotEmpty(memberAccountIds) ? ContextItemMembersType.listed_accounts : ContextItemMembersType.all;
        ContextItemMembers members = ContextItemMembers(type: membersType, members: memberAccountIds);
        items.add(ContextItem(name: ContextItemName.groups_bb_group, identifier: groupId, members: members));
      }
    }
    // All post auth statuses are "active" for now because they are part of a group
    return AuthorizationContext(status: AuthorizationContextStatus.active, items: items);
  }

  static AuthorizationContext forMembersType({required ContextItemMembersType membersType, List<String>? groupIds}) {
    List<ContextItem>? items;
    if (groupIds != null) {
      items = <ContextItem>[];
      for (String groupId in groupIds) {
        ContextItemMembers members = ContextItemMembers(type: membersType);
        items.add(ContextItem(name: ContextItemName.groups_bb_group, identifier: groupId, members: members));
      }
    }
    // All post auth statuses are "active" for now because they are part of a group
    return AuthorizationContext(status: AuthorizationContextStatus.active, items: items);
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

  ContextItem? getItemFor({required ContextItemName name, required String identifier}) {
    if (CollectionUtils.isNotEmpty(items)) {
      for (ContextItem item in items!) {
        if ((item.name == name) && (item.identifier == identifier)) {
          return item;
        }
      }
    }
    return null;
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

  factory SocialContext.forGroup({required String groupId}) => SocialContext.forGroups(groupIds: [groupId]);

  factory SocialContext.forGroups({required List<String> groupIds}) {
    List<ContextItem> items = <ContextItem>[];
    for (String identifier in groupIds) {
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
  ContextItemMembers? members;
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

class PostDetails {
  final String? postId;
  final int? commentsCount;

  PostDetails({this.postId, this.commentsCount});

  static PostDetails? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PostDetails(postId: JsonUtils.stringValue(json['post_id']), commentsCount: JsonUtils.intValue(json['comments_count']));
  }

  @override
  bool operator ==(other) => (other is PostDetails) && (other.postId == postId) && (other.commentsCount == commentsCount);

  @override
  int get hashCode => (postId?.hashCode ?? 0) ^ (commentsCount?.hashCode ?? 0);

  static List<PostDetails>? listFromJson(List<dynamic>? jsonList) {
    List<PostDetails>? items;
    if (jsonList != null) {
      items = <PostDetails>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, PostDetails.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static PostDetails? findInList(List<PostDetails>? values, {String? postId}) {
    if (values != null) {
      for (PostDetails value in values) {
        if ((postId != null) && (value.postId == postId)) {
          return value;
        }
      }
    }
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

  factory PostNotification.simple() =>
      PostNotification(policyType: PostNotificationPolicyType.all, type: PostNotificationType.post_published, usePostData: true);

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

enum PostStatus { draft, active }

String? postStatusToString(PostStatus? status) {
  switch (status) {
    case PostStatus.active:
      return 'active';
    case PostStatus.draft:
      return 'draft';
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

class Comment {
  final String? id;
  final String? parentId;

  String? body;
  String? imageUrl;

  final Creator? creator;
  final DateTime? dateCreatedUtc;
  final DateTime? dateUpdatedUtc;
  final ContextItem? innerContext;

  Comment({this.id, this.parentId, this.body, this.imageUrl, this.creator, this.innerContext, this.dateCreatedUtc, this.dateUpdatedUtc,});

  static Comment? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return Comment(
      id: JsonUtils.stringValue(json['id']),
      parentId: JsonUtils.stringValue(json['parent_id']),
      body: JsonUtils.stringValue(json['body']),
      imageUrl: JsonUtils.stringValue(json['image_url']),
      creator: Creator.fromJson(JsonUtils.mapValue(json['created_by'])),
      innerContext: ContextItem.fromJson(JsonUtils.mapValue(json['inner_context'])),
      dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), isUtc: true),
      dateUpdatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_updated']), isUtc: true),
    );
  }

  //TBD why this don't contain all fields
  Map<String, dynamic> toJson() => {
    'body': body,
    'parent_id': parentId,
    'image_url': imageUrl,
    "inner_context": innerContext?.toJson()
  };

  @override
  bool operator ==(other) =>
      (other is Comment) &&
      (other.id == id) &&
      (other.parentId == parentId) &&
      (other.body == body) &&
      (other.imageUrl == imageUrl) &&
      (other.creator == creator) &&
      (other.innerContext == innerContext) &&
      (other.dateCreatedUtc == dateCreatedUtc) &&
      (other.dateUpdatedUtc == dateUpdatedUtc);

  @override
  int get hashCode =>
      (id?.hashCode ?? 0) ^
      (parentId?.hashCode ?? 0) ^
      (body?.hashCode ?? 0) ^
      (imageUrl?.hashCode ?? 0) ^
      (creator?.hashCode ?? 0) ^
      (innerContext?.hashCode ?? 0) ^
      (dateCreatedUtc?.hashCode ?? 0) ^
      (dateUpdatedUtc?.hashCode ?? 0);

  static List<Comment>? listFromJson(List<dynamic>? jsonList) {
    List<Comment>? items;
    if (jsonList != null) {
      items = <Comment>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Comment.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<Comment>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Comment? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }

  bool get isUpdated => (dateUpdatedUtc != null) && (dateCreatedUtc != dateUpdatedUtc);
}

class Reaction {
  final String? id;
  final ReactionType? type;
  final Map<String, dynamic>? data;
  final Creator? engager;
  final DateTime? dateCreatedUtc;
  final ContextItem? innerContext;

  Reaction({this.id, this.type, this.engager, this.data, this.dateCreatedUtc, this.innerContext});

  factory Reaction.emoji({String?emojiSource, String? emojiName, String? id, Creator? engager, dateCreatedUtc, ContextItem? innerContext}) =>
    Reaction(id: id, engager: engager, dateCreatedUtc: dateCreatedUtc, innerContext: innerContext,
        type: ReactionType.emoji,
        data: {
          "emoji_source": emojiSource,
          "emoji_name": emojiName
        },
    );

  static Reaction? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return Reaction(
        id: JsonUtils.stringValue(json['id']),
        data: JsonUtils.mapValue(json['data']),
        type: reactionTypeFromString(JsonUtils.stringValue(json['type'])),
        engager: Creator.fromJson(JsonUtils.mapValue(json['created_by'])),
        dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), isUtc: true),
        innerContext: ContextItem.fromJson(JsonUtils.mapValue(json['inner_context']))
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "data": data,
    "type": reactionTypeToString(type),
    "created_by": engager?.toJson(),
    "date_created": DateTimeUtils.utcDateTimeToString(dateCreatedUtc),
    "inner_context": innerContext?.toJson()
  };

  @override
  bool operator ==(other) =>
      (other is Reaction) &&
      (other.id == id) &&
      (other.type == type) &&
      (other.engager == engager) &&
      (other.data == data) &&
      (other.data == innerContext) &&
      (other.dateCreatedUtc == dateCreatedUtc);

  @override
  int get hashCode => (id?.hashCode ?? 0) ^ (type?.hashCode ?? 0) ^ (engager?.hashCode ?? 0) ^ (dateCreatedUtc?.hashCode ?? 0) ^ (innerContext?.hashCode ?? 0) ^ (data?.hashCode ?? 0);

  static List<Reaction>? listFromJson(List<dynamic>? jsonList) {
    List<Reaction>? items;
    if (jsonList != null) {
      items = <Reaction>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Reaction.fromJson(jsonEntry));
      }
    }
    return items;
  }
}

class SocialStats {
  final int? posts;
  final int? comments;
  final int? reactions;

  SocialStats({this.posts, this.comments, this.reactions});

  static SocialStats? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return SocialStats(
        posts: JsonUtils.intValue(json['posts_count']),
        comments: JsonUtils.intValue(json['comments_count']),
        reactions: JsonUtils.intValue(json['reactions_count']));
  }

  @override
  bool operator ==(other) =>
      (other is SocialStats) && (other.posts == posts) && (other.comments == comments) && (other.reactions == reactions);

  @override
  int get hashCode => (posts?.hashCode ?? 0) ^ (comments?.hashCode ?? 0) ^ (reactions?.hashCode ?? 0);
}

enum SocialEntityType { post, comment }

String? socialEntityTypeToString(SocialEntityType? type) {
  switch (type) {
    case SocialEntityType.comment:
      return 'comment';
    case SocialEntityType.post:
      return 'post';
    default:
      return null;
  }
}

SocialEntityType? socialEntityTypeFromString(String? value) {
  switch (value) {
    case 'comment':
      return SocialEntityType.comment;
    case 'post':
      return SocialEntityType.post;
    default:
      return null;
  }
}

enum ReactionType { like, emoji }

String? reactionTypeToString(ReactionType? type) {
  switch (type) {
    case ReactionType.like:
      return 'like';
    case ReactionType.emoji:
      return 'emoji';
    default:
      return null;
  }
}

ReactionType? reactionTypeFromString(String? value) {
  switch (value) {
    case 'like':
      return ReactionType.like;
    case 'emoji':
      return ReactionType.emoji;
    default:
      return null;
  }
}

class Message {
  final String? id;
  final String? globalId;
  final String? conversationId;

  final ConversationMember? sender;
  final ConversationMember? recipient;

  final String? message;
  final bool? read;

  final List<FileAttachment>? fileAttachments;

  final DateTime? dateSentUtc;
  final DateTime? dateUpdatedUtc;

  Message({this.id, this.globalId, this.conversationId, this.sender, this.recipient, this.message, this.read, this.fileAttachments, this.dateSentUtc, this.dateUpdatedUtc});

  factory Message.fromOther(Message? other, {
    String? id, String? globalId, String? conversationId,
    ConversationMember? sender, ConversationMember? recipient,
    String? message, bool? read, List<FileAttachment>? fileAttachments,
    DateTime? dateSentUtc,
    DateTime? dateUpdatedUtc
  }) => Message(
    id: id ?? other?.id,
    globalId: globalId ?? other?.globalId,
    conversationId: conversationId ?? other?.conversationId,
    sender: sender ?? other?.sender,
    recipient: recipient ?? other?.recipient,
    message: message ?? other?.message,
    read: read ?? other?.read,
    fileAttachments: fileAttachments ?? other?.fileAttachments,
    dateSentUtc: dateSentUtc ?? other?.dateSentUtc,
    dateUpdatedUtc: dateUpdatedUtc ?? other?.dateUpdatedUtc,
  );

  static Message? fromJson(Map<String, dynamic>? json) => (json != null) ? Message(
    id: JsonUtils.stringValue(json['id']),
    globalId: JsonUtils.stringValue(json['global_id']),
    conversationId: JsonUtils.stringValue(json['conversation_id']),
    sender: ConversationMember.fromJson(JsonUtils.mapValue(json['sender'])),
    recipient: ConversationMember.fromJson(json['recipient']),
    message: JsonUtils.stringValue(json['message']),
    read: JsonUtils.boolValue(json['read']),
    fileAttachments: FileAttachment.listFromJson(json['file_attachments']),
    dateSentUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_sent']), isUtc: true),
    dateUpdatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_updated']), isUtc: true),
  ) : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'global_id': globalId,
      'conversation_id': conversationId,
      'sender': sender?.toJson(),
      'recipient': recipient?.toJson(),
      'message': message,
      'read': read,
      'file_attachments': FileAttachment.listToJson(fileAttachments),
      'date_sent': DateTimeUtils.utcDateTimeToString(dateSentUtc),
      'date_updated': DateTimeUtils.utcDateTimeToString(dateUpdatedUtc),
    };
  }

  static List<Message>? listFromJson(List<dynamic>? jsonList) {
    List<Message>? items;
    if (jsonList != null) {
      items = <Message>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Message.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<Message>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Message? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }

  static void sortListByDateSent(List<Message> messages) {
    DateTime now = DateTime.now();
    messages.sort((Message msg1, Message msg2) {
      DateTime time1 = msg1.dateSentUtc ?? now;
      DateTime time2 = msg2.dateSentUtc ?? now;
      return time1.compareTo(time2);  // chronological
    });
  }
}

class FileAttachment {
  final String? id;
  final String? name;
  final String? type;

  String? url;

  FileAttachment({this.id, this.name, this.type, this.url});

  static FileAttachment? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return FileAttachment(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      type: JsonUtils.stringValue(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  static List<FileAttachment>? listFromJson(List<dynamic>? jsonList) {
    List<FileAttachment>? items;
    if (jsonList != null) {
      items = <FileAttachment>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, FileAttachment.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<FileAttachment>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (FileAttachment? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }

  String? get extension => name?.split('.').last;
}

class Conversation {
  final String? id;
  final String? lastMessageText;
  final Message? lastMessage;
  final DateTime? lastActivityTimeUtc;
  final bool? mute;
  final List<ConversationMember>? members;
  final DateTime? dateCreatedUtc;

  Conversation({this.id, this.lastMessageText, this.lastMessage, this.lastActivityTimeUtc, this.mute, this.members, this.dateCreatedUtc });

  static Conversation? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return Conversation(
      id: JsonUtils.stringValue(json['id']),
      lastMessageText: JsonUtils.stringValue(json['info']),
      lastMessage: Message.fromJson(json['last_message']),
      lastActivityTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['last_activity_time']), isUtc: true),
      mute: JsonUtils.boolValue(json['mute']),
      members: ConversationMember.listFromJson(JsonUtils.listValue(json['members'])),
      dateCreatedUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['date_created']), isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'info': lastMessageText,
      'last_message': lastMessage,
      'last_activity_time': DateTimeUtils.utcDateTimeToString(lastActivityTimeUtc),
      'mute': mute,
      'members': ConversationMember.listToJson(members),
      'date_created': DateTimeUtils.utcDateTimeToString(dateCreatedUtc),
    };
  }

  static List<Conversation>? listFromJson(List<dynamic>? jsonList) {
    List<Conversation>? items;
    if (jsonList != null) {
      items = <Conversation>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Conversation.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<Conversation>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (Conversation? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }

  static void sortListByLastActivityTime(List<Conversation> conversations) {
    DateTime now = DateTime.now();
    conversations.sort((Conversation conv1, Conversation conv2) {
      DateTime time1 = conv1.lastActivityTimeUtc ?? now;
      DateTime time2 = conv2.lastActivityTimeUtc ?? now;
      return time2.compareTo(time1);  // reverse chronological
    });
  }

  bool get isGroupConversation => (members?.length ?? 0) > 1;
  String? get membersString => List.generate(members?.length ?? 0, (index) => members?[index].name ?? '').join(', ');
  List<String>? get memberIds => List.generate(members?.length ?? 0, (index) => members?[index].accountId ?? '');
}

class ConversationMember {
  final String? accountId;
  final String? name;

  ConversationMember({this.accountId, this.name});

  static ConversationMember? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return ConversationMember(
      accountId: JsonUtils.stringValue(json['account_id']),
      name: JsonUtils.stringValue(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'name': name,
    };
  }

  static List<ConversationMember>? listFromJson(List<dynamic>? jsonList) {
    List<ConversationMember>? items;
    if (jsonList != null) {
      items = <ConversationMember>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, ConversationMember.fromJson(jsonEntry));
      }
    }
    return items;
  }

  static List<dynamic>? listToJson(List<ConversationMember>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (ConversationMember? value in values) {
        ListUtils.add(json, value?.toJson());
      }
    }
    return json;
  }
}