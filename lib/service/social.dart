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
  //TBD: DDGS - rename / remove group
  static const String notifyGroupPostCreated  = 'edu.illinois.rokwire.social.post.created';
  static const String notifyGroupPostUpdated  = 'edu.illinois.rokwire.social.post.updated';
  static const String notifyGroupPostDeleted  = 'edu.illinois.rokwire.social.post.deleted';
  static const String notifyGroupPostsUpdated = "edu.illinois.rokwire.social.posts.updated";

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

  Future<bool> createPost({required Post post}) async {
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
      Post? result = Post.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyGroupPostCreated, result);
      NotificationService().notify(notifyGroupPostsUpdated);
      return true;
    } else {
      Log.e('Failed to create social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> updatePost({required Post post}) async {
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
      Post? result = Post.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyGroupPostUpdated, result);
      NotificationService().notify(notifyGroupPostsUpdated);
      return true;
    } else {
      Log.e('Failed to update social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> deletePost({required Post post}) async {
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
      Post? result = Post.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyGroupPostDeleted, result);
      NotificationService().notify(notifyGroupPostsUpdated);
      return true;
    } else {
      Log.e('Failed to delete social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<List<Post>?> loadPosts(
      {String? groupId,
      PostType? type,
      Set<String>? postIds,
      PostStatus status = PostStatus.active,
      int limit = 0,
      int offset = 0,
      PostSortOrder order = PostSortOrder.desc,
      PostSortBy? sortBy}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load social posts. Reason: missing social url.');
      return null;
    }
    Map<String, dynamic> requestBody = {
      'status': postStatusToString(status),
      'offset': offset,
      'limit': limit,
      'order': _sortOrderToString(order),
      'sort_by': _sortByToString(sortBy)
    };
    if (CollectionUtils.isNotEmpty(postIds)) {
      requestBody['ids'] = postIds;
    }
    if (groupId != null) {
      SocialContext? context = SocialContext.fromIdentifier(groupId);
      requestBody['context'] = context?.toJson();
    }
    if (type != null) {
      List<String>? groupIds = (groupId != null) ? [groupId] : null;
      requestBody['authorization_context'] = AuthorizationContext.fromPostType(type: type, groupIds: groupIds);
    }
    String? encodedBody = JsonUtils.encode(requestBody);
    Response? response = await Network().post('$socialUrl/posts/load', body: encodedBody, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<Post>? posts = Post.listFromJson(JsonUtils.decodeList(responseBody));
      return posts;
    } else {
      Log.e('Failed to load social posts. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<Post?> loadSinglePost({required String postId, String? groupId}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load single post. Reason: missing social url.');
      return null;
    }
    List<Post>? resultPosts = await loadPosts(groupId: groupId, postIds: {postId});
    if (resultPosts == null) {
      Log.e('Failed to load single post {$postId} for group {$groupId}.');
      return null;
    }
    return (resultPosts.length >= 1) ? resultPosts.first : null;
  }

  String _sortOrderToString(PostSortOrder? order) {
    switch (order) {
      case PostSortOrder.asc:
        return 'asc';
      case PostSortOrder.desc:
        return 'desc';
      default:
        return 'desc';
    }
  }

  String _sortByToString(PostSortBy? sortBy) {
    switch (sortBy) {
      case PostSortBy.date_created:
        return 'date_created';
      case PostSortBy.activation_date:
        return 'activation_date';
      default:
        return 'date_created';
    }
  }
}

enum PostSortOrder { asc, desc }

enum PostSortBy { date_created, activation_date }
