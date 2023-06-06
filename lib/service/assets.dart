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

import 'dart:core';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class Assets with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.assets.changed";

  static const String _assetsName      = "assets.json";

  Directory? _assetsDir;
  DateTime?  _pausedDateTime;

  Map<String, dynamic>? _defAssets;
  Map<String, dynamic>? _appAssets;
  Map<String, dynamic>? _netAssets;
  Map<String, dynamic>? _assets;

  // Singletone Factory

  static Assets? _instance;

  static Assets? get instance => _instance;
  
  @protected
  static set instance(Assets? value) => _instance = value;

  factory Assets() => _instance ?? (_instance = Assets.internal());

  @protected
  Assets.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, AppLifecycle.notifyStateChanged);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _assetsDir = await getAssetsDir();
    _defAssets = await loadFromAssets(assetsKey);
    _appAssets = kIsWeb ? null : await loadFromAssets(appAssetsKey);
    _netAssets = await loadFromCache(netCacheFileName);

    if ((_defAssets != null) || (_appAssets != null) || (_netAssets != null)) {
      build();
      updateFromNet();
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Assets Initialization Failed',
        description: 'Failed to initialize application assets content.',
      );
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Config() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          updateFromNet();
        }
      }
    }
  }

  // Assets

  dynamic operator [](dynamic key) {
    return MapPathKey.entry(_assets, key);
  }

  String? randomStringFromListWithKey(String key) {
    List<dynamic>? list = JsonUtils.listValue(this[key]);
    return ((list != null) && list.isNotEmpty) ? JsonUtils.stringValue(list[Random().nextInt(list.length)]) : null;
  }

  // Implementation

  Future<Directory?> getAssetsDir() async {
    Directory? assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return assetsDir;
  }

  @protected
  String get assetsKey => 'assets/$_assetsName';

  @protected
  String get appAssetsKey => 'app/assets/$_assetsName';

  @protected
  Future<Map<String, dynamic>?> loadFromAssets(String assetsKey) async {
    try { return JsonUtils.decodeMap(await rootBundle.loadString(assetsKey)); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  @protected
  String get netCacheFileName => _assetsName;

  @protected
  Future<Map<String, dynamic>?> loadFromCache(String cacheFileName) async {
    try { 
      if (_assetsDir != null) {
        String cacheFilePath = join(_assetsDir!.path, cacheFileName);
        File cacheFile = File(cacheFilePath);
        if (await cacheFile.exists()) {
          return JsonUtils.decodeMap(await cacheFile.readAsString());
        }
      }
    }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  @protected
  Future<void> saveToCache(String cacheFileName, String? content) async {
    try { 
      if (_assetsDir != null) {
        String cacheFilePath = join(_assetsDir!.path, cacheFileName);
        File cacheFile = File(cacheFilePath);
        if (content != null) {
          cacheFile.writeAsString(content, flush: true);
        }
        else if (await cacheFile.exists()) {
          await cacheFile.delete();
        }
      }
    }
    catch(e) { debugPrint(e.toString()); }
  }

  @protected
  String get netAssetFileName => _assetsName;

  @protected
  Future<String?> loadContentStringFromNet() async {
    if (StringUtils.isNotEmpty(Config().assetsUrl)) {
      http.Response? response = await Network().get("${Config().assetsUrl}/$netAssetFileName");
      return (response?.statusCode == 200) ? response?.body : null;
    }
    return null;
  }

  @protected
  Future<void> updateFromNet() async {
    String? netAssetsString = await loadContentStringFromNet();
    Map<String, dynamic>? netAssets = JsonUtils.decodeMap(netAssetsString);
    if (((netAssets != null) && !const DeepCollectionEquality().equals(netAssets, _netAssets)) ||
        ((netAssets == null) && (_netAssets != null)))
    {
      _netAssets = netAssets;
      await saveToCache(netCacheFileName, netAssetsString);
      build();
      NotificationService().notify(notifyChanged, null);
    }
  }

  @protected
  void build() {
    _assets = <String, dynamic>{};
    if (_defAssets != null) {
      _assets!.addAll(_defAssets!);
    }
    if (_appAssets != null) {
      _assets!.addAll(_appAssets!);
    }
    if (_netAssets != null) {
      _assets!.addAll(_netAssets!);
    }
  }
}
