/*
 * Copyright 2025 Board of Trustees of the University of Illinois.
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

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as path_package;
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension UriExt on Uri {
  bool matchDeepLinkUri(Uri? deepLinkUri) =>
      (deepLinkUri != null) && (deepLinkUri.scheme == scheme) && (deepLinkUri.authority == authority) && (deepLinkUri.path == path);

  bool get isPdf {
    String? extension;
    if (path.isNotEmpty) {
      extension = path_package.extension(path);
    }
    return (extension == '.pdf');
  }

  Uri? build({String? scheme, String? userInfo, String? host, int? port, String? path, String? query, String? fragment}) {
    String sourceHost = this.host;
    String sourcePath = this.path;
    if (sourceHost.isEmpty && sourcePath.isNotEmpty) {
      List<String> sourcePathComponents = sourcePath.split('/');
      if (0 < sourcePathComponents.length) {
        sourceHost = sourcePathComponents.first;
        sourcePath = (1 < sourcePathComponents.length) ? sourcePathComponents.slice(1).join('/') : "";
      }
    }

    try {
      return Uri(
          scheme: (scheme != null) ? scheme : (this.scheme.isNotEmpty ? this.scheme : null),
          userInfo: (userInfo != null) ? userInfo : (this.userInfo.isNotEmpty ? this.userInfo : null),
          host: (host != null) ? host : (sourceHost.isNotEmpty ? sourceHost : null),
          port: (port != null) ? port : ((0 < this.port) ? this.port : null),
          path: (path != null) ? path : (sourcePath.isNotEmpty ? sourcePath : null),
          //pathSegments: uri.pathSegments.isNotEmpty ? uri.pathSegments : null,
          query: (query != null) ? query : (this.query.isNotEmpty ? this.query : null),
          //queryParameters: uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
          fragment: (fragment != null) ? fragment : (this.fragment.isNotEmpty ? this.fragment : null)
      );
    }
    catch(e) {
      return null;
    }
  }

  Uri? fix({String scheme = 'http'}) => this.scheme.isEmpty ? this.build(scheme: scheme) : null;

  Future<Uri?> fixAsync({int? timeout = 60}) async {
    if (scheme.isEmpty) {
      final List<String> schemes = ['https', 'http'];
      for (String newScheme in schemes) {
        Uri? schemeUri = build(scheme: newScheme);
        Response? schemeResponse = (schemeUri != null) ? await Network().head(schemeUri, timeout: timeout) : null;
        if (schemeResponse?.statusCode == 200) {
          return schemeUri;
        }
      }

      final String www = 'www.';
      String? host = this.host.isNotEmpty ? this.host : (this.path.isNotEmpty ? this.path : null);
      if ((host != null) && !host.startsWith(www)) {
        for (String newScheme in schemes) {
          Uri? schemeUri = this.build(scheme: newScheme, host: www + host);
          Response? schemeResponse = (schemeUri != null) ? await Network().head(schemeUri, timeout: timeout) : null;
          if (schemeResponse?.statusCode == 200) {
            return schemeUri;
          }
        }
      }

    }
    return null;
  }

  bool get isWebScheme => ((scheme == 'http') || (scheme == 'https'));

  bool get isValid => StringUtils.isNotEmpty(scheme) && (StringUtils.isNotEmpty(host) || StringUtils.isNotEmpty(path));

  static Uri? tryParse(String? url) {
    return (url != null) ? Uri.tryParse(url) : null;
  }

  static Uri? parse(String? url) {
    Uri? uri = tryParse(url);
    if ((uri != null) && uri.host.isEmpty && (uri.path.isNotEmpty)) {
      List<String> pathComponents = uri.path.split('/');
      if (0 < pathComponents.length) {
        String host = pathComponents.first;
        String? path = (1 < pathComponents.length) ? pathComponents.slice(1).join('/') : null;
        try {
          return Uri(
              scheme: (uri.scheme.isNotEmpty ? uri.scheme : null),
              userInfo: uri.userInfo.isNotEmpty ? uri.userInfo : null,
              host: host,
              port: (0 < uri.port) ? uri.port : null,
              path: path,
              //pathSegments: uri.pathSegments.isNotEmpty ? uri.pathSegments : null,
              query: uri.query.isNotEmpty ? uri.query : null,
              //queryParameters: uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
              fragment: uri.fragment.isNotEmpty ? uri.fragment : null);
        } catch (e) {}
      }
    }
    return uri;
  }
}
