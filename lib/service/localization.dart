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

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:http/http.dart' as http;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_io/io.dart';

class Localization with Service, NotificationsListener {
  
  // Notifications
  static const String notifyLocaleChanged   = "edu.illinois.rokwire.localization.locale.updated";
  static const String notifyStringsUpdated  = "edu.illinois.rokwire.localization.strings.updated";

  // Singletone Factory
  static Localization? _instance;

  static Localization? get instance => _instance;
  
  @protected
  static set instance(Localization? value) => _instance = value;

  factory Localization() => _instance ?? (_instance = Localization.internal());

  @protected
  Localization.internal();

  // Multilanguage support
  final List<String> defaultSupportedLanguages = ['en', 'es', 'zh'];
  List<String> get supportedLanguages => (Config().supportedLocales?.isNotEmpty == true) ? (JsonUtils.listStringsValue(Config().supportedLocales) ?? defaultSupportedLanguages) : defaultSupportedLanguages;
  Iterable<Locale> supportedLocales() => supportedLanguages.map<Locale>((language) => Locale(language, ""));  

  // Data
  Directory? _assetsDir;
  
  Locale? _defaultLocale;
  Map<String, dynamic>? _defaultStrings;
  Map<String, dynamic>? _defaultAssetsStrings;
  Map<String, dynamic>? _defaultAppAssetsStrings;
  Map<String, dynamic>? _defaultNetStrings;
  
  Locale? _systemLocale;
  Locale? _selectedLocale;
  Locale? _currentLocale;
  Map<String, dynamic>? _localeStrings;
  Map<String, dynamic>? _localeAssetsStrings;
  Map<String, dynamic>? _localeAppAssetsStrings;
  Map<String, dynamic>? _localeNetStrings;

  DateTime?  _pausedDateTime;

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
    
    String defaultLanguage = supportedLanguages[0];
    _defaultLocale = Locale.fromSubtags(languageCode : defaultLanguage);
    await initDefaultStrings(defaultLanguage);

    String? systemLanguage = Storage().systemLanguage;
    _systemLocale = (systemLanguage != null) ? Locale(systemLanguage) : null;

    String? selectedLanguage = Storage().selectedLanguage;
    _selectedLocale = (selectedLanguage != null) ? Locale(selectedLanguage) : null;

    String? currentLanguage = selectedLanguage ?? systemLanguage;
    if ((currentLanguage != null) && (currentLanguage != defaultLanguage)) {
      _currentLocale = Locale(currentLanguage);
      await initLocaleStrings(currentLanguage);
    }

    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config() };
  }

  // Locale

  Locale? get defaultLocale => _defaultLocale;

  Locale? get systemLocale => _systemLocale;
  set systemLocale(Locale? value) => setSystemLocaleAsync(value);

  Future<void> setSystemLocaleAsync(Locale? value) async {
    if (value?.languageCode != _systemLocale?.languageCode) {
      _systemLocale = value;
      Storage().systemLanguage = value?.languageCode;
      await _updateLocaleStrings(_selectedLocale ?? _systemLocale);
    }
  }

  Locale? get selectedLocale => _selectedLocale;
  set selectedLocale(Locale? value) => setSelectedLocaleAsync(value);

  Future<void> setSelectedLocaleAsync(Locale? value) async {
    if (value?.languageCode != _selectedLocale?.languageCode) {
      _selectedLocale = value;
      Storage().selectedLanguage = value?.languageCode;
      await _updateLocaleStrings(_selectedLocale ?? _systemLocale);
    }
  }

  Locale? get currentLocale => _currentLocale;

  Future<void> _updateLocaleStrings(Locale? value) async {
    if ((value == null) || (value.languageCode == _defaultLocale?.languageCode)) {
      if (_currentLocale != null) {
        // use default
        _currentLocale = null;
        _localeStrings = _localeAssetsStrings = _localeNetStrings = null;
        // Notyfy when we change the locale (valid change)
        NotificationService().notify(notifyLocaleChanged, null);
      }
    }
    else if (_currentLocale?.languageCode != value.languageCode) {
      // use value
      _currentLocale = value;
      await initLocaleStrings(value.languageCode);
      // Notyfy when we change the locale (valid change)
      NotificationService().notify(notifyLocaleChanged, null);
    }
  }

  // Load / Update

  @protected
  Future<Directory?> getAssetsDir() async {
    Directory? assetsDir = Config().assetsCacheDir;
    if ((assetsDir != null) && !await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return assetsDir;
  }

  @protected
  Future<void> initDefaultStrings(String language) async {
    _defaultStrings = _buildStrings(
      asset: _defaultAssetsStrings = await loadAssetsStrings(language),
      appAsset: _defaultAppAssetsStrings = kIsWeb ? null : await loadAssetsStrings(language, app: true),
      net: _defaultNetStrings = await loadNetStringsFromCache(language));
    updateDefaultStrings();
  }

  @protected
  Future<void> initLocaleStrings(String language) async {
    _localeStrings = _buildStrings(
      asset: _localeAssetsStrings = await loadAssetsStrings(language),
      appAsset: _localeAppAssetsStrings = kIsWeb ? null : await loadAssetsStrings(language, app: true),
      net: _localeNetStrings = await loadNetStringsFromCache(language));
    updateLocaleStrings();
  }

  @protected
  String getResourceAssetsKey(String language, { bool app = false }) => app ? 'app/assets/strings.$language.json' : 'assets/strings.$language.json';

  @protected
  Future<String?> loadResourceAssetsJsonString(String language, { bool app = false }) => rootBundle.loadString(getResourceAssetsKey(language, app: app));

  @protected
  Future<Map<String, dynamic>?> loadAssetsStrings(String language, { bool app = false }) async {
    dynamic jsonData;
    try {jsonData = JsonUtils.decode(await loadResourceAssetsJsonString(language, app: app)); }
    catch (e) { debugPrint(e.toString()); }
    return ((jsonData != null) && (jsonData is Map<String,dynamic>)) ? jsonData : null;
  }

  @protected
  String getCacheFileName(String language) => 'strings.$language.json';

  @protected
  String? getCacheFilePath(String language) => (_assetsDir != null) ? join(_assetsDir!.path, getCacheFileName(language)) : null;

  @protected
  Future<Map<String,dynamic>?> loadNetStringsFromCache(String language) async {
    dynamic jsonData;
    try { 
      String? cacheFilePath = getCacheFilePath(language);
      File? cacheFile = (cacheFilePath != null) ? File(cacheFilePath) : null;
      
      String? jsonString = ((cacheFile != null) && await cacheFile.exists()) ? await cacheFile.readAsString() : null;
      jsonData = JsonUtils.decode(jsonString);
    } catch (e) { debugPrint(e.toString()); }
    return ((jsonData != null) && (jsonData is Map<String,dynamic>)) ? jsonData : null;
  }

  @protected
  void updateDefaultStrings() {
    if (_defaultLocale != null) {
      _updateStringsFromNet(_defaultLocale!.languageCode, cache: _defaultNetStrings).then((Map<String,dynamic>? update) {
        if (update != null) {
          _defaultStrings = _buildStrings(asset: _defaultAssetsStrings, appAsset: _defaultAppAssetsStrings, net: _defaultNetStrings = update);
          NotificationService().notify(notifyStringsUpdated, null);
        }
      });
    }
  }

  @protected
  Future<void> updateLocaleStrings() async {
    if (_currentLocale != null) {
      final String requestedLocale = _currentLocale!.languageCode;
      Map<String,dynamic>? update = await _updateStringsFromNet(_currentLocale!.languageCode, cache: _localeNetStrings);
      if (update != null && (requestedLocale == _currentLocale?.languageCode)) { // Sync: If the locale was not changed while update was in process
        _localeStrings = _buildStrings(asset: _localeAssetsStrings, appAsset: _localeAppAssetsStrings, net: _localeNetStrings = update);
        NotificationService().notify(notifyStringsUpdated, null);
      }
    }
  }

  @protected
  String getNetworkAssetName(String language) => 'strings.$language.json';

  Future<Map<String,dynamic>?> _updateStringsFromNet(String language, { Map<String, dynamic>? cache }) async {
    Map<String, dynamic>? jsonData;
    try {
      String assetName = getNetworkAssetName(language);
      http.Response? response = StringUtils.isNotEmpty(Config().assetsUrl) ? await Network().get("${Config().assetsUrl}/$assetName") : null;
      String? jsonString = ((response != null) && (response.statusCode == 200)) ? response.body : null;
      jsonData = (jsonString != null) ? JsonUtils.decode(jsonString) : null;
      if ((jsonString != null) && (jsonData != null) && ((cache == null) || !const DeepCollectionEquality().equals(jsonData, cache))) {
        String? cacheFilePath = (_assetsDir != null) ? join(_assetsDir!.path, assetName) : null;
        File? cacheFile = (cacheFilePath != null) ? File(cacheFilePath) : null;
        if (cacheFile != null) {
          await cacheFile.writeAsString(jsonString, flush: true);
        }
        return jsonData;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  static Map<String, dynamic> _buildStrings({ Map<String, dynamic>? asset, Map<String, dynamic>? appAsset, Map<String, dynamic>? net}) {
    Map<String, dynamic> strings = <String, dynamic>{};
    if ((asset != null) && asset.isNotEmpty) {
      strings.addAll(asset);
    }
    if ((appAsset != null) && appAsset.isNotEmpty) {
      strings.addAll(appAsset);
    }
    if ((net != null) && net.isNotEmpty) {
      strings.addAll(net);
    }
    return strings;
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
    if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          updateDefaultStrings();
          updateLocaleStrings();
        }
      }
    }
  }

  // Strings 

  String? getString(String? key, {String? defaults, String? language}) {
    dynamic value;
    if ((_localeStrings != null) && ((language == null) || (language == _currentLocale?.languageCode))) {
      value = _localeStrings![key];
    }
    if ((value == null) && (_defaultStrings != null) && ((language == null) || (language == _defaultLocale?.languageCode))) {
      value = _defaultStrings![key];
    }
    return ((value != null) && (value is String)) ? value : defaults;
  }

  String getStringEx(String key, String defaults, {String? language})  {
    return getString(key, language: language) ?? defaults;
  }

  String? getContentString(Map<String, dynamic>? strings, String? key, {String? languageCode}) {
    if ((strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(strings[languageCode]) ??
        JsonUtils.mapValue(strings[_currentLocale?.languageCode]) ??
        JsonUtils.mapValue(strings[_defaultLocale?.languageCode]);
      if (mapping != null) {
        return JsonUtils.stringValue(mapping[key]);
      }
    }
    return null;
  }

  String? getStringFromMapping(String? text, Map<String, dynamic>? stringsMap) {
    if ((text != null) && (stringsMap != null)) {
      String? entry;
      if ((entry = _getStringFromLanguageMapping(text, stringsMap[_currentLocale?.languageCode])) != null) {
        return entry;
      }
      if ((entry = _getStringFromLanguageMapping(text, stringsMap[_defaultLocale?.languageCode])) != null) {
        return entry;
      }
    }
    return text;
  }

  String? getStringFromKeyMapping(String? key, Map<String, dynamic>? stringsMap, {String defaults = ''}) {
    String? text;
    if (StringUtils.isNotEmpty(key)) {
      //1. Get text value from assets
      text = Localization().getStringFromMapping(key, stringsMap); // returns 'key' if text is not found
      //2. If there is no text for this key then get text value from strings
      if (StringUtils.isEmpty(text) || text == key) {
        text = Localization().getString(key, defaults: defaults);
      }
    }
    return StringUtils.ensureNotEmpty(text, defaultValue: defaults);
  }

  static String? _getStringFromLanguageMapping(String text, Map<String, dynamic>? languageMap) {
    if (languageMap is Map) {
      String? languageTextEntry = languageMap![text];
      if (languageTextEntry is String) {
        return languageTextEntry;
      }
    }
    return null;
  }
}

class AppLocalizations {
  Locale? locale;
  
  AppLocalizations(Locale locale) {
    Localization().systemLocale = this.locale = locale;
  }
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {

  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return Localization().supportedLanguages.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return true;
  }
}