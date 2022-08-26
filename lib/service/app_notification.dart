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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

class AppNotification {
  static const String notify = 'edu.illinois.rokwire.appnotification.notification';

  // Singletone Factory

  static AppNotification ? _instance;

  static AppNotification? get instance => _instance;
  
  @protected
  static set instance(AppNotification? value) => _instance = value;

  factory AppNotification() => _instance ?? (_instance = AppNotification.internal());

  @protected
  AppNotification.internal();

  // Implementation

  bool handleNotification(Notification notification) {
    NotificationService().notify(notify, notification);
    return false;
  }
}
