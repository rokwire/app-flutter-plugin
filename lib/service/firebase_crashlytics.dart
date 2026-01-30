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

import 'package:firebase_crashlytics/firebase_crashlytics.dart' as google;
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/firebase_core.dart';
import 'package:rokwire_plugin/service/service.dart';

///
/// Disable FirebaseCrashlytics for web - not supported.
///
class FirebaseCrashlytics with Service {
  
  // Singletone Factory

  static FirebaseCrashlytics? _instance;

  static FirebaseCrashlytics? get instance => _instance;

  @protected
  static set instance(FirebaseCrashlytics? value) => _instance = value;

  factory FirebaseCrashlytics() => _instance ?? (_instance = FirebaseCrashlytics.internal());

  @protected
  FirebaseCrashlytics.internal();
  
  // Service

  @override
  Future<void> initService() async{
    if (!kIsWeb) {
      // Enable automatic data collection
      google.FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Set device identifier
      String? deviceId = await Auth2().getDeviceId(); // Exception: Safe to call this API nevertheless has Auth2 dependency.
      if (deviceId != null) {
        google.FirebaseCrashlytics.instance.setUserIdentifier(deviceId);
      }

      // Pass all uncaught errors to Firebase.Crashlytics.
      FlutterError.onError = handleFlutterFatalError;
      PlatformDispatcher.instance.onError = handleFlutterError;
    }

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn => { FirebaseCore() };

  void handleFlutterFatalError(FlutterErrorDetails details) {
    if (!kIsWeb) {
      FlutterError.dumpErrorToConsole(details);
      google.FirebaseCrashlytics.instance.recordFlutterError(details, fatal: true);
    }
  }

  bool handleFlutterError(Object exception, StackTrace stackTrace) {
    if (kIsWeb) {
      return false;
    } else {
      debugPrintStack(stackTrace: stackTrace, label: exception.toString());
      google.FirebaseCrashlytics.instance.recordError(exception, stackTrace, fatal: true);
      return true;
    }
  }

  void handleZoneError(dynamic exception, StackTrace stackTrace) {
    if (!kIsWeb) {
      debugPrintStack(stackTrace: stackTrace, label: exception.toString());
      google.FirebaseCrashlytics.instance.recordError(exception, stackTrace);
    }
  }

  void recordError(dynamic exception, [StackTrace? stackTrace]) {
    if (!kIsWeb) {
      stackTrace ??= StackTrace.current;
      debugPrintStack(stackTrace: stackTrace, label: exception.toString());
      google.FirebaseCrashlytics.instance.recordError(exception, stackTrace);
    }
  }

  void log(String message) {
    debugPrint(message, wrapWidth: 512);
    if (!kIsWeb) {
      google.FirebaseCrashlytics.instance.log(message);
    }
  }



  Future<void> flush() async {
    if (!kIsWeb) {
      return google.FirebaseCrashlytics.instance.sendUnsentReports();
    }
  }
}