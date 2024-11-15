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

import 'package:http/http.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Social with Service implements NotificationsListener {
  static const String notifyGroupPostCreated = 'edu.illinois.rokwire.social.post.created';
  static const String notifyGroupPostUpdated = 'edu.illinois.rokwire.social.post.updated';
  static const String notifyGroupPostDeleted = 'edu.illinois.rokwire.social.post.deleted';

  // Singleton Factory

  static Social? _instance;

  static Social? get instance => _instance;

  static set instance(Social? value) => _instance = value;

  factory Social() => _instance ?? (_instance = Social.internal());

  Social.internal();

  // Service

  @override
  void createService() {
    super.createService();
  }

  @override
  void destroyService() {
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    super.initService();
  }

  // Notification Listener

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  // APIs

  Future<bool> createPost({required SocialPost post}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to create social post. Reason: missing social url.');
      return false;
    }
    String? requestBody = JsonUtils.encode(post.toJson());
    Response? response = await Network().post('$socialUrl/posts', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      SocialPost? result = SocialPost.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyGroupPostCreated, result);
      return true;
    } else {
      Log.e('Failed to create social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> updatePost({required SocialPost post}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to update social post. Reason: missing social url.');
      return false;
    }
    String? postId = post.id;
    if (StringUtils.isEmpty(postId)) {
      Log.e('Failed to update social post. Reason: missing post id.');
      return false;
    }
    String? requestBody = JsonUtils.encode(post.toJson());
    Response? response = await Network().put('$socialUrl/posts/$postId', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      SocialPost? result = SocialPost.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyGroupPostUpdated, result);
      return true;
    } else {
      Log.e('Failed to update social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> deletePost({required SocialPost post}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to delete social post. Reason: missing social url.');
      return false;
    }
    String? postId = post.id;
    if (StringUtils.isEmpty(postId)) {
      Log.e('Failed to delete social post. Reason: missing post id.');
      return false;
    }
    Response? response = await Network().delete('$socialUrl/posts/$postId', auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      SocialPost? result = SocialPost.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyGroupPostDeleted, result);
      return true;
    } else {
      Log.e('Failed to delete social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<List<SocialPost>?> loadPosts(
      {SocialAuthorizationContext? authorizationContext,
      Set<String>? ids,
      PostStatus? status,
      int limit = 0,
      int offset = 0,
      SortOrder? order,
      SortBy? sortBy}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load social posts. Reason: missing social url.');
      return null;
    }
    Map<String, dynamic> requestBody = {
      'offset': offset,
      'limit': limit,
      'order': _sortOrderToString(order),
      'sort_by': _sortByToString(sortBy)
    };
    if (CollectionUtils.isNotEmpty(ids)) {
      requestBody['ids'] = ids;
    }
    if (authorizationContext != null) {
      requestBody['authorization_context'] = authorizationContext.toJson();
    }
    if (status != null) {
      requestBody['status'] = postStatusToString(status);
    }
    Response? response = await Network().post('$socialUrl/posts/load', body: JsonUtils.encode(requestBody), auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<SocialPost>? posts = SocialPost.listFromJson(JsonUtils.decodeList(responseBody));
      return posts;
    } else {
      Log.e('Failed to load social posts. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  String _sortOrderToString(SortOrder? order) {
    switch (order) {
      case SortOrder.asc:
        return 'asc';
      case SortOrder.desc:
        return 'desc';
      default:
        return 'desc';
    }
  }

  String _sortByToString(SortBy? sortBy) {
    switch (sortBy) {
      case SortBy.start_time:
        return 'start_time';
      case SortBy.end_time:
        return 'end_time';
      case SortBy.name:
        return 'name';
      case SortBy.proximity:
        return 'proximity';
      default:
        return 'start_time';
    }
  }
}

enum SortOrder { asc, desc }

enum SortBy { start_time, end_time, name, proximity }
