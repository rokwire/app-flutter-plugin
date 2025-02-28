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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';

class FlexUI with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.flexui.changed";

  static const String _assetsName   = "flexUI.json";
  static const String _defaultContentSourceKey   = "";

  static const String _featuresKey   = "features";
  static const String _attributesKey   = "attributes";

  Directory? _assetsDir;
  DateTime?  _pausedDateTime;

  Map<String, dynamic>? _defContentSource;
  Map<String, dynamic>? _appContentSource;
  Map<String, dynamic>? _netContentSource;
  Map<String, dynamic>? _contentSource;

  Map<String, dynamic>? _defaultContent;
  Set<dynamic>?         _defaultFeatures;
  Map<String, Set<String>>? _sourceAttributes;
  Map<String, Set<String>>? _defaultAttributes;
  Set<String>?          _defaultStorageKeys;

  // Singletone Factory

  static FlexUI? _instance;

  static FlexUI? get instance => _instance;

  @protected
  static set instance(FlexUI? value) => _instance = value;

  factory FlexUI() => _instance ?? (_instance = FlexUI.internal());

  @protected
  FlexUI.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      Auth2.notifyPrefsChanged,
      Auth2.notifyUserDeleted,
      Auth2UserPrefs.notifyRolesChanged,
      Auth2UserPrefs.notifyPrivacyLevelChanged,
      Auth2.notifyLoginChanged,
      Auth2.notifyLinkChanged,
      AppLivecycle.notifyStateChanged,
      Groups.notifyUserGroupsUpdated,
      GeoFence.notifyCurrentRegionsUpdated,
      Config.notifyConfigChanged,
      Storage.notifySettingChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _assetsDir = await getAssetsDir();
    _defContentSource = await loadFromAssets(assetsKey);
    _appContentSource = await loadFromAssets(appAssetsKey);
    _netContentSource = await loadFromCache(netCacheFileName);
    build();
    if (_defaultContent != null) {
      updateFromNet();
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'FlexUI Initialization Failed',
        description: 'Failed to initialize FlexUI content.',
      );
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Config(), Auth2(), Groups(), GeoFence() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyPrefsChanged) ||
        (name == Auth2.notifyUserDeleted) ||
        (name == Auth2UserPrefs.notifyRolesChanged) ||
        (name == Auth2UserPrefs.notifyPrivacyLevelChanged) ||
        (name == Auth2.notifyLoginChanged) ||
        (name == Auth2.notifyLinkChanged) ||
        (name == Groups.notifyUserGroupsUpdated) ||
        (name == GeoFence.notifyCurrentRegionsUpdated) ||
        (name == Config.notifyConfigChanged) ||
        ((name == Storage.notifySettingChanged) && (_defaultStorageKeys?.contains(param) == true))
      )
    {
      updateContent();
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      onAppLivecycleStateChanged(param);
    }
  }

  @protected
  void onAppLivecycleStateChanged(AppLifecycleState? state) {
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
    if (Config().assetsUrl != null) {
      Response? response = await Network().get("${Config().assetsUrl}/$netAssetFileName");
      return (response?.statusCode == 200) ? response?.body : null;
    }
    return null;
  }

  @protected
  Future<void> updateFromNet() async {
    String? netContentSourceString = await loadContentStringFromNet();
    Map<String, dynamic>? netContentSource = JsonUtils.decodeMap(netContentSourceString);
    if (((netContentSource != null) && !const DeepCollectionEquality().equals(netContentSource, _netContentSource)) ||
        ((netContentSource == null) && (_netContentSource != null)))
    {
      _netContentSource = netContentSource;
      await saveToCache(netCacheFileName, netContentSourceString);
      build();
      NotificationService().notify(notifyChanged, null);
    }
  }

  @protected
  Map<String, dynamic> buildContentSource() {
    Map<String, dynamic> contentSource = <String, dynamic>{};
    MapUtils.merge(contentSource, _defContentSource);
    MapUtils.merge(contentSource, _appContentSource);
    MapUtils.merge(contentSource, _netContentSource);
    return contentSource;
  }

  @protected
  Map<String, dynamic>? contentSourceEntry(String key) {
    return JsonUtils.mapValue(MapPathKey.entry(_contentSource, key));
  }

  @protected
  String get defaultContentSourceKey => _defaultContentSourceKey;

  @protected
  Map<String, dynamic>? get defaultContentSourceEntry {
    return contentSourceEntry(defaultContentSourceKey);
  }

  @protected
  void build() {
    _contentSource = buildContentSource();

    FlexUiBuildContext buildContext = FlexUiBuildContext();
    _defaultContent = buildContent(defaultContentSourceEntry, buildContext: buildContext);
    _sourceAttributes = buildAttributes(defaultSourceContent);

    _defaultFeatures = buildFeatures(_defaultContent);
    _defaultAttributes = buildAttributes(_defaultContent);
    _defaultStorageKeys = buildContext.storageKeys;
  }

  @protected
  void updateContent() {
    FlexUiBuildContext buildContext = FlexUiBuildContext();
    Map<String, dynamic>? defaultContent = buildContent(defaultContentSourceEntry, buildContext: buildContext);
    if (!const DeepCollectionEquality().equals(_defaultStorageKeys, buildContext.storageKeys)) {
      _defaultStorageKeys = buildContext.storageKeys;
    }
    if ((defaultContent != null) && ((_defaultContent == null) || !const DeepCollectionEquality().equals(_defaultContent, defaultContent))) {
      _defaultContent = defaultContent;

      _defaultFeatures = buildFeatures(_defaultContent);
      _defaultAttributes = buildAttributes(_defaultContent);
      NotificationService().notify(notifyChanged, null);
    }
  }

  @protected
  Set<dynamic>? buildFeatures(Map<String, dynamic>? content) {
    dynamic featuresList = (content != null) ? content[_featuresKey] : null;
    return (featuresList is Iterable) ? Set.from(featuresList) : null;
  }

  Map<String, Set<String>>? buildAttributes(Map<String, dynamic>? content) {
    Map<String, Set<String>>? attributesForScope;
    if (content != null) {
      List<String>? scopesList = JsonUtils.listStringsValue(content[_attributesKey]);
      if (scopesList != null) {
        attributesForScope = <String, Set<String>>{};
        for (String scope in scopesList) {
          Set<String>? scopeAttributes = JsonUtils.setStringsValue(content["$_attributesKey.$scope"]);
          if (scopeAttributes != null) {
            attributesForScope[scope] = scopeAttributes;
          }
        }
      }
    }
    return attributesForScope;
  }

  // Content

  Map<String, dynamic>? content(String key) {
    if (key == defaultContentSourceKey) {
      return _defaultContent;
    }
    else {
      return buildContent(contentSourceEntry(key, /* buildContext: we do not care about it for non default content */));
    }
  }

  Map<String, dynamic>? get defaultContent {
    return _defaultContent;
  }

  List<dynamic>? operator [](dynamic key) {
    return (_defaultContent != null) ? JsonUtils.listValue(_defaultContent![key]) : null;
  }

  Map<String, dynamic> get defaultSourceRules {
    return JsonUtils.mapValue(defaultContentSourceEntry?['rules']) ?? <String, dynamic>{};
  }

  Map<String, dynamic> get defaultSourceContent {
    return JsonUtils.mapValue(defaultContentSourceEntry?['content']) ?? <String, dynamic>{};
  }

  Set<dynamic>? get defaultFeatures {
    return _defaultFeatures;
  }

  bool hasFeature(String feature) {
    return (_defaultFeatures != null) && _defaultFeatures!.contains(feature);
  }

  Map<String, Set<String>>? get sourceAttributes => _sourceAttributes;
  Map<String, Set<String>>? get defaultAttributes => _defaultAttributes;

  bool isAttributeEnabled(String? attribute, { String? scope }) =>
    (attribute != null) && (scope != null) && !isAttributeDisabled(attribute, scope: scope);

  bool isAttributeDisabled(String attribute, { required String scope }) =>
    (_sourceAttributes?[scope]?.contains(attribute) == true) &&
    (_defaultAttributes?[scope]?.contains(attribute) == false);

  Future<void> update() async {
    return updateContent();
  }

  // Local Build

  @protected
  Map<String, dynamic>? buildContent(Map<String, dynamic>? contentSource, { FlexUiBuildContext? buildContext }) {
    Map<String, dynamic>? result;
    if (contentSource != null) {
      Map<String, dynamic> contents = JsonUtils.mapValue(contentSource['content']) ?? <String, dynamic>{};
      Map<String, dynamic> rules = JsonUtils.mapValue(contentSource['rules']) ?? <String, dynamic>{};

      result = {};
      contents.forEach((String key, dynamic contentEntry) {

        if (contentEntry is Map) {
          for (String contentEntryKey in contentEntry.keys) {
            if (localeIsEntryAvailable(contentEntryKey, group: key, rules: rules, buildContext: buildContext)) {
              contentEntry = contentEntry[contentEntryKey];
              break;
            }
          }
        }

        if (contentEntry is List) {
          List<String> resultList = <String>[];
          for (dynamic entry in contentEntry) {
            String? stringEntry = JsonUtils.stringValue(entry);
            if (stringEntry != null) {
              if (localeIsEntryAvailable(stringEntry, group: key, rules: rules, buildContext: buildContext)) {
                resultList.add(entry);
              }
            }
          }
          result![key] = resultList;
        }
        else {
          result![key] = contentEntry;
        }
      });
    }
    return result;
  }

  @protected
  bool localeIsEntryAvailable(String entry, { String? group, required Map<String, dynamic> rules, FlexUiBuildContext? buildContext }) {

    String? pathEntry = (group != null) ? '$group.$entry' : null;

    Map<String, dynamic>? roleRules = rules['roles'];
    dynamic roleRule = (roleRules != null) ? (((pathEntry != null) ? roleRules[pathEntry] : null) ?? roleRules[entry]) : null;
    if ((roleRule != null) && !localeEvalRoleRule(roleRule, buildContext: buildContext)) {
      return false;
    }

    Map<String, dynamic>? groupRules = rules['groups'];
    dynamic groupRule = (groupRules != null) ? (((pathEntry != null) ? groupRules[pathEntry] : null) ?? groupRules[entry]) : null;
    if ((groupRule != null) && !localeEvalGroupRule(groupRule, buildContext: buildContext)) {
      return false;
    }

    Map<String, dynamic>? locationRules = rules['locations'];
    dynamic locationRule = (locationRules != null) ? (((pathEntry != null) ? locationRules[pathEntry] : null) ?? locationRules[entry]) : null;
    if ((locationRule != null) && !localeEvalLocationRule(locationRule, buildContext: buildContext)) {
      return false;
    }

    Map<String, dynamic>? privacyRules = rules['privacy'];
    dynamic privacyRule = (privacyRules != null) ? (((pathEntry != null) ? privacyRules[pathEntry] : null) ?? privacyRules[entry]) : null;
    if ((privacyRule != null) && !localeEvalPrivacyRule(privacyRule, buildContext: buildContext)) {
      return false;
    }

    Map<String, dynamic>? authRules = rules['auth'];
    dynamic authRule = (authRules != null) ? (((pathEntry != null) ? authRules[pathEntry] : null) ?? authRules[entry])  : null;
    if ((authRule != null) && !localeEvalAuthRule(authRule, buildContext: buildContext)) {
      return false;
    }

    Map<String, dynamic>? platformRules = rules['platform'];
    dynamic platformRule = (platformRules != null) ? (((pathEntry != null) ? platformRules[pathEntry] : null) ?? platformRules[entry])  : null;
    if ((platformRule != null) && !localeEvalPlatformRule(platformRule, buildContext: buildContext)) {
      return false;
    }

    Map<String, dynamic>? enableRules = rules['enable'];
    dynamic enableRule = (enableRules != null) ? (((pathEntry != null) ? enableRules[pathEntry] : null) ?? enableRules[entry])  : null;
    if ((enableRule != null) && !localeEvalEnableRule(enableRule, buildContext: buildContext)) {
      return false;
    }

    return true;
  }

  @protected
  bool localeEvalRoleRule(dynamic roleRule, { FlexUiBuildContext? buildContext }) {
    return BoolExpr.eval(roleRule, (dynamic argument) {
      if (argument is String) {
        bool? not, all, any;
        if (not = argument.startsWith('~')) {
          argument = argument.substring(1);
        }
        if (all = argument.endsWith('!')) {
          argument = argument.substring(0, argument.length - 1);
        }
        else if (any = argument.endsWith('?')) {
          argument = argument.substring(0, argument.length - 1);
        }

        Set<UserRole>? userRoles = localeEvalRolesSetParam(argument, buildContext: buildContext);
        if (userRoles != null) {
          if (not == true) {
            userRoles = Set.from(UserRole.values).cast<UserRole>().difference(userRoles);
          }

          if (all == true) {
            return const DeepCollectionEquality().equals(Auth2().prefs?.roles, userRoles);
          }
          else if (any == true) {
            return Auth2().prefs?.roles?.intersection(userRoles).isNotEmpty ?? false;
          }
          else {
            return Auth2().prefs?.roles?.containsAll(userRoles) ?? false;
          }
        }
      }
      return null;
    });
  }

  @protected
  Set<UserRole>? localeEvalRolesSetParam(String? roleParam, { FlexUiBuildContext? buildContext }) {
    if (roleParam != null) {
      if (RegExp(r"\(.+\)").hasMatch(roleParam)) {
        Set<UserRole> roles = <UserRole>{};
        String rolesStr = roleParam.substring(1, roleParam.length - 1);
        List<String> rolesStrList = rolesStr.split(',');
        for (String roleStr in rolesStrList) {
          UserRole? role = UserRole.fromString(roleStr.trim());
          if (role != null) {
            roles.add(role);
          }
        }
        return roles;
      }
      else if (RegExp(r"\${.+}").hasMatch(roleParam)) {
        String stringRef = roleParam.substring(2, roleParam.length - 1);
        String? stringRefValue = JsonUtils.stringValue(localeEvalStringReference(stringRef, buildContext: buildContext));
        return localeEvalRolesSetParam(stringRefValue, buildContext: buildContext);
      }
      else {
        UserRole? userRole = UserRole.fromString(roleParam);
        return (userRole != null) ? { userRole } : null;
      }
    }
    return null;
  }

  @protected
  bool localeEvalGroupRule(dynamic groupRule, { FlexUiBuildContext? buildContext }) =>
    localeEvalStringsSetExpr(groupRule, Groups().userGroupNames, buildContext: buildContext);

  @protected
  bool localeEvalLocationRule(dynamic locationRule, { FlexUiBuildContext? buildContext }) =>
    localeEvalStringsSetExpr(locationRule, GeoFence().currentRegionIds, buildContext: buildContext);

  @protected
  bool localeEvalStringsSetExpr(dynamic rule, Set<String>? allStrings, { FlexUiBuildContext? buildContext }) {
    return BoolExpr.eval(rule, (dynamic argument) {
      if (argument is String) {
        bool? not, all, any;
        if (not = argument.startsWith('~')) {
          argument = argument.substring(1);
        }
        if (all = argument.endsWith('!')) {
          argument = argument.substring(0, argument.length - 1);
        }
        else if (any = argument.endsWith('?')) {
          argument = argument.substring(0, argument.length - 1);
        }

        Set<String>? targetStrings = localeEvalStringsSetParam(argument, buildContext: buildContext);
        if (targetStrings != null) {
          if (not == true) {
            targetStrings = allStrings?.difference(targetStrings) ?? <String>{};
          }

          if (all == true) {
            return const DeepCollectionEquality().equals(allStrings, targetStrings);
          }
          else if (any == true) {
            return allStrings?.intersection(targetStrings).isNotEmpty == true;
          }
          else {
            return allStrings?.containsAll(targetStrings) == true;
          }
        }
      }
      return null;
    });
  }

  @protected
  Set<String>? localeEvalStringsSetParam(String? stringParam, { FlexUiBuildContext? buildContext }) {
    if (stringParam != null) {
      if (RegExp(r"\(.+\)").hasMatch(stringParam)) {
        String stringsStr = stringParam.substring(1, stringParam.length - 1);
        return Set<String>.from(stringsStr.split(',').map((e) => e.trim()));
      }
      else if (RegExp(r"\${.+}").hasMatch(stringParam)) {
        String stringRef = stringParam.substring(2, stringParam.length - 1);
        String? stringRefValue = JsonUtils.stringValue(localeEvalStringReference(stringRef, buildContext: buildContext));
        return localeEvalStringsSetParam(stringRefValue, buildContext: buildContext);
      }
      else {
        return <String>{ stringParam };
      }
    }
    return null;
  }

  @protected
  bool localeEvalPrivacyRule(dynamic privacyRule, { FlexUiBuildContext? buildContext }) {
    return (privacyRule is int) ? Auth2().privacyMatch(privacyRule) : true; // allow everything that is not defined or we do not understand
  }

  @protected
  bool localeEvalAuthRule(dynamic authRule, { FlexUiBuildContext? buildContext }) {
    return BoolExpr.eval(authRule, (dynamic argument) => localeEvalAuthRuleParam(argument, buildContext: buildContext));
  }

  bool? localeEvalAuthRuleParam(dynamic authParam, { FlexUiBuildContext? buildContext }) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (authParam is Map) {
      authParam.forEach((dynamic key, dynamic value) {
        if (key is String) {
          if ((key == 'loggedIn') && (value is bool)) {
            result = result && (Auth2().isLoggedIn == value);
          }
          else if ((key == 'shibbolethLoggedIn') && (value is bool)) {
            result = result && (Auth2().isOidcLoggedIn == value);
          }
          else if ((key == 'phoneLoggedIn') && (value is bool)) {
            result = result && (Auth2().isPhoneLoggedIn == value);
          }
          else if ((key == 'emailLoggedIn') && (value is bool)) {
            result = result && (Auth2().isEmailLoggedIn == value);
          }
          else if ((key == 'usernameLoggedIn') && (value is bool)) {
            result = result && (Auth2().isUsernameLoggedIn == value);
          }
          else if ((key == 'phoneOrEmailLoggedIn') && (value is bool)) {
            result = result && ((Auth2().isPhoneLoggedIn || Auth2().isEmailLoggedIn) == value) ;
          }
          else if ((key == 'shibbolethLinked') && (value is bool)) {
            result = result && (Auth2().isOidcLinked == value);
          }
          else if ((key == 'phoneLinked') && (value is bool)) {
            result = result && (Auth2().isPhoneLinked == value);
          }
          else if ((key == 'emailLinked') && (value is bool)) {
            result = result && (Auth2().isEmailLinked == value);
          }
          else if ((key == 'usernameLinked') && (value is bool)) {
            result = result && (Auth2().isUsernameLinked == value);
          }
          else if (key == 'accountRole') {
            result = result && localeEvalAccountRole(value, buildContext: buildContext);
          }
          else if (key == 'accountPermission') {
            result = result && localeEvalAccountPermission(value, buildContext: buildContext);
          }
          else if ((key == 'shibbolethMemberOf') && (value is String)) {
            result = result && Auth2().isShibbolethMemberOf(value);
          }
          else if ((key == 'eventEditor') && (value is bool)) {
            result = result && (Auth2().isEventEditor == value);
          }
          else if ((key == 'stadiumPollManager') && (value is bool)) {
            result = result && (Auth2().isStadiumPollManager == value);
          }
        }
      });
    }
    return result;
  }

  @protected
  bool localeEvalAccountRole(dynamic accountRoleRule, { FlexUiBuildContext? buildContext }) =>
    localeEvalStringsSetExpr(accountRoleRule, Auth2().account?.allRoleNames, buildContext: buildContext);

  @protected
  bool localeEvalAccountPermission(dynamic accountPermissionRule, { FlexUiBuildContext? buildContext } ) =>
    localeEvalStringsSetExpr(accountPermissionRule, Auth2().account?.allPermissionNames, buildContext: buildContext);

  @protected
  bool localeEvalPlatformRule(dynamic platformRule, { FlexUiBuildContext? buildContext }) {
    bool result = true;  // allow everything that is not defined or we do not understand
    if (platformRule is Map) {
      platformRule.forEach((dynamic key, dynamic value) {
        if (key is String) {
          String? target;
          if (key == 'os') {
            target = Platform.operatingSystem;
          }
          else if (key == 'environment') {
            target = configEnvToString(Config().configEnvironment);
          }
          else if (key == 'build') {
            if (kReleaseMode) {
              target = 'release';
            }
            else if (kProfileMode) {
              target = 'profile';
            }
            else if (kDebugMode) {
              target = 'debug';
            }
          }

          if (target != null) {
            if (value is List) {
              result = result && value.contains(target);
            }
            else if (value is String) {
              result = result && (value == target);
            }
          }
        }
      });
    }
    return result;
  }

  @protected
  bool localeEvalEnableRule(dynamic enableRule, { FlexUiBuildContext? buildContext }) {
    return BoolExpr.eval(enableRule, (dynamic argument) {
      return localeEvalBoolParam(argument, buildContext: buildContext);
    });
  }

  @protected
  bool? localeEvalBoolParam(dynamic stringParam, { FlexUiBuildContext? buildContext }) {
    if (stringParam is String) {
      if (RegExp(r"\${.+}").hasMatch(stringParam)) {
        String stringRef = stringParam.substring(2, stringParam.length - 1);
        return JsonUtils.boolValue(localeEvalStringReference(stringRef, buildContext: buildContext));
      }
    }
    return null;
  }

  // External Refs

  @protected
  String get configReferenceKey => 'config';
  String get appStorageReferenceKey => 'app.storage';

  @protected
  dynamic localeEvalStringReference(String? stringRef, { FlexUiBuildContext? buildContext }) {
    if (stringRef != null) {
      String configPrefix = '$configReferenceKey${MapPathKey.pathDelimiter}';
      if (stringRef.startsWith(configPrefix)) {
        return Config().pathEntry(stringRef.substring(configPrefix.length));
      }
      String appPrefix = '$appStorageReferenceKey${MapPathKey.pathDelimiter}';
      if (stringRef.startsWith(appPrefix)) {
        String storageKey = stringRef.substring(appPrefix.length);
        buildContext?.storageKeys.add(storageKey);
        return Storage()[storageKey];
      }
    }
    return null;
  }

}

class FlexUiBuildContext {
  final Set<String> storageKeys; // referenced storage keys from data source

  FlexUiBuildContext({
    Set<String>? storageKeys,
  }) :
    this.storageKeys = storageKeys ?? <String>{};
}