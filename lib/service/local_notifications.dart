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
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LocalNotifications with Service {
  static const String notifyLocalNotificationTapped = "edu.illinois.rokwire.local_notifications.notification.tapped";
  
  // Singletone Factory

  static LocalNotifications? _instance;

  static LocalNotifications? get instance => _instance;

  @protected
  static set instance(LocalNotifications? value) => _instance = value;

  factory LocalNotifications() => _instance ?? (_instance = LocalNotifications.internal());

  @protected
  LocalNotifications.internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Service

  @override
  Future<void> initService() async {
    try {
      await RokwirePlugin.createAndroidNotificationChannel(androidNotificationChannel);
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidNotificationChannel);
    } catch (e) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Local Notifications Initialization Failed',
        description: 'Failed to create Android notification channel: ${e.toString()}.',
      );
    }
    
    bool? initSuccess = await _initPlugin();
    if (initSuccess == true) {  
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Local Notifications Initialization Failed',
        description: 'Failed to initialize local notifications plugin.',
      );
    }
  }

  Future<bool?> _initPlugin() {
    AndroidInitializationSettings androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);
    return _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: _onTapNotification);
  }

  // AndroidNotificationChannel

  AndroidNotificationChannel get androidNotificationChannel {
    return const AndroidNotificationChannel(
      "edu.illinois.rokwire.firebase_messaging.notification_channel",
      "Rokwire", // name
      description: "Rokwire notifications receiver",
      importance: Importance.high,
    );
  }

  AndroidNotificationDetails get androidNotificationDetails {
    AndroidNotificationChannel androidChannel = androidNotificationChannel;
    return AndroidNotificationDetails(
      androidChannel.id,
      androidChannel.name,
      channelDescription: androidChannel.description,
      importance: androidChannel.importance,
    );
  }

  DarwinNotificationDetails get iOSNotificationDetails {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
  }

  NotificationDetails get notificationDetails {
    return NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );
  }

  void _onTapNotification(NotificationResponse? response) {
    NotificationService().notify(notifyLocalNotificationTapped, _getActionFromNotificationResponse(response));
  }

  Future _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    NotificationService().notify(notifyLocalNotificationTapped, NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification, id: id, payload: payload
    ));
  }

  Future<bool> showNotification(String id, {String? title, String? message, String? payload, bool overwrite = true}) async {
    if (await _shouldScheduleNotification(id, overwrite)) {
      _localNotifications.show(
        id.hashCode,
        title,
        message,
        notificationDetails,
        payload: payload,
      );
      return true;
    }

    return false;
  }

  Future<bool> showPeriodic(String id, {String? title, String? message, String? payload = '', RepeatInterval repeatInterval = RepeatInterval.daily, bool overwrite = true}) async {
    if (await _shouldScheduleNotification(id, overwrite)) {
      _localNotifications.periodicallyShow(
        id.hashCode,
        title,
        message,
        repeatInterval,
        notificationDetails,
        payload: payload,
      );
      return true;
    }

    return false;
  }

  Future<bool> zonedSchedule(String id, {String? title, String? message, String? payload = '', DateTime? dateTime, bool overwrite = true}) async {
    if (await _shouldScheduleNotification(id, overwrite)) {
      _localNotifications.zonedSchedule(
        id.hashCode,
        title,
        message,
        timezone.TZDateTime.from(dateTime ?? DateTime.now(), timezone.getLocation(AppDateTime().localTimeZone)),
        notificationDetails,
        androidAllowWhileIdle: true,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime
      );
      return true;
    }

    return false;
  }

  Future<PendingNotificationRequest?> getPendingNotification(String id) async {
    List<PendingNotificationRequest> pendingList = await _localNotifications.pendingNotificationRequests();
    try {
      return pendingList.firstWhere((element) => element.id == id.hashCode);
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> clearNotification(String id, {bool cancel = true}) async {
    await _localNotifications.cancel(id.hashCode);
  }

  Future<void> clearPendingNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<ActionData?> getNotificationResponseAction() async {
    NotificationAppLaunchDetails? launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    return (launchDetails?.didNotificationLaunchApp == true) ? _getActionFromNotificationResponse(launchDetails?.notificationResponse) : null;
  }

  ActionData? _getActionFromNotificationResponse(NotificationResponse? response) {
    if (response != null) {
      List<ActionData> actions = ActionData.listFromJson(JsonUtils.listValue(JsonUtils.decode(response.payload)));
      if (CollectionUtils.isNotEmpty(actions)) {
        switch (response.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            if (actions.length > 1) {
              for (ActionData action in actions) {
                dynamic primary = action.params["primary"];
                if (primary is bool && primary) {
                  return action;
                }
              }
            }
            return actions[0];
          case NotificationResponseType.selectedNotificationAction:
            for (ActionData action in actions) {
              dynamic actionId = action.params["action_id"];
              if (actionId is String && actionId == response.actionId) {
                return action;
              }
            }
            return null;
          default:
            return null;
        }
      }
    }
    
    return null;
  }
  
  Future<bool> _shouldScheduleNotification(String id, bool overwrite) async => overwrite || (await getPendingNotification(id) == null);
}
