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
import 'package:timezone/timezone.dart' as tz;
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';


class LocalNotifications with Service {
  static const int pendingNotificationsLimit = 64; // TODO: use growable list instead

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  List<String?>? _scheduledIds;
  
  // Singletone Factory

  static LocalNotifications? _instance;

  static LocalNotifications? get instance => _instance;

  @protected
  static set instance(LocalNotifications? value) => _instance = value;

  factory LocalNotifications() => _instance ?? (_instance = LocalNotifications.internal());

  @protected
  LocalNotifications.internal();

  // Service

  @override
  Future<void> initService() async {
    // NotificationAppLaunchDetails? launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    // if (launchDetails?.didNotificationLaunchApp == true) {
    //   //TODO: use launchDetails!.notificationResponse to do some navigation?
    // }
    try {
      await RokwirePlugin.createAndroidNotificationChannel(androidNotificationChannel);
      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidNotificationChannel);
    } catch (e) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Local Notifications Initialization Failed',
        description: 'Failed to create Android notification channel: ${e.toString()}.',
      );
    }
    
    bool? initSuccess = await _initPlugin();
    if (initSuccess == true) {
    // List<PendingNotificationRequest> pending = await _localNotifications.pendingNotificationRequests();
      List<String?>? storedPendingIds = Storage().pendingNotificationIds;
      _scheduledIds = storedPendingIds != null ? List.from(storedPendingIds, growable: false) : List.filled(pendingNotificationsLimit, null);

      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Local Notifications Initialization Failed',
        description: 'Failed to initialize local notifications plugin.',
      );
    }
  }

  Future<bool?> _initPlugin() {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('app_icon');
    DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
    InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);
    return _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: _onTapNotification, onDidReceiveBackgroundNotificationResponse: _onTapNotificationBackground);
  }

  @override
  Set<Service> get serviceDependsOn {
    return { AppDateTime(), Storage(), };
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
    _clearNotification(notificationId: response?.id, cancel: false);
    // Log.d('Android: on select local notification: ' + payload!);
    // NotificationService().notify(notifySelected, payload);
  }

  @pragma('vm:entry-point')
  void _onTapNotificationBackground(NotificationResponse? response) {
    _clearNotification(notificationId: response?.id, cancel: false);
    // Log.d('Android: on select local notification: ' + payload!);
    // NotificationService().notify(notifySelected, payload);
  }

  Future _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    _clearNotification(notificationId: id, cancel: false);
    // Log.d('iOS: on did receive local notification: ' + payload!);
  }

  void showNotification(String id, {String? title, String? message, String? payload}) {
    _localNotifications.show(
      _getNotificationId(id),
      title,
      message,
      notificationDetails,
      payload: payload,
    );
  }

  void showPeriodic(String id, {String? title, String? message, RepeatInterval repeatInterval = RepeatInterval.daily, String? payload = ''}) {
    _localNotifications.periodicallyShow(
      _getNotificationId(id),
      title,
      message,
      repeatInterval,
      notificationDetails,
      payload: payload,
    );
  }

  void zonedSchedule(String id, {required DateTime formattedDate, required String? title, required String? message, String? payload = ''}) {
    _localNotifications.zonedSchedule(
      _getNotificationId(id),
      title,
      message,
      tz.TZDateTime.from(formattedDate, tz.getLocation(AppDateTime().localTimeZone)),
      notificationDetails,
      androidAllowWhileIdle: true,
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
  }

  int _getNotificationId(String id) {
    // List<PendingNotificationRequest> pending = await _localNotifications.pendingNotificationRequests();

    int notificationId = _scheduledIds!.indexOf(id);
    if (notificationId == -1) {
      notificationId = _scheduledIds!.indexOf(null);
      _scheduledIds![notificationId] = id;
      Storage().pendingNotificationIds = _scheduledIds;
    }
    return notificationId;
  }

  void _clearNotification({String? id, int? notificationId, bool cancel = true}) {
    notificationId ??= (id != null ? _getNotificationId(id) : null);
    if (notificationId != null) {
      _scheduledIds![notificationId] = null;
      Storage().pendingNotificationIds = _scheduledIds;

      if (cancel) {
        _localNotifications.cancel(notificationId);
      }
    }
  }

  void _clearPendingNotifications() {
    _localNotifications.cancelAll();
    Storage().pendingNotificationIds = _scheduledIds = null;
  }
}
