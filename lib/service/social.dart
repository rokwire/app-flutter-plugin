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

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'dart:async';

class Social extends Service with NotificationsListener {

  static const String notifyMessageDetail = "edu.illinois.rokwire.social.message.detail";
  static const String notifyPostCreated  = 'edu.illinois.rokwire.social.post.created';
  static const String notifyPostUpdated  = 'edu.illinois.rokwire.social.post.updated';
  static const String notifyPostDeleted  = 'edu.illinois.rokwire.social.post.deleted';
  static const String notifyPostsUpdated = "edu.illinois.rokwire.social.posts.updated";

  static const String notifyConversationsUpdated = "edu.illinois.rokwire.social.conversations.updated";
  static const String notifyMessageSent = "edu.illinois.rokwire.social.message.sent";
  static const String notifyMessageEdited = "edu.illinois.rokwire.social.message.edited";
  static const String notifyMessageDeleted = "edu.illinois.rokwire.social.message.deleted";

  static const String notifyReactionsUpdated = "edu.illinois.rokwire.social.reactions.update";
  // Filtering keys
  static const String _postsOperationKey = 'operation';
  static const String _postsOperationAndValue = 'and';
  static const String _postsOperationOrValue = 'or';
  static const String _postsCriteriaItemsKey = 'criteria_items';

  // Singleton Factory
  static Social? _instance;

  static Social? get instance => _instance;

  static set instance(Social? value) => _instance = value;

  factory Social() => _instance ?? (_instance = Social.internal());

  Social.internal();

  // Service
  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUiUri,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return {Config(), Auth2(), DeepLink()};
  }

  @override
  Future<void> initService() async {
    await super.initService();
  }

  // Deep Link Setup
  static String get messageDetailRawUrl => '${DeepLink().appUrl}/social_message';
  static String messageDetailUrl({String? conversationId, String? messageId, String? messageGlobalId}) => UrlUtils.buildWithQueryParameters(
      messageDetailRawUrl, <String, String>{
        if (conversationId != null)
          'conversation_id': "$conversationId",
        if (messageId != null)
          'message_id': "$messageId",
        if (messageGlobalId != null)
          'message_global_id': "$messageGlobalId",
      }
  );

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUiUri) {
      onDeepLinkUri(JsonUtils.cast(param));
    }
  }

  void onDeepLinkUri(Uri? uri) {
    if ((uri != null) && uri.matchDeepLinkUri(Uri.tryParse(messageDetailRawUrl))) {
      try { NotificationService().notify(notifyMessageDetail, uri.queryParameters.cast<String, dynamic>()); }
      catch (e) { debugPrint(e.toString()); }
    }
  }

  //APIs

  Future<Post?> pinPost({required String postId, bool pinned = true}) async{
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to create social post. Reason: missing social url.');
      return null;
    }

    String? requestBody = JsonUtils.encode({"pinned": pinned});
    Response? response = await Network().put('$socialUrl/posts/$postId/pinned-update', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Post? result = Post.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyPostUpdated, result);
      NotificationService().notify(notifyPostsUpdated);
      return result;
    } else {
      Log.e('Failed to pin social post. Reason: $responseCode, $responseBody');
      return null;
    }

  }

  Future<Post?> createPost({required Post post}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to create social post. Reason: missing social url.');
      return null;
    }
    String? requestBody = JsonUtils.encode(post.toJson());
    Response? response = await Network().post('$socialUrl/posts', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Post? result = Post.fromJson(JsonUtils.decodeMap(responseBody));
      NotificationService().notify(notifyPostCreated, result);
      NotificationService().notify(notifyPostsUpdated);
      return result;
    } else {
      Log.e('Failed to create social post. Reason: $responseCode, $responseBody');
      return null;
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
      bool showCommentsCount = false,
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

    Map<String, dynamic> receiverCriteria = {_postsOperationKey: _postsOperationAndValue, _postsCriteriaItemsKey: receiverItem};
    mainCriteriaItems.add(receiverCriteria);

    late String mainOperation;
    if (type == PostType.direct_message) {
      // 2. Created_By criteria
      mainOperation = _postsOperationOrValue;
      Map<String, dynamic> createdByItem = {
        'status': statusToString,
        'created_by': Auth2().accountId,
        'authorization_context':
            AuthorizationContext.forMembersType(membersType: ContextItemMembersType.listed_accounts, groupIds: groupIds)
      };
      Map<String, dynamic> createdByCriteria = {_postsOperationKey: _postsOperationAndValue, _postsCriteriaItemsKey: createdByItem};
      mainCriteriaItems.add(createdByCriteria);
    } else {
      mainOperation = _postsOperationAndValue;
    }

    // 3. Common

    List<String>? details;
    if (showCommentsCount) {
      details = ['comments-count'];
    }

    // 4. Request Body
    Map<String, dynamic> requestBody = {
      'offset': offset,
      'limit': limit,
      'order': _socialSortOrderToString(order),
      'sort_by': _socialSortByToString(sortBy)
    };
    if (details != null) {
      requestBody['details'] = details;
    }
    requestBody[_postsOperationKey] = mainOperation;
    requestBody[_postsCriteriaItemsKey] = mainCriteriaItems;

    String? encodedBody = JsonUtils.encode(requestBody);
    Response? response = await Network().post('$socialUrl/posts/load', body: encodedBody, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Map<String, dynamic>? jsonResponse = JsonUtils.decodeMap(responseBody);
      List<dynamic>? detailsJsonList = JsonUtils.listValue(jsonResponse?['details']);
      List<dynamic>? postsJsonList = JsonUtils.listValue(jsonResponse?['posts']);

      List<PostDetails>? detailsList = PostDetails.listFromJson(detailsJsonList);
      List<Post>? posts = Post.listFrom(json: postsJsonList, detailsList: detailsList);
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

  Future<bool> react({required String entityId, required SocialEntityType source, Reaction? reaction}) async {
    String? sourceString = socialEntityTypeToString(source);
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to react on $sourceString with id $entityId. Reason: missing social url.');
      return false;
    }
    Map<String, dynamic> requestJson = reaction?.toJson() ?? {};
    requestJson["identifier"] = entityId;
    requestJson["source"] = sourceString;

    String? encodedBody = JsonUtils.encode(requestJson);
    Response? response = await Network().post('$socialUrl/v2/reactions/alter', auth: Auth2(), body: encodedBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      NotificationService().notify(notifyReactionsUpdated, {"identifier": entityId, "source": source});
      return true;
    } else {
      Log.e('Failed to react on $sourceString with id $entityId. Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<List<Reaction>?> loadReactions({required String entityId, required SocialEntityType source, String? innerContextIdentifier}) async {
    String? sourceString = socialEntityTypeToString(source);
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load reactions for $sourceString with id $entityId. Reason: missing social url.');
      return null;
    }
    Map<String, dynamic> requestJson = {'identifier': entityId, 'source': sourceString};
    if(StringUtils.isNotEmpty(innerContextIdentifier))
      requestJson['inner_context'] = ContextItem(identifier: innerContextIdentifier).toJson();

    String? encodedBody = JsonUtils.encode(requestJson);
    Response? response = await Network().post('$socialUrl/reactions', auth: Auth2(), body: encodedBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<Reaction>? reactions = Reaction.listFromJson(JsonUtils.decodeList(responseBody));
      return reactions;
    } else {
      Log.e('Failed to load reactions for $sourceString with id $entityId. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<bool> reportAbuse(
      {String? groupId,
      String? entityId,
      SocialEntityType? source,
      String? reportMsg,
      bool reportToDeanOfStudents = false,
      bool reportToGroupAdmins = false}) async {
    String? sourceString = socialEntityTypeToString(source);
    if (StringUtils.isEmpty(Config().socialUrl)) {
      Log.e('Failed to report abuse for $sourceString with id $entityId. Reason: missing social url.');
      return false;
    }
    Map<String, dynamic> requestBody = {
      'comment': reportMsg,
      'identifier': entityId,
      'report_to_dean': reportToDeanOfStudents,
      'report_to_admins': reportToGroupAdmins,
      'source': sourceString
    };
    String? encodedBody = JsonUtils.encode(requestBody);
    String url = '${Config().socialUrl}/abuse/report';
    Response? response = await Network().put(url, body: encodedBody, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return true;
    } else {
      Log.e('Failed to report abuse for $sourceString with id $entityId. Reason: $responseCode, $responseBody.');
      return false;
    }
  }

  Future<Response?> _loadStatsResponse() async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load stats response. Reason: missing social url.');
      return null;
    }
    Response? response = await Network().get('$socialUrl/statistics', auth: Auth2());
    return response;
  }

  Future<SocialStats?> loadStats() async {
    Response? response = await _loadStatsResponse();
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      SocialStats? stats = SocialStats.fromJson(JsonUtils.decodeMap(responseString));
      return stats;
    } else {
      Log.e('Failed to load stats. Reason: $responseCode, $responseString.');
      return null;
    }
  }

  Future<int> getUserPostsCount() async {
    SocialStats? stats = await loadStats();
    return stats?.posts ?? 0;
  }

  Future<bool?> deleteUser({NetworkAuthProvider? auth}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isNotEmpty(socialUrl) && ((auth != null) || Auth2().isLoggedIn)) {
      Response? response = await Network().delete("$socialUrl/user", auth: auth ?? Auth2());
      if (response?.statusCode == 200) {
        return true;
      } else {
        Log.e('Social: Failed to delete user. Reason: ${response?.statusCode}, ${response?.body}.');
        return false;
      }
    }
    return null;
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

  // Conversations

  Future<List<Conversation>?> loadConversations({Iterable<String>? ids, int limit = 20, int offset = 0, String? name, bool? mute, DateTime? fromTime, DateTime? toTime}) async {
    String accountId = Auth2().accountId ?? '';
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load conversations. Reason: missing social url.');
      return null;
    }

    Map<String, String> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if ((ids != null) && ids.isNotEmpty) {
      queryParams['ids'] = ids.join(',');
    }
    if (StringUtils.isNotEmpty(name)) {
      queryParams['name'] = name!;
    }
    if (mute != null) {
      queryParams['mute'] = mute.toString();
    }
    if (fromTime != null) {
      String? fromTimeStr = DateTimeUtils.utcDateTimeToString(fromTime);
      if (fromTimeStr != null) {
        queryParams['from-time'] = fromTimeStr;
      }
    }
    if (toTime != null) {
      String? toTimeStr = DateTimeUtils.utcDateTimeToString(toTime);
      if (toTimeStr != null) {
        queryParams['to-time'] = toTimeStr;
      }
    }

    socialUrl = UrlUtils.addQueryParameters('$socialUrl/conversations', queryParams);

    Response? response = await Network().get(socialUrl, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<Conversation>? conversations = Conversation.listFromJson(JsonUtils.decodeList(responseBody));
      conversations?.forEach((conversation) {
        conversation.members?.removeWhere((member) => member.accountId == accountId);
      });
      return conversations;
    } else {
      Log.e('Failed to load conversations. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<Conversation?> loadConversation(String? id) async {
    List<Conversation>? conversations = (id != null) ? await loadConversations(ids: [id], offset: 0, limit: 1) : null;
    return ((conversations != null) && conversations.isNotEmpty) ? conversations.first : null;
  }

  Future<Conversation?> createConversation({required List<String> memberIds}) async {
    String accountId = Auth2().accountId ?? '';
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to create conversation. Reason: missing social url.');
      return null;
    }
    if (memberIds.isEmpty) {
      Log.e('Failed to create conversation. Reason: missing members.');
      return null;
    }
    String? requestBody = JsonUtils.encode({
      'members': memberIds
    });
    Response? response = await Network().post('$socialUrl/conversations', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Conversation? conversation = Conversation.fromJson(JsonUtils.decodeMap(responseBody));
      conversation?.members?.removeWhere((member) => member.accountId == accountId);

      NotificationService().notify(notifyConversationsUpdated);
      return conversation;
    } else {
      Log.e('Failed to create conversation. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<Conversation?> updateConverstion({required String conversationId, bool? mute}) async {
    String accountId = Auth2().accountId ?? '';
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to update conversation $conversationId. Reason: missing social url.');
      return null;
    }
    String? requestBody = JsonUtils.encode({
      'mute': mute
    });
    Response? response = await Network().put('$socialUrl/conversations/$conversationId', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      Conversation? conversation = Conversation.fromJson(JsonUtils.decodeMap(responseBody));
      conversation?.members?.removeWhere((member) => member.accountId == accountId);

      NotificationService().notify(notifyConversationsUpdated);
      return conversation;
    } else {
      Log.e('Failed to update conversation $conversationId. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<List<Message>?> loadConversationMessages({required String conversationId,
    int offset = 0, int limit = 100,
    String? extendLimitToMessageId, String? extendLimitToGlobalMessageId}) async
  {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load messages for conversation $conversationId. Reason: missing social url.');
      return null;
    }

    Map<String, String> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (extendLimitToMessageId != null)
        'extend-limit-to-message-id': extendLimitToMessageId,
      if (extendLimitToGlobalMessageId != null)
        'extend-limit-to-global-message-id': extendLimitToGlobalMessageId,
    };

    socialUrl = UrlUtils.addQueryParameters('$socialUrl/conversations/$conversationId/messages', queryParams);

    Response? response = await Network().get(socialUrl, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return Message.listFromJson(JsonUtils.decodeList(responseBody));
    } else {
      Log.e('Failed to load messages for conversation $conversationId. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  Future<bool> updateConversationMessage({required String conversationId, required String globalMessageId, required String newText,}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to update conversation message. Reason: missing social url.');
      return false;
    }
    if (StringUtils.isEmpty(conversationId) || StringUtils.isEmpty(globalMessageId)) {
      Log.e('Failed to update conversation message. Reason: missing conversationId or globalMessageId.');
      return false;
    }
    if (StringUtils.isEmpty(newText)) {
      Log.e('Failed to update conversation message. Reason: missing message text.');
      return false;
    }

    String? requestBody = JsonUtils.encode({'message': newText});

    String url = '$socialUrl/conversations/$conversationId/messages/$globalMessageId/update';

    Response? response = await Network().put(
      url,
      auth: Auth2(),
      body: requestBody,
    );

    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200 || responseCode == 204) {
      Log.d('updateConversationMessage: success (code $responseCode) for $globalMessageId');
      NotificationService().notify(notifyMessageEdited);
      return true;
    } else {
      Log.e('Failed to update conversation message ($conversationId). Reason: $responseCode, $responseBody');
      return false;
    }
  }

  Future<bool> deleteConversationMessage({
    required String conversationId,
    required String globalMessageId,
  }) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to delete conversation message. Reason: missing social url.');
      return false;
    }
    if (StringUtils.isEmpty(conversationId) || StringUtils.isEmpty(globalMessageId)) {
      Log.e('Failed to delete conversation message. Reason: missing conversationId or globalMessageId.');
      return false;
    }

    String url = '$socialUrl/conversations/$conversationId/messages/$globalMessageId/delete';
    Response? response = await Network().delete(url, auth: Auth2());

    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;

    if ((responseCode == 200) || (responseCode == 204)) {
      Log.d('deleteConversationMessage: success (code $responseCode) for $globalMessageId');
      NotificationService().notify(notifyMessageDeleted);
      return true;
    } else {
      Log.e('Failed to delete conversation message ($conversationId). Reason: $responseCode, $responseBody');
      return false;
    }
  }




  Future<List<Message>?> createConversationMessage({required String conversationId, required String message}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to create message for conversation $conversationId. Reason: missing social url.');
      return null;
    }
    if (message.isEmpty) {
      Log.e('Failed to create message for conversation $conversationId. Reason: missing message.');
      return null;
    }
    String? requestBody = JsonUtils.encode({
      'message': message
    });
    Response? response = await Network().post('$socialUrl/conversations/$conversationId/messages/send', auth: Auth2(), body: requestBody);
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      List<Message>? messages = Message.listFromJson(JsonUtils.decodeList(responseBody));
      NotificationService().notify(notifyMessageSent);
      return messages;
    } else {
      Log.e('Failed to create message for conversation $conversationId. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  // find users

  Future<List<ConversationMember>?> loadAccounts({int limit = 20, int offset = 0, String? firstName, String? lastName}) async {
    String? socialUrl = Config().socialUrl;
    if (StringUtils.isEmpty(socialUrl)) {
      Log.e('Failed to load accounts. Reason: missing social url.');
      return null;
    }

    Map<String, String> queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (StringUtils.isNotEmpty(firstName)) {
      queryParams['first-name'] = firstName!;
    }
    if (StringUtils.isNotEmpty(lastName)) {
      queryParams['last-name'] = lastName!;
    }

    socialUrl = UrlUtils.addQueryParameters('$socialUrl/accounts', queryParams);

    Response? response = await Network().get(socialUrl, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseBody = response?.body;
    if (responseCode == 200) {
      return ConversationMember.listFromJson(JsonUtils.decodeList(responseBody));
    } else {
      Log.e('Failed to load accounts. Reason: $responseCode, $responseBody');
      return null;
    }
  }

  // User Data

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    Response? response = (Config().socialUrl != null) ? await Network().get("${Config().socialUrl}/user-data", auth: Auth2()) : null;
    return (response?.succeeded == true) ? JsonUtils.decodeMap(response?.body) : null;
  }
}

enum SocialSortOrder { asc, desc }

enum SocialSortBy { date_created, activation_date }
