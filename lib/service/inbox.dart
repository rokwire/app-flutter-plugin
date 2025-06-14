
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/firebase_messaging.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Inbox with Service, NotificationsListener {

  static const String notifyInboxUserInfoChanged             = "edu.illinois.rokwire.inbox.user.info.changed";
  static const String notifyInboxUnreadMessagesCountChanged  = "edu.illinois.rokwire.inbox.messages.unread.count.changed";
  static const String notifyInboxMessagesDeleted             = "edu.illinois.rokwire.inbox.messages.deleted";
  static const String notifyInboxMessageRead                 = "edu.illinois.rokwire.inbox.message.read";

  String?   _fcmToken;
  String?   _fcmUserId;
  bool?     _isServiceInitialized;
  DateTime? _pausedDateTime;
  
  InboxUserInfo? _userInfo;
  int? _unreadMessagesCount;

  // Singletone Factory

  static Inbox? _instance;

  static Inbox? get instance => _instance;
  
  @protected
  static set instance(Inbox? value) => _instance = value;

  factory Inbox() => _instance ?? (_instance = Inbox.internal());

  @protected
  Inbox.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      FirebaseMessaging.notifyToken,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _fcmToken = Storage().inboxFirebaseMessagingToken;
    _fcmUserId = Storage().inboxFirebaseMessagingUserId;
    _userInfo = Storage().inboxUserInfo;
    _unreadMessagesCount = Storage().inboxUnreadMessagesCount;
    _isServiceInitialized = true;
    _processFcmToken();
    _loadUserInfo();
    _loadUnreadMessagesCount();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config(), Auth2(), FirebaseMessaging() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FirebaseMessaging.notifyToken) {
      _processFcmToken();
    }
    else if (name == Auth2.notifyLoginChanged) {
      _processFcmToken();
      _loadUserInfo();
      _loadUnreadMessagesCount();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param); 
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _processFcmToken();
          _loadUserInfo();
          _loadUnreadMessagesCount();
        }
      }
    }
  }

  // Inbox APIs

  Future<List<InboxMessage>?> loadMessages({DateTime? startDate, DateTime? endDate, String? category, Iterable<String>? messageIds, bool? muted, bool? unread, int? offset, int? limit }) async {

    String urlParams = "";
    
    if (offset != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "offset=$offset";
    }
    
    if (limit != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "limit=$limit";
    }

    if (startDate != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "start_date=${startDate.millisecondsSinceEpoch}";
    }

    if (endDate != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "end_date=${endDate.millisecondsSinceEpoch}";
    }

    if (muted != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "mute=$muted";
    }

    if (unread != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "read=${!unread}";
    }

    if (urlParams.isNotEmpty) {
      urlParams = "?$urlParams";
    }

    dynamic body = (messageIds != null) ? JsonUtils.encode({ "ids": List<String>.from(messageIds) }) : null;

    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/messages$urlParams" : null;
    Response? response = await Network().get(url, body: body, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      return (InboxMessage.listFromJson(JsonUtils.decodeList(responseString)) ?? []);
    } else {
      debugPrint('Failed to load notifications messages. Reason: $responseCode, body: $responseString');
      return null;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    return await deleteMessages([messageId]);
  }

  Future<bool> deleteMessages(Iterable<String>? messageIds) async {
    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/messages" : null;
    String? body = JsonUtils.encode({
      "ids": (messageIds != null) ? List<String>.from(messageIds) : null
    });

    Response? response = await Network().delete(url, body: body, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      NotificationService().notify(notifyInboxMessagesDeleted);
      return true;
    } else {
      debugPrint('Failed to delete messages with ids {${messageIds}. Reason: $responseCode, ${response?.body}.');
      return false;
    }
  }

  Future<bool> sendMessage(InboxMessage? message) async {
    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/message" : null;
    String? body = JsonUtils.encode(message?.toJson());

    Response? response = await Network().post(url, body: body, auth: Auth2());
    return (response?.statusCode == 200);
  }

  Future<bool> readMessage(String? messageId) async {
    if (StringUtils.isEmpty(messageId)) {
      debugPrint('Failed to read message - missing message id.');
      return false;
    }
    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/message/$messageId/read" : null;
    Response? response = await Network().put(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      _loadUnreadMessagesCount(); // Reload unread messages count when a message is marked as read.
      NotificationService().notify(notifyInboxMessageRead);
      return true;
    } else {
      debugPrint('Failed to read message. Reason: $responseCode, ${response?.body}.');
      return false;
    }
  }

  Future<bool> markAllMessagesAsRead() async {
    String? url = (Config().notificationsUrl != null) ? "${Config().notificationsUrl}/api/messages/read" : null;
    String? body = JsonUtils.encode({'read': true});//{"read":true|false}
    Response? response = await Network().put(url, body: body, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      _loadUnreadMessagesCount(); // Reload unread messages count when all messages are read.
      NotificationService().notify(notifyInboxMessageRead);
      return true;
    } else {
      debugPrint('Failed to read messages. Reason: $responseCode, ${response?.body}.');
      return false;
    }
  }

  Future<bool> subscribeToTopic({String? topic, String? token}) async {
    _storeTopic(topic); // Store first, otherwise we have delay
    bool result = await _manageFCMSubscription(topic: topic, token: token, action: 'subscribe');
    if (!result){
      //if failed and not already stored remove
      Log.e("Unable to subscribe to topic: $topic");
    }

    return result;
  }

  Future<bool> unsubscribeFromTopic({String? topic, String? token}) async {
    _removeStoredTopic(topic); //StoreFist, otherwise we have visual delay
    bool result = await _manageFCMSubscription(topic: topic, token: token, action: 'unsubscribe');
    if (!result){
      //if failed //TBD
      Log.e("Unable to unsubscribe from topic: $topic");
    }

    return result;
  }

  Future<bool> _manageFCMSubscription({String? topic, String? token, String? action}) async {
    if ((Config().notificationsUrl != null) && (topic != null) && (token != null) && (action != null)) {
      String url = "${Config().notificationsUrl}/api/topic/$topic/$action";
      String? body = JsonUtils.encode({
        'token': token
      });
      Response? response = await Network().post(url, body: body, auth: Auth2());
      //Log.d("FCMTopic_$action($topic) => ${(response?.statusCode == 200) ? 'Yes' : 'No'}");
      return (response?.statusCode == 200);
    }
    return false;
  }

  // FCM Token

  void _processFcmToken() {
    // We call _processFcmToken when FCM token changes or when user logs in/out.
    if (_isServiceInitialized == true) {
      String? fcmToken = FirebaseMessaging().token;
      String? userId = Auth2().accountId;
      if ((fcmToken != null) && (fcmToken != _fcmToken)) {
        _updateFCMToken(token: fcmToken, previousToken: _fcmToken).then((bool result) {
          if (result) {
            Storage().inboxFirebaseMessagingToken = _fcmToken = fcmToken;
          }
        });
      }
      else if (userId != _fcmUserId) {
        _updateFCMToken(token: fcmToken).then((bool result) {
          if (result) {
            Storage().inboxFirebaseMessagingUserId = _fcmUserId = userId;
          }
        });
      }
    }
  }

  Future<bool> _updateFCMToken({String? token, String? previousToken}) async {
    if ((Config().notificationsUrl != null) && ((token != null) || (previousToken != null))) {
      String url = "${Config().notificationsUrl}/api/token";
      String? body = JsonUtils.encode({
        'token': token,
        'previous_token': previousToken,
        'app_platform': Platform.operatingSystem,
        'app_version': Config().appVersion,
      });
      Response? response = await Network().post(url, body: body, auth: Auth2());
      //Log.d("FCMToken_update(${(token != null) ? 'token' : 'null'}, ${(previousToken != null) ? 'token' : 'null'}) / UserId: '${Auth2().accountId}'  => ${(response?.statusCode == 200) ? 'Yes' : 'No'}");
      return (response?.statusCode == 200);
    }
    return false;
  }

  // Topics storage
  void _storeTopic(String? topic) {
    if (!Auth2().isLoggedIn) {
      Storage().addInboxFirebaseMessagingSubscriptionTopic(topic);
    }
    else if (userInfo != null) {
      _userInfo?.topics ??= <String>{};
      userInfo?.topics?.add(topic);
    }
  }

  void _removeStoredTopic(String? topic) {
    if (!Auth2().isLoggedIn) {
      Storage().removeInboxFirebaseMessagingSubscriptionTopic(topic);
    }
    else if (userInfo?.topics != null) {
      userInfo?.topics?.remove(topic);
    }
  }

  //UserInfo
  Future<Response?> _loadUserInfoResponse() async {
    try {
      return (Auth2().isLoggedIn && Config().notificationsUrl != null) ? await Network().get("${Config().notificationsUrl}/api/user", auth: Auth2()) : null;
    } catch (e) {
      Log.e('Failed to load inbox user info');
      Log.e(e.toString());
    }
    return null;
  }

  Future<void> _loadUserInfo() async {
    try {
      Response? response = await _loadUserInfoResponse();
      if (response?.statusCode == 200) {
        Map<String, dynamic>? jsonData = JsonUtils.decode(response?.body);
        InboxUserInfo? userInfo = InboxUserInfo.fromJson(jsonData);
        _applyUserInfo(userInfo);
      }
    } catch (e) {
      Log.e('Failed to load inbox user info');
      Log.e(e.toString());
    }
  }

  Future<bool> _putUserInfo(InboxUserInfo? userInfo) async {
    if (Auth2().isLoggedIn && Config().notificationsUrl != null && userInfo != null){
      String? body = JsonUtils.encode(userInfo.toJson()); // Update user API do not receive topics. Only update enable/disable notifications for now
      Response? response = await Network().put("${Config().notificationsUrl}/api/user", auth: Auth2(), body: body);
      if (response?.statusCode == 200) {
        Map<String, dynamic>? jsonData = JsonUtils.decode(response?.body);
        InboxUserInfo? userInfo = InboxUserInfo.fromJson(jsonData);
        _applyUserInfo(userInfo);
        return true;
      }
    }
    return false;
  }

  Future<bool> applySettingNotificationsEnabled(bool? value) async{
    if (_userInfo != null && value!=null){
      userInfo!.notificationsDisabled = value;
      return _putUserInfo(InboxUserInfo(userId: _userInfo!.userId, notificationsDisabled: value));
    }
    return false;
  }
  
  void _applyUserInfo(InboxUserInfo? userInfo){
    if (_userInfo != userInfo){
      Storage().inboxUserInfo = _userInfo = userInfo;
      NotificationService().notify(notifyInboxUserInfoChanged);
    } //else it's the same
  }

  //Delete User
  Future<bool?> deleteUser({NetworkAuthProvider? auth}) async {
    if ((Config().notificationsUrl != null) && ((auth != null) || Auth2().isLoggedIn)) {
      String? body = JsonUtils.encode({
        'notifications_disabled': true,
      });
      Response? response =  await Network().delete("${Config().notificationsUrl}/api/user", auth: auth ?? Auth2(), body: body);
      if (response?.statusCode == 200) {
        _applyUserInfo(null);
        return true;
      } else {
        Log.e('Inbox: Failed to delete user. Reason: ${response?.statusCode}, ${response?.body}.');
        return false;
      }
    }
    else {
      return null;
    }
  }

  InboxUserInfo? get userInfo{
    return _userInfo;
  }

  // Unread Messages Count
  Future<void> _loadUnreadMessagesCount() async {
    if (Auth2().isLoggedIn && (Config().notificationsUrl != null)) {
      String url = "${Config().notificationsUrl}/api/messages/stats";
      Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseBody = response?.body;
      if (responseCode == 200) {
        Map<String, dynamic>? jsonData = JsonUtils.decode(responseBody);
        int? unreadCount = jsonData != null ? JsonUtils.intValue(jsonData["not_read_not_mute"]) : null;
        _applyUnreadMessagesCount(unreadCount);
      } else {
        debugPrint('Failed to retrieve unread messages count. Reason: $responseCode, $responseBody');
      }
    }
    else {
      _applyUnreadMessagesCount(0);
    }
  }

  void _applyUnreadMessagesCount(int? unreadMessagesCount){
    if (_unreadMessagesCount != unreadMessagesCount){
      Storage().inboxUnreadMessagesCount = _unreadMessagesCount = unreadMessagesCount;
      NotificationService().notify(notifyInboxUnreadMessagesCountChanged);
    }
  }

  int get unreadMessagesCount {
    return _unreadMessagesCount ?? 0;
  }

  // User Data

  Future<Map<String, dynamic>?> loadUserDataJson() async {
    Response? response = (Config().notificationsUrl != null) ? await Network().get("${Config().notificationsUrl}/api/user-data", auth: Auth2()) : null;
    return (response?.succeeded == true) ? JsonUtils.decodeMap(response?.body) : null;
  }
}