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

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:uni_links/uni_links.dart';

class DeepLink with Service {
  
  static const String notifyUri  = "edu.illinois.rokwire.deeplink.uri";
  static const String notifyUiUri  = "edu.illinois.rokwire.deeplink.uri.ui";

  List<Uri>? _uriCache;

  // Singletone Factory

  static DeepLink? _instance;

  static DeepLink? get instance => _instance;
  
  @protected
  static set instance(DeepLink? value) => _instance = value;

  factory DeepLink() => _instance ?? (_instance = DeepLink.internal());

  @protected
  DeepLink.internal();

  // Service

  @override
  Future<void> initService() async {

    if (!kIsWeb) {
      // 1. Initial Uri
      getInitialUri().then((Uri? uri) => handleUri(uri));

      // 2. Updated uri
      uriLinkStream.listen((Uri? uri) => handleUri(uri));
    } else {
      debugPrint('WEB: deepLinks - not implemented.');
    }

    _uriCache = <Uri>[];

    await super.initService();
  }

  @override
  void initServiceUI() {
    processUriCache();
  }

  // App URI

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
      NotificationService().notify(notifyUiUri, uri);
    }
  }

  // URI cahcing
  @protected
  void handleUri(Uri? uri) {
    if (uri != null) {
      NotificationService().notify(notifyUri, uri);
      if (_uriCache != null) {
        cacheUri(uri);
      }
      else {
        processUri(uri);
      }
    }
  }

  @protected
  void processUri(Uri uri) {
    NotificationService().notify(notifyUiUri, uri);
  }

  @protected
  void cacheUri(Uri uri) {
    _uriCache?.add(uri);
  }

  @protected
  void processUriCache() {
    if (_uriCache != null) {
      List<Uri> uriCache = _uriCache!;
      _uriCache = null;

      for (Uri uri in uriCache) {
        processUri(uri);
      }
    }
  }
}
