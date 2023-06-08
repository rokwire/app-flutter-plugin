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

import 'dart:collection';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/rokwire_plugin.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GeoFence with Service implements NotificationsListener, ContentItemCategoryClient {

  static const String notifyRegionEnter            = "edu.illinois.rokwire.geofence.region.enter";
  static const String notifyRegionExit             = "edu.illinois.rokwire.geofence.region.exit";
  static const String notifyCurrentRegionsUpdated  = "edu.illinois.rokwire.geofence.regions.current.updated";
  static const String notifyCurrentBeaconsUpdated  = "edu.illinois.rokwire.geofence.beacons.current.updated";
  
  static const String _regionContentCategory = "region";

  LinkedHashMap<String, GeoFenceRegion>? _regions;
  Map<String, bool> _regionOverrides = <String, bool>{};
  Set<String> _insideRegions = <String>{};
  Set<String> _currentRegions = <String>{};
  final Map<String, Set<GeoFenceBeacon>> _insideBeacons = <String, Set<GeoFenceBeacon>>{};
  Map<String, Set<GeoFenceBeacon>> _currentBeacons = <String, Set<GeoFenceBeacon>>{};
  int? _debugRegionRadius;

  // Singletone Factory

  static GeoFence? _instance;

  static GeoFence? get instance => _instance;
  
  @protected
  static set instance(GeoFence? value) => _instance = value;

  factory GeoFence() => _instance ?? (_instance = GeoFence.internal());

  @protected
  GeoFence.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Content.notifyContentItemsChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _debugRegionRadius = Storage().debugGeoFenceRegionRadius;
    _regionOverrides = Storage().geoFenceRegionOverrides ?? <String, bool>{};

    _regions = GeoFenceRegion.mapFromJsonList(_regionsJson);
    
    _updateCurrentRegions(notify: false);
    _updateCurrentBeacons(notify: false);

    monitorRegions();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return {Storage(), Content()};
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Content.notifyContentItemsChanged) {
      _onContentItemsChanged(param);
    }
  }

  void _onContentItemsChanged(Set<String>? categoriesDiff) {
    if (categoriesDiff?.contains(regionContentCategory) == true) {
      _onRegionsChanged();
    }
  }

  // Accessories

  LinkedHashMap<String, GeoFenceRegion>? get regions {
    return _regions;
  }

  Set<String> get currentRegionIds {
    return _currentRegions;
  }
  
  Map<String, bool> get regionOverrides => _regionOverrides;

  set regionOverrides(Map<String, bool> value) {
    if (!const DeepCollectionEquality().equals(_regionOverrides, value)) {
      Storage().geoFenceRegionOverrides = _regionOverrides = value;

      _updateCurrentRegions();
      _updateCurrentBeacons();
      monitorRegions();
    }
  }

  List<GeoFenceRegion> regionsList({String? type, bool? enabled, GeoFenceRegionType? regionType, bool? inside}) {
    List<GeoFenceRegion> regions = [];
    if (_regions != null) {
      _regions!.forEach((String? regionId, GeoFenceRegion? region) {
        if ((region != null) &&
            ((type == null) || (region.types?.contains(type) ?? false)) &&
            ((enabled == null) || (enabled == region.enabled)) &&
            ((regionType == null) || (regionType == region.regionType)) &&
            ((inside == null) || (inside == (_currentRegions.contains(regionId)))))
        {
          regions.add(region);
        }
      });
    }
    return regions;
  }

  Set<GeoFenceBeacon>? currentBeaconsInRegion(String regionId) {
    return _currentBeacons[regionId];
  }

  Future<bool?> startRangingBeaconsInRegion(String regionId) async {
    return JsonUtils.boolValue(await RokwirePlugin.geoFence('startRangingBeaconsInRegion', regionId));
  }

  Future<bool?> stopRangingBeaconsInRegion(String regionId) async {
    return JsonUtils.boolValue(await RokwirePlugin.geoFence('stopRangingBeaconsInRegion', regionId));
  }

  Future<List<GeoFenceBeacon>?> beaconsInRegion(String regionId) async {
    return GeoFenceBeacon.listFromJsonList(JsonUtils.listValue(await RokwirePlugin.geoFence('getBeaconsInRegion', regionId)));
  }

  int? get debugRegionRadius => _debugRegionRadius;

  set debugRegionRadius(int? value) {
    if (_debugRegionRadius != value) {
      Storage().debugGeoFenceRegionRadius = _debugRegionRadius = value;
      monitorRegions();
    }
  }

  // Region Content Items

  @protected
  String get regionContentCategory =>
    _regionContentCategory;

  List<dynamic>? get _regionsJson =>
    Content().contentListItem(regionContentCategory);

  void _onRegionsChanged() {
    _regions = GeoFenceRegion.mapFromJsonList(_regionsJson);
    _updateCurrentRegions();
    _updateCurrentBeacons();
    monitorRegions();
  }

  // ContentItemCategoryClient

  @override
  List<String> get contentItemCategory => <String>[regionContentCategory];

  // Implementation

  // ignore: unused_element
  static Future<List<String>?> _currentRegionIds() async {
    return JsonUtils.listStringsValue(await RokwirePlugin.geoFence('getCurrentRegions'));
  }

  @protected
  Future<void> monitorRegions() async {
    await RokwirePlugin.geoFence('monitorRegions', GeoFenceRegion.listToJsonList(GeoFenceRegion.filterList(_regions?.values, shouldMonitorRegion), locationRadius: _debugRegionRadius?.toDouble()));
  }

  @protected
  bool shouldMonitorRegion(GeoFenceRegion region) => (region.enabled == true) && !_regionOverrides.containsKey(region.id);

  void _updateInsideRegions(List<String>? regionIds) {
    if (regionIds != null) {
      Set<String> insideRegions = Set.from(regionIds);
      if (!const DeepCollectionEquality().equals(_insideRegions, insideRegions)) {
        _insideRegions = insideRegions;
        _updateCurrentRegions();
      }
    }
  }

  void _updateCurrentRegions({bool notify = true}) {
    Set<String> currentRegions = <String>{};

    // add regions that should be always current
    _regionOverrides.forEach((String regionId, bool override) {
      if (override == true) {
        GeoFenceRegion? region = (_regions != null) ? _regions![regionId] : null;
        if (region?.regionType == GeoFenceRegionType.location) {
          currentRegions.add(regionId);
        }
      }
    });

    // add regions that are currently inside
    for (String insideRegionId in _insideRegions) {
      // skip regions that should be never current
      if (_regionOverrides[insideRegionId] != false) {
        currentRegions.add(insideRegionId);
      }
    }

    if (!const DeepCollectionEquality().equals(_currentRegions, currentRegions)) {
      _currentRegions = currentRegions;
      if (notify) {
        NotificationService().notify(notifyCurrentRegionsUpdated);
      }
    }
  }

  void _updateInsideBeacons({String? regionId, List<GeoFenceBeacon>? beaconsList}) {
    try {
      if (regionId != null) {
        Set<GeoFenceBeacon>? beacons = (beaconsList != null) ? Set.from(beaconsList) : null;
        if (!const DeepCollectionEquality().equals(_insideBeacons[regionId], beacons)) {
          if (beacons != null) {
            _insideBeacons[regionId] = Set<GeoFenceBeacon>.from(beacons);
          }
          else {
            _insideBeacons.remove(regionId);
          }
          _updateCurrentBeacons();
        }
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
  }

  void _updateCurrentBeacons({bool notify = true}) {
    Map<String, Set<GeoFenceBeacon>> currentBeacons = <String, Set<GeoFenceBeacon>>{};

    // add regions that should be always current
    _regionOverrides.forEach((String regionId, bool override) {
      if (override == true) {
        GeoFenceRegion? region = (_regions != null) ? _regions![regionId] : null;
        if (region?.beacon != null) {
          currentBeacons[regionId] = <GeoFenceBeacon>{ region!.beacon! };
        }
      }
    });

    // add regions that are currently inside
    _insideBeacons.forEach((String regionId, Set<GeoFenceBeacon> beacons) {
      // skip regions that should be never current
      if (_regionOverrides[regionId] != false) {
        currentBeacons[regionId] = beacons;
      }
    });

    if (!const DeepCollectionEquality().equals(_currentBeacons, currentBeacons)) {
      _currentBeacons = currentBeacons;
      if (notify) {
        NotificationService().notify(notifyCurrentBeaconsUpdated);
      }
    }
  }

  // Plugin

  Future<dynamic> onPluginNotification(String? name, dynamic arguments) async {
    if (name == 'onEnterRegion') {
      String? regionId = JsonUtils.stringValue(arguments);
      debugPrint("GeoFence didEnterRegion: $regionId}");
      NotificationService().notify(notifyRegionEnter, regionId);
    }
    else if (name == 'onExitRegion') {
      String? regionId = JsonUtils.stringValue(arguments);
      debugPrint("GeoFence didExitRegion: $regionId}");
      NotificationService().notify(notifyRegionExit, regionId);
    }
    else if (name == 'onCurrentRegionsChanged') {
      _updateInsideRegions(JsonUtils.listStringsValue(arguments));
    }
    else if (name == 'onBeaconsInRegionChanged') {
      Map<String, dynamic>? params = JsonUtils.mapValue(arguments);
      String? regionId = (params != null) ? JsonUtils.stringValue(params['regionId']) : null;
      List<GeoFenceBeacon>? beacons = (params != null) ? GeoFenceBeacon.listFromJsonList(JsonUtils.listValue(params['beacons'])) : null;
      _updateInsideBeacons(regionId: regionId, beaconsList: beacons);
    }
  }
}


