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

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

class DeepLink with Service {

  static const String notifyUri  = "edu.illinois.rokwire.deeplink.uri";
  static const String notifyUriError  = "edu.illinois.rokwire.deeplink.uri.error";

  // Singleton Factory

  static DeepLink? _instance;

  static DeepLink? get instance => _instance;
  
  @protected
  static set instance(DeepLink? value) => _instance = value;

  factory DeepLink() => _instance ?? (_instance = DeepLink.internal());

  @protected
  DeepLink.internal();

  Uri? _initialUri;
  Uri? get initialUri => _initialUri;

  // Service

  @override
  Future<void> initService() async {
    final _appLinks = AppLinks();

    // 1. Initial Uri
    _appLinks.getInitialAppLink().then((uri) {
      if (uri != null) {
        _initialUri = uri;
        debugPrint('Launch URI: $uri');
        NotificationService().notify(notifyUri, uri);
      }
    });

    // 2. Updated uri
    if (!kIsWeb) {
      _appLinks.uriLinkStream.listen((Uri? uri) {
        debugPrint('Received URI: $uri');
        if (uri != null) {
          NotificationService().notify(notifyUri, uri);
        } else {
          NotificationService().notify(notifyUriError, 'deeplink null');
        }
      }, onError: (e) {
        NotificationService().notify(notifyUriError, e);
      }, onDone: () {
        NotificationService().notify(notifyUriError, 'deeplink handler done');
      });
    }

    await super.initService();
  }

  String? get appScheme => null;
  String? get appHost => null;
  String? get appUrl {
    String url = "";
    if (appScheme?.isNotEmpty == true) {
      url += '$appScheme://';
    }
    if (appHost?.isNotEmpty == true) {
      url += '$appHost';
    }
    return url;
  }
  
  bool isAppUri(Uri? uri) => (uri?.scheme == appScheme) && (uri?.host == appHost);
  bool isAppUrl(String? url) =>  isAppUri((url != null) ? Uri.tryParse(url) : null);
  void launchUrl(String? url) => launchUri((url != null) ? Uri.tryParse(url) : null);

  void launchUri(Uri? uri) {
    if (uri != null) {
      NotificationService().notify(notifyUri, uri);
    }
  }
}
