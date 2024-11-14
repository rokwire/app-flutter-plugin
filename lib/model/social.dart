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

import 'package:rokwire_plugin/utils/utils.dart';

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
        json.add(value?.toJson());
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
