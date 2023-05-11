// Copyright 2023 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/alert.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/local_notifications.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/popups/alerts.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Rules service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Rules {

  // Singletone Factory

  static Rules? _instance;

  static Rules? get instance => _instance;

  @protected
  static set instance(Rules? value) => _instance = value;

  factory Rules() => _instance ?? (_instance = Rules.internal());

  @protected
  Rules.internal();

  // Engine
  final Map<String, Map<String, List<RuleData>>> _dataCache = {};

  void clearDataCache(String id) {
    _dataCache[id]?.forEach((_, data) { data.clear(); });
  }

  void evaluateRules(RuleEngine engine, List<Rule> rules, {bool clearCache = true}) {
    if (clearCache) {
      clearDataCache(engine.id);
    }
    RuleActionResult? topAction;
    for (Rule rule in rules) {
      try {
        RuleActionResult? action = evaluateRule(engine, rule);
        if (action != null && (topAction == null || (topAction.priority ?? 0) < (action.priority ?? 0))) {
          topAction = action;
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    }

    if (topAction is RuleAction) {
      evaluateAction(engine, topAction);
    } else if (topAction is RuleActionList) {
      for (RuleAction action in topAction.actions) {
        evaluateAction(engine, action);
      }
    }
  }

  dynamic _getEngineVal(RuleEngine engine, String? key, dynamic param) {
    if (key == null) {
      return null;
    }

    if (_dataCache[engine.id] == null) {
      _dataCache[engine.id] = {};
    }
    List<RuleData> cached = _dataCache[engine.id]![key] ?? [];
    for (RuleData data in cached.reversed) {
      if (data.match(param)) {
        return data.value;
      }
    }

    // dynamic val = getValDirect(key, param);
    // if (val != null) {
    //   cached.add(RuleData(value: val, param: param));
    //   _dataCache[key] = cached;
    // }

    param = _getEngineValOrCollection(engine, param);

    RuleKey ruleKey = RuleKey.fromKey(key);
    switch (ruleKey.key) {
      case "literal":
        _dataCache[engine.id]![key]?.add(RuleData(value: ruleKey.subKey, param: param));
        return ruleKey.subKey;
      case "constants":
        if (ruleKey.subKey != null) {
          dynamic constVal = engine.constants[ruleKey.subKey!];
          _dataCache[engine.id]![key]?.add(RuleData(value: constVal, param: param));
          return constVal;
        }
        return null;
      case "strings":
        if (ruleKey.subKey != null) {
          String? stringVal = _interpolateEngineString(engine, _localeString(engine, ruleKey.subKey!));
          _dataCache[engine.id]![key]?.add(RuleData(value: stringVal, param: param));
          return stringVal;
        }
        return null;
      case "current_time":
        return DateTime.now();
      case "current_time_offset":
        Duration offset = JsonUtils.durationValue(param) ?? const Duration();
        return DateTime.now().subtract(offset);
      default:
        return engine is Survey ? Surveys().getProperty(engine, ruleKey) : getEngineProperty(ruleKey);
    }
  }

  dynamic _getEngineValOrCollection(RuleEngine engine, dynamic data) {
    if (data is String) {
      return _getEngineVal(engine, data, null);
    } else if (data is Map<String, dynamic>) {
      Map<String, dynamic> out = {};
      for (MapEntry<String, dynamic> entry in data.entries) {
        if (entry.value is String) {
          out[entry.key] = _getEngineVal(engine, entry.value, null);
        } else {
          out[entry.key] = _getEngineValOrCollection(engine, entry.value);
        }
      }
      return out;
    } else if (data is List<dynamic>) {
      List<dynamic> out = [];
      for (int i = 0; i < data.length; i++) {
        if (data[i] is String) {
          out.add(_getEngineVal(engine, data[i], null));
        } else {
          out.add(_getEngineValOrCollection(engine, data[i]));
        }
      }
      return out;
    }
    return data;
  }

  String _localeString(RuleEngine engine, String key) {
    String? currentLanguage = Localization().currentLocale?.languageCode;
    Map<String, String>? currentLanguageStrings = (currentLanguage != null) ? engine.strings[currentLanguage] : null;
    dynamic currentResult = (currentLanguageStrings != null) ? currentLanguageStrings[key] : null;
    if (currentResult != null) {
      return currentResult;
    }

    String? defaultLanguage = Localization().defaultLocale?.languageCode;
    Map<String, String>? defaultLanguageStrings = (defaultLanguage != null) ? engine.strings[defaultLanguage] : null;
    dynamic defaultResult = (defaultLanguageStrings != null) ? defaultLanguageStrings[key] : null;
    if (defaultResult is String) {
      return defaultResult;
    }

    return Localization().getString(key) ?? key;
  }

  /*
  String? stringValue(String? string) {
    if (string == null) {
      return null;
    }

    dynamic val = getVal(string, null);
    if (val is String) {
      return interpolateString(val);
    }
    return interpolateString(string);
  }
  */

  String? _interpolateEngineString(RuleEngine engine, String? string) {
    if (string == null) {
      return null;
    }

    RegExp regExp = RegExp(r"%{(.*?)}");
    for (Match match in regExp.allMatches(string)) {
      String? full = match.group(0);
      String? key = match.group(1);

      if (full != null && key != null){
        List<String> parts = key.split(",");
        String val;
        if (parts.length == 2) {
          val = _getDisplayVal(engine, parts[0], parts[1]);
        } else {
          val = _getDisplayVal(engine, key, null);
        }
        string = string?.replaceFirst(full, val);
      }
    }
    return string;
  }

  String _getDisplayVal(RuleEngine engine, String key, String? param) {
    dynamic val = _getEngineVal(engine, key, param);
    if (val is DateTime) {
      return AppDateTime().getDisplayDateTime(val, format: param, considerSettingsDisplayTime: false);
    }
    return val.toString();
  }

  // Comparison

  bool evaluateComparison(RuleEngine engine, RuleComparison comparison) {
    dynamic dataVal = _getEngineVal(engine, comparison.dataKey, comparison.dataParam);

    dynamic compareToVal = comparison.compareTo;
    if (compareToVal is String) {
      compareToVal = _getEngineVal(engine, comparison.compareTo, comparison.compareToParam);
    }
    return _compare(comparison.operator, dataVal, compareToVal, comparison.defaultResult ?? false);
  }

  bool _compare(String operator, dynamic val, dynamic ruleVal, bool defaultResult) {
    try {
      switch (operator) {
        case "<":
          if (val is DateTime && ruleVal is DateTime) {
            return val.isBefore(ruleVal);
          }
          return val < ruleVal;
        case ">":
          if (val is DateTime && ruleVal is DateTime) {
            return val.isAfter(ruleVal);
          }
          return ruleVal < val;
        case "<=":
          return val <= ruleVal;
        case ">=":
          return ruleVal <= val;
        case "==":
          if (val is DateTime && ruleVal is DateTime) {
            return val.isAtSameMomentAs(ruleVal);
          }
          return val == ruleVal;
        case "!=":
          if (val is DateTime && ruleVal is DateTime) {
            return !val.isAtSameMomentAs(ruleVal);
          }
          return val != ruleVal;
        case "in_range":
          //TODO: implement
          return defaultResult;
        case "any":
          if (ruleVal is Iterable) {
            return ListUtils.contains(ruleVal.toList(), val) ?? false;
          }
          if (val is Iterable) {
            return ListUtils.contains(val.toList(), ruleVal) ?? false;
          }
          return val == ruleVal;
        case "all":
          if (ruleVal is Iterable) {
            return ListUtils.contains(ruleVal.toList(), val, checkAll: true) ?? false;
          }
          if (val is Iterable) {
            return ListUtils.contains(val.toList(), ruleVal, checkAll: true) ?? false;
          }
          return val == ruleVal;
        default:
          return defaultResult;
      }
    } catch(e) {
      return defaultResult;
    }
  }

  // Logic

  bool evaluateLogic(RuleEngine engine, RuleLogic logic) {
    bool defaultResult = (logic.operator == "and");
    for (RuleCondition subCondition in logic.conditions) {
      if (logic.operator == "and") {
        if (subCondition is RuleLogic) {
          if (!evaluateLogic(engine, subCondition)) {
            return false;
          }
        } else if (subCondition is RuleComparison) {
          if (!evaluateComparison(engine, subCondition)) {
            return false;
          }
        }
        return false;
      } else if (logic.operator == "or") {
        if (subCondition is RuleLogic) {
          if (evaluateLogic(engine, subCondition)) {
            return true;
          }
        } else if (subCondition is RuleComparison) {
          if (evaluateComparison(engine, subCondition)) {
            return true;
          }
        }
        return false;
      }
    }
    return defaultResult;
  }

  // RuleResult

  dynamic evaluateRuleResult(RuleEngine engine, RuleResult result, {bool summarize = false}) {
    if (result is RuleReference) {
      Rule? subRule = engine.subRules[result.ruleKey];
      if (subRule != null) {
        return evaluateRule(engine, subRule, summarize: summarize);
      }
    } else if (result is Rule) {
      return evaluateRule(engine, result, summarize: summarize);
    } else if (result is RuleCases) {
      for (Rule rule in result.cases) {
        dynamic caseResult = evaluateRule(engine, rule, summarize: summarize);
        if (caseResult != null) {
          return caseResult;
        }
      }
    } else if (result is RuleAction) {
      return evaluateAction(engine, result, summarize: summarize);
    } else if (result is RuleActionList) {
      List<dynamic> actionResults = [];
      for (RuleAction action in result.actions) {
        actionResults.add(evaluateAction(engine, action, summarize: summarize));
      }
      return actionResults;
    }

    return null;
  }

  // Action

  dynamic evaluateAction(RuleEngine engine, RuleAction action, {bool summarize = false}) {
    if (summarize) {
      return action.getSummary();
    }
    switch (action.action) {
      case "return":
        return _return(engine, action);
      case "show":
        return _return(engine, action);
      case "set_to":
        return _return(engine, action);
      case "sum":
        return _sum(engine, action);
      case "set_result":
        _setResult(engine, action);
        return null;
      case "show_survey":
        //TODO: fix this (should use notification like alert)
      case "alert":
        _alert(engine, action);
        return null;
      case "alert_result":
        _alert(engine, action);
        _setResult(engine, action);
        return null;
      case "notify":
        return _notify(engine, action);
      case "save":
        return (engine is Survey) ? Surveys().createSurveyResponse(engine) : null;
      case "local_notify":
        return _localNotify(engine, action);
    }
    return null;
  }

  dynamic _return(RuleEngine engine, RuleAction action) {
    return _getEngineValOrCollection(engine, action.data);
  }

  dynamic _sum(RuleEngine engine, RuleAction action) {
    dynamic evaluatedData = _getEngineValOrCollection(engine, action.data);
    if (action.data is List<dynamic>) {
      num sum = 0;
      for (dynamic item in evaluatedData) {
        if (item is num) {
          sum += item;
        }
      }
      return sum;
    } else if (action.data is num) {
      return action.data;
    }
    return null;
  }

  void _setResult(RuleEngine engine, RuleAction action) {
    if (engine.resultData is Map && action.dataKey != null) {
      engine.resultData[action.dataKey] = _getEngineValOrCollection(engine, action.data);
    } else if (action.dataKey != null) {
      engine.resultData = <String, dynamic>{action.dataKey!: _getEngineValOrCollection(engine, action.data)};
    } else {
      engine.resultData = _getEngineValOrCollection(engine, action.data);
    }
  }

  void _alert(RuleEngine engine, RuleAction action) {
    dynamic alertData = _getEngineValOrCollection(engine, action.data);
    if (alertData is SurveyDataResult) {
      NotificationService().notify(Alerts.notifyAlert, Alert(title: alertData.text, text: alertData.moreInfo, actions: alertData.actions));
    } else if (alertData is Alert) {
      NotificationService().notify(Alerts.notifyAlert, alertData);
    }
  }

  Future<bool> _notify(RuleEngine engine, RuleAction action) {
    dynamic notificationData = _getEngineValOrCollection(engine, action.data);
    if (notificationData is Map<String, dynamic>) {
      SurveyAlert alert = SurveyAlert.fromJson(notificationData);
      return Surveys().createSurveyAlert(alert);
    }
    return Future<bool>.value(false);
  }

  Future<bool> _localNotify(RuleEngine engine, RuleAction action) {
    dynamic resolvedData = _getEngineValOrCollection(engine, action.data);
    if (resolvedData is Map<String, dynamic>) {
      Alert alert = Alert.fromJson(resolvedData, engineId: engine.id);
      if (alert.timeToAlert != null) {
        return LocalNotifications().zonedSchedule("${engine.type}.${engine.id}",
          title: alert.title,
          message: alert.text,
          payload: JsonUtils.encode(alert.actions),
          dateTime: DateTime.now().add(alert.timeToAlert!)
        );
      }
    }
    
    return Future<bool>.value(false);
  }

  // Rule

  dynamic evaluateRule(RuleEngine engine, Rule rule, {bool summarize = false}) {
    RuleResult? result;
    if (rule.condition == null) {
      result = rule.trueResult;
    } else if (rule.condition! is RuleComparison && evaluateComparison(engine, rule.condition! as RuleComparison)) {
      result = rule.trueResult;
    } else if (rule.condition! is RuleLogic && evaluateLogic(engine, rule.condition! as RuleLogic)) {
      result = rule.trueResult;
    } else {
      result = rule.falseResult;
    }

    return result != null ? evaluateRuleResult(engine, result, summarize: summarize) : null;
  }

  // Property getters
  dynamic getEngineProperty(RuleKey? key) {
    switch (key?.key) {
      case "auth":
        return getServiceProperty(key?.subRuleKey);
    }
    return key?.toString();
  }

  dynamic getServiceProperty(RuleKey? key) {
    switch (key?.key) {
      case "uin":
        return Auth2().uin;
      case "net_id":
        return Auth2().netId;
      case "email":
        return Auth2().email;
      case "phone":
        return Auth2().phone;
      case "login_type":
        return Auth2().loginType != null ? auth2LoginTypeToString(Auth2().loginType!) : null;
      case "full_name":
        return Auth2().fullName;
      case "first_name":
        return Auth2().firstName;
      case "profile":
        return _auth2UserProfileGetProperty(key?.subRuleKey);
      case "preferences":
        return _auth2UserPrefsGetProperty(key?.subRuleKey);
      case "permissions":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().account?.hasPermission(subKey);
        }
        return Auth2().account?.permissions;
      case "roles":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().account?.hasRole(subKey);
        }
        return Auth2().account?.roles;
      case "groups":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().account?.belongsToGroup(subKey);
        }
        return Auth2().account?.groups;
      case "system_configs":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().account?.systemConfigs?[subKey];
        }
        return Auth2().account?.systemConfigs;
      case "is_logged_in":
        return Auth2().isLoggedIn;
      case "is_oidc_logged_in":
        return Auth2().isOidcLoggedIn;
      case "is_email_logged_in":
        return Auth2().isEmailLoggedIn;
      case "is_phone_logged_in":
        return Auth2().isPhoneLoggedIn;
    }
    return null;
  }

  dynamic _auth2UserProfileGetProperty(RuleKey? key) {
    switch (key?.key) {
      case "first_name":
        return Auth2().profile?.firstName;
      case "middle_name":
        return Auth2().profile?.middleName;
      case "last_name":
        return Auth2().profile?.lastName;
      case "birth_year":
        return Auth2().profile?.birthYear;
      case "photo_url":
        return Auth2().profile?.photoUrl;
      case "email":
        return Auth2().profile?.email;
      case "phone":
        return Auth2().profile?.phone;
      case "address":
        return Auth2().profile?.address;
      case "state":
        return Auth2().profile?.state;
      case "zip":
        return Auth2().profile?.zip;
      case "country":
        return Auth2().profile?.country;
      case "data":
        return Auth2().profile?.data?[key?.subRuleKey];
    }
    return null;
  }

  dynamic _auth2UserPrefsGetProperty(RuleKey? key) {
    switch (key?.key) {
      case "privacy_level":
        return Auth2().prefs?.privacyLevel;
      case "roles":
        return Auth2().prefs?.roles;
      case "favorites":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().prefs?.getFavorites(subKey);
        }
        return null;
      case "interests":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().prefs?.getInterestsFromCategory(subKey);
        }
        return null;
      case "food_filters":
        switch (key?.subRuleKey?.key) {
          case "included":
            return Auth2().prefs?.includedFoodTypes;
          case "excluded":
            return Auth2().prefs?.excludedFoodIngredients;
        }
        return null;
      case "tags":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().prefs?.hasTag(subKey);
        }
        return null;
      case "settings":
        String? subKey = key?.subRuleKey?.key;
        if (subKey != null) {
          return Auth2().prefs?.getSetting(subKey);
        }
        return null;
    }
    return null;
  }
}