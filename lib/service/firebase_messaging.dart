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
 
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase_messaging;
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class FirebaseMessaging with Service {

  static const String notifyToken                 = "edu.illinois.rokwire.firebase.messaging.token";
  static const String notifyForegroundMessage     = "edu.illinois.rokwire.firebase.messaging.message.foreground";

  static const String notifyGroupsNotification    = "edu.illinois.rokwire.firebase.messaging.groups.updated";

  String?   _token;
  
  // Singletone Factory

  static FirebaseMessaging? _instance;

  static FirebaseMessaging? get instance => _instance;
  
  @protected
  static set instance(FirebaseMessaging? value) => _instance = value;

  factory FirebaseMessaging() => _instance ?? (_instance = FirebaseMessaging.internal());

  @protected
  FirebaseMessaging.internal();

  // Public getters

  String? get token => _token;
  bool get hasToken => StringUtils.isNotEmpty(_token);

  // Service

  @override
  Future<void> initService() async {
    await firebase_messaging.FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    firebase_messaging.FirebaseMessaging.onMessage.listen((firebase_messaging.RemoteMessage message) {
      Log.d('FCM: onMessage');
      onFirebaseMessage(message);
    });

    firebase_messaging.FirebaseMessaging.onMessageOpenedApp.listen((firebase_messaging.RemoteMessage message) {
      Log.d('FCM: onMessageOpenedApp');
      onFirebaseMessage(message);
    });

    firebase_messaging.FirebaseMessaging.instance.getToken().then((String? token) => applyToken(token));

    await super.initService();
  }

  @override
  void initServiceUI() {
    firebase_messaging.FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        processDataMessage(message.data);
      }
    });
  }

  @override
  Set<Service> get serviceDependsOn {
    return { FirebaseCore(), Storage(), Config() };
  }

  Future<NotificationsAuthorizationStatus> get authorizationStatus async {
    firebase_messaging.NotificationSettings settings = await firebase_messaging.FirebaseMessaging.instance.getNotificationSettings();
    return _convertStatus(settings.authorizationStatus);
  }

  Future<bool> get requiresAuthorization async {
    firebase_messaging.NotificationSettings settings = await firebase_messaging.FirebaseMessaging.instance.getNotificationSettings();
    firebase_messaging.AuthorizationStatus authorizationStatus = settings.authorizationStatus;
    // There is not "notDetermined" status for android. Treat "denied" in Android like "notDetermined" in iOS
    if (Config().operatingSystem == "android") {
      return (authorizationStatus != firebase_messaging.AuthorizationStatus.denied);
    } else {
      return (authorizationStatus == firebase_messaging.AuthorizationStatus.notDetermined);
    }
  }

  Future<NotificationsAuthorizationStatus> requestAuthorization() async {
    firebase_messaging.FirebaseMessaging messagingInstance = firebase_messaging.FirebaseMessaging.instance;
    firebase_messaging.NotificationSettings requestSettings = await messagingInstance.requestPermission(
        alert: true, announcement: false, badge: true, carPlay: false, criticalAlert: false, provisional: false, sound: true);
    return _convertStatus(requestSettings.authorizationStatus);
  }

  NotificationsAuthorizationStatus _convertStatus(firebase_messaging.AuthorizationStatus status) {
    switch(status) {
      case firebase_messaging.AuthorizationStatus.authorized:
        return NotificationsAuthorizationStatus.authorized;
      case firebase_messaging.AuthorizationStatus.denied:
        return NotificationsAuthorizationStatus.denied;
      case firebase_messaging.AuthorizationStatus.notDetermined:
        return NotificationsAuthorizationStatus.notDetermined;
      case firebase_messaging.AuthorizationStatus.provisional:
        return NotificationsAuthorizationStatus.provisional;
    }
  }

  // Token

  @protected
  void applyToken(String? token) {
    if ((token != null) && (token != _token)) {
      _token = token;
      Log.d('FCM: token: $token');
      NotificationService().notify(notifyToken, null);
    }
  }

  // Subscription APIs

  Future<bool> subscribeToTopic(String? topic) async {
    return await Inbox().subscribeToTopic(topic: topic, token: _token);
  }

  Future<bool> unsubscribeFromTopic(String? topic) async {
    return await Inbox().unsubscribeFromTopic(topic: topic, token: _token);
  }

  // Message Processing

  @protected
  Future<dynamic> onFirebaseMessage(firebase_messaging.RemoteMessage message) async {
    Log.d("FCM: onFirebaseMessage: $message");
    try {
      if ((AppLifecycle.instance?.state == AppLifecycleState.resumed) && StringUtils.isNotEmpty(message.notification?.body)) {
        NotificationService().notify(notifyForegroundMessage, {
          "body": message.notification?.body,
          "onComplete": () {
            processDataMessage(message.data);
          }
        });
      } else {
        processDataMessage(message.data);
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
  }

  
  @protected
  void processDataMessage(Map<String, dynamic>? data) {
  }
}

enum NotificationsAuthorizationStatus { authorized, denied, notDetermined, provisional }