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

class Social with Service {
  static const String notifyPostCreated  = 'edu.illinois.rokwire.social.post.created';
  static const String notifyPostUpdated  = 'edu.illinois.rokwire.social.post.updated';
  static const String notifyPostDeleted  = 'edu.illinois.rokwire.social.post.deleted';
  static const String notifyPostsUpdated = "edu.illinois.rokwire.social.posts.updated";

  // Filtering keys
  static const String _operationKey = 'operation';
  static const String _criteriaItemsKey = 'criteria_items';
  static const String _operationAndValue = 'and';
  static const String _operationOrValue = 'or';

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
      NotificationService().notify(notifyPostCreated, result);
      NotificationService().notify(notifyPostsUpdated);
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
      NotificationService().notify(notifyPostUpdated, result);
      NotificationService().notify(notifyPostsUpdated);
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
      NotificationService().notify(notifyPostDeleted, post);
      NotificationService().notify(notifyPostsUpdated);
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
      SocialSortOrder order = SocialSortOrder.desc,
      SocialSortBy? sortBy}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load social posts. Reason: missing social url.');
      return null;
    }

    // 1. Receiver criteria
    String? statusToString = postStatusToString(status);
    Map<String, dynamic> receiverItem = {'status': statusToString};
    if (CollectionUtils.isNotEmpty(postIds)) {
      receiverItem['ids'] = postIds!.toList();
    }
    bool hasGroupId = (groupId != null);
    if (hasGroupId) {
      SocialContext context = SocialContext.forGroup(groupId: groupId);
      receiverItem['context'] = context.toJson();
    }
    List<String>? groupIds = hasGroupId ? [groupId] : null;
    if (type != null) {
      List<String>? memberAccountIds;
      switch (type) {
        case PostType.post:
          memberAccountIds = null; // Post is for all group members
          break;
        case PostType.direct_message:
          memberAccountIds = (Auth2().accountId != null) ? [Auth2().accountId!] : null; // direct messages are for the current user.
          break;
      }
      receiverItem['authorization_context'] =
          AuthorizationContext.forGroups(groupIds: groupIds, memberAccountIds: memberAccountIds);
    }

    List<dynamic> mainCriteriaItems = <dynamic>[];

    Map<String, dynamic> receiverCriteria = {_operationKey: _operationAndValue, _criteriaItemsKey: receiverItem};
    mainCriteriaItems.add(receiverCriteria);

    late String mainOperation;
    if (type == PostType.direct_message) {
      // 2. Created_By criteria
      mainOperation = _operationOrValue;
      Map<String, dynamic> createdByItem = {
        'status': statusToString,
        'created_by': Auth2().accountId,
        'authorization_context':
            AuthorizationContext.forMembersType(membersType: ContextItemMembersType.listed_accounts, groupIds: groupIds)
      };
      Map<String, dynamic> createdByCriteria = {_operationKey: _operationAndValue, _criteriaItemsKey: createdByItem};
      mainCriteriaItems.add(createdByCriteria);
    } else {
      mainOperation = _operationAndValue;
    }

    // 3. Request Body
    Map<String, dynamic> requestBody = {
      'offset': offset,
      'limit': limit,
      'order': _socialSortOrderToString(order),
      'sort_by': _socialSortByToString(sortBy)
    };
    requestBody[_operationKey] = mainOperation;
    requestBody[_criteriaItemsKey] = mainCriteriaItems;

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

  Future<bool> createComment({required Comment comment}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to create social comment. Reason: missing social url.');
      return false;
    }
    String? parentId = comment.parentId;
    if (StringUtils.isEmpty(parentId)) {
      Log.e('Failed to create social comment. Reason: missing parent id.');
      return false;
    }
    String? requestBody = JsonUtils.encode(comment.toJson());
    Response? response = await Network().post('$socialUrl/posts/$parentId/comments', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.e('Failed to create social comment. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> updateComment({required Comment comment}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to update social comment. Reason: missing social url.');
      return false;
    }
    String? commentId = comment.id;
    if (StringUtils.isEmpty(commentId)) {
      Log.e('Failed to update social comment. Reason: missing comment id.');
      return false;
    }
    String? parentId = comment.parentId;
    if (StringUtils.isEmpty(parentId)) {
      Log.e('Failed to update social comment. Reason: missing parent id.');
      return false;
    }
    String? requestBody = JsonUtils.encode(comment.toJson());
    Response? response = await Network().put('$socialUrl/posts/$parentId/comments/$commentId', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.e('Failed to update social comment. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> deleteComment({required Comment comment}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to delete social comment. Reason: missing social url.');
      return false;
    }
    String? commentId = comment.id;
    if (StringUtils.isEmpty(commentId)) {
      Log.e('Failed to delete social comment. Reason: missing comment id.');
      return false;
    }
    String? parentId = comment.parentId;
    if (StringUtils.isEmpty(parentId)) {
      Log.e('Failed to delete social comment. Reason: missing parent id.');
      return false;
    }
    Response? response = await Network().delete('$socialUrl/posts/$parentId/comments/$commentId', auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.e('Failed to delete social post. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<List<Comment>?> loadComments({required String postId}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load social comments. Reason: missing social url.');
      return null;
    }
    Response? response = await Network().get('$socialUrl/posts/$postId/comments', auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<Comment>? posts = Comment.listFromJson(JsonUtils.decodeList(responseBody));
      return posts;
    } else {
      Log.e('Failed to load social comments. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<bool> react({required String? entityId, required ReactionSource source}) async {
    String? sourceString = reactionSourceToString(source);
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to react on $sourceString with id $entityId. Reason: missing social url.');
      return false;
    }
    Map<String, dynamic> requestJson = {'identifier': entityId, 'source': sourceString};
    String? encodedBody = JsonUtils.encode(requestJson);
    Response? response = await Network().post('$socialUrl/reactions/alter', auth: Auth2(), body: encodedBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.e('Failed to react on $sourceString with id $entityId. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<ReactionsResult?> loadReactions({required String entityId, required ReactionSource source}) async {
    String? sourceString = reactionSourceToString(source);
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load reactions for $sourceString with id $entityId. Reason: missing social url.');
      return null;
    }
    Map<String, dynamic> requestJson = {'identifier': entityId, 'source': sourceString};
    String? encodedBody = JsonUtils.encode(requestJson);
    Response? response = await Network().post('$socialUrl/reactions', auth: Auth2(), body: encodedBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      ReactionsResult? reactionsResult = ReactionsResult.fromJson(JsonUtils.decodeMap(responseBody));
      return reactionsResult;
    } else {
      Log.e('Failed to load reactions for $sourceString with id $entityId. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  String _socialSortOrderToString(SocialSortOrder? order) {
    switch (order) {
      case SocialSortOrder.asc:
        return 'asc';
      case SocialSortOrder.desc:
        return 'desc';
      default:
        return 'desc';
    }
  }

  String _socialSortByToString(SocialSortBy? sortBy) {
    switch (sortBy) {
      case SocialSortBy.date_created:
        return 'date_created';
      case SocialSortBy.activation_date:
        return 'activation_date';
      default:
        return 'date_created';
    }
  }
}

enum SocialSortOrder { asc, desc }

enum SocialSortBy { date_created, activation_date }
