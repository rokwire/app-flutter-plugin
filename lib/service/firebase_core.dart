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

import 'package:firebase_core/firebase_core.dart' as google;
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class FirebaseCore extends Service {

  google.FirebaseApp? _firebaseApp;

  // Singletone Factory

  static FirebaseCore? _instance;

  static FirebaseCore? get instance => _instance;

  @protected
  static set instance(FirebaseCore? value) => _instance = value;

  factory FirebaseCore() => _instance ?? (_instance = FirebaseCore.internal());

  @protected
  FirebaseCore.internal();
  
  // Service

  @override
  Future<void> initService() async{
    await initFirebase();
    
    if (_firebaseApp != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Firebase Initialization Failed',
        description: 'Failed to initialize Firebase application.',
      );
    }
  }

  // This is required for the web app
  @override
  Set<Service> get serviceDependsOn => { Config() };

  Future<void> initFirebase() async {
    google.FirebaseOptions? firebaseOptions;
    if (kIsWeb) {
      String? firebaseApiKey = Config().firebaseApiKey;
      String? firebaseAppId = Config().firebaseAppId;
      String? firebaseMessagingSenderId = Config().firebaseMessagingSenderId;
      String? firebaseProjectId = Config().firebaseProjectId;

      firebaseOptions = google.FirebaseOptions(
        apiKey: StringUtils.ensureNotEmpty(firebaseApiKey),
        appId: StringUtils.ensureNotEmpty(firebaseAppId),
        messagingSenderId: StringUtils.ensureNotEmpty(firebaseMessagingSenderId),
        projectId: StringUtils.ensureNotEmpty(firebaseProjectId),
      );
    }

    _firebaseApp ??= await google.Firebase.initializeApp(options: firebaseOptions);
  }

  google.FirebaseApp? get app => _firebaseApp;
}