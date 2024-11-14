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

import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

class Social with Service implements NotificationsListener {

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
}
