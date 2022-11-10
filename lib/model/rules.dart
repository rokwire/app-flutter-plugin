// Copyright 2022 Board of Trustees of the University of Illinois.
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

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/model/alert.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/local_notifications.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/ui/popups/alerts.dart';
import 'package:rokwire_plugin/utils/utils.dart';

abstract class RuleCondition {

  RuleCondition();

  factory RuleCondition.fromJson(Map<String, dynamic> json) {
    dynamic conditions = json["conditions"];
    if (conditions is List<dynamic>) {
      List<RuleCondition> parsedConditions = [];
      for (dynamic condition in conditions) {
        parsedConditions.add(RuleCondition.fromJson(condition));
      }
      return RuleLogic(json["operator"], parsedConditions);
    }
    return RuleComparison.fromJson(json);
  }

  Map<String, dynamic> toJson();

  bool evaluate(RuleEngine engine);
}

class RuleComparison extends RuleCondition {
  final String operator;
  final String dataKey;
  final dynamic dataParam;
  final dynamic compareTo;
  final dynamic compareToParam;
  final bool defaultResult;

  RuleComparison({required this.dataKey, required this.operator, this.dataParam,
    required this.compareTo, this.compareToParam, this.defaultResult = false});

  factory RuleComparison.fromJson(Map<String, dynamic> json) {
    return RuleComparison(
      operator: json["operator"],
      dataKey: json["data_key"],
      dataParam: json["data_param"],
      compareTo: json["compare_to"],
      compareToParam: json["compare_to_param"],
      defaultResult: json["default_result"] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'data_key': dataKey,
      'data_param': dataParam,
      'compare_to': compareTo,
      'compare_to_param': compareToParam,
      'default_result': defaultResult,
    };
  }

  @override
  bool evaluate(RuleEngine engine) {
    dynamic dataVal = engine.getVal(dataKey, dataParam);

    dynamic compareToVal = compareTo;
    if (compareToVal is String) {
      compareToVal = engine.getVal(compareTo, compareToParam);
    }
    return compare(operator, dataVal, compareToVal, defaultResult: defaultResult);
  }

  bool compare(String operator, dynamic val, dynamic ruleVal, {bool defaultResult = false}) {
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

  
}

class RuleLogic extends RuleCondition {
  final String operator;
  final List<RuleCondition> conditions;

  RuleLogic(this.operator, this.conditions);

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'conditions': conditions.map((e) => e.toJson()),
    };
  }

  @override
  bool evaluate(RuleEngine engine) {
    bool defaultResult = (operator == "and");
    for (RuleCondition subCondition in conditions) {
      if (operator == "and") {
        if (!subCondition.evaluate(engine)) {
          return false;
        }
      } else if (operator == "or") {
        if (subCondition.evaluate(engine)) {
          return true;
        }
      }
    }
    return defaultResult;
  }
}

abstract class RuleResult {

  RuleResult();

  factory RuleResult.fromJson(Map<String, dynamic> json) {
    dynamic ruleKey = json["rule_key"];
    if (ruleKey is String) {
      return RuleReference(ruleKey);
    }
    dynamic condition = json["condition"];
    if (condition != null) {
      return Rule.fromJson(json);
    }
    return RuleActionResult.fromJson(json);
  }

  Map<String, dynamic> toJson();
}

abstract class RuleActionResult extends RuleResult {
  abstract final int? priority;

  RuleActionResult();

  factory RuleActionResult.fromJson(Map<String, dynamic> json) {
    dynamic actions = json["actions"];
    if (actions is List<dynamic>) {
      List<RuleAction> actionList = [];
      for (dynamic action in actions) {
        actionList.add(RuleAction.fromJson(action));
      }
      return RuleActionList(actions: actionList, priority: json["priority"]);
    }
    return RuleAction.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson();
}

class RuleReference extends RuleResult {
  final String ruleKey;

  RuleReference(this.ruleKey);

  @override
  Map<String, dynamic> toJson() {
    return {
      'rule_key': ruleKey,
    };
  }
}

class RuleAction extends RuleActionResult {
  final String action;
  final dynamic data;
  final String? dataKey;
  @override int? priority;

  RuleAction({required this.action, required this.data, this.dataKey, this.priority});

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      action: json["action"],
      data: json["data"],
      dataKey: JsonUtils.stringValue(json["data_key"]),
      priority: json["priority"],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'data': data,
      'data_key': dataKey,
      'priority': priority,
    };
  }

  dynamic evaluate(RuleEngine engine) {
    switch (action) {
      case "return":
        return _return(engine);
      case "sum":
        return _sum(engine);
      case "set_result":
        _setResult(engine);
        return null;
      case "show_survey":
        //TODO: fix this (should use notification like alert)
        if (data is String) {
        // data = survey id
          return data;
        }
        return null;
      case "alert":
        _alert(engine);
        return null;
      case "alert_result":
        _alert(engine);
        _setResult(engine);
        return null;
      case "notify":
        return _notify(engine);
      case "save":
        return _save(engine);
      case "local_notify":
        return _localNotify(engine);
    }
    return null;
  }

  dynamic _return(RuleEngine engine) {
    return engine.getValOrCollection(data);
  }

  dynamic _sum(RuleEngine engine) {
    dynamic evaluatedData = engine.getValOrCollection(data);
    if (data is List<dynamic>) {
      num sum = 0;
      for (dynamic item in evaluatedData) {
        if (item is num) {
          sum += item;
        }
      }
      return sum;
    } else if (data is num) {
      return data;
    }
    return null;
  }

  void _setResult(RuleEngine engine) {
    engine.resultData = engine.getValOrCollection(data);
  }

  void _alert(RuleEngine engine) {
    dynamic alertData = engine.getValOrCollection(data);
    if (alertData is SurveyDataResult) {
      NotificationService().notify(Alerts.notifyAlert, Alert(title: alertData.text, text: alertData.moreInfo, actions: alertData.actions));
    } else if (alertData is Alert) {
      NotificationService().notify(Alerts.notifyAlert, alertData);
    }
  }

  Future<bool> _notify(RuleEngine engine) {
    dynamic notificationData = engine.getValOrCollection(data);
    if (notificationData is Map<String, dynamic>) {
      SurveyAlert alert = SurveyAlert.fromJson(notificationData);
      return Polls().createSurveyAlert(alert);
    }
    return Future<bool>(() => false);
  } 

  Future<bool> _save(RuleEngine engine) {
    return engine.save();
  }

  Future<bool> _localNotify(RuleEngine engine) {
    if (data is Map<String, dynamic>) {
      Alert alert = Alert.fromJson(data);
      dynamic scheduleType = alert.params?["type"];
      dynamic schedule = alert.params?["schedule"];
      if (scheduleType is String && schedule is String) {
        switch (scheduleType) {
          case "relative":
            //TODO: string interpolation for title and text
            Duration? notifyWaitTime = DateTimeUtils.parseDelimitedDurationString(schedule, ":");
            if (notifyWaitTime != null) {
              return LocalNotifications().zonedSchedule("${engine.type}.${engine.id}",
                title: alert.title,
                message: alert.text,
                payload: JsonUtils.encode(alert.actions),
                dateTime: DateTime.now().add(notifyWaitTime)
              );
            }
            break;
          case "absolute":
            //TODO: implement
          case "cron":
            //TODO: implement
        }
      }
    }
    
    return Future<bool>(() => false);
  }
}

class RuleActionList extends RuleActionResult {
  final List<RuleAction> actions;
  @override int? priority;

  RuleActionList({required this.actions, this.priority});

  @override
  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'actions': actions.map((e) => e.toJson()),
    };
  }
}

class Rule extends RuleResult {
  final RuleCondition? condition;
  final RuleResult? trueResult;
  final RuleResult? falseResult;

  Rule({this.condition, this.trueResult, this.falseResult});

  factory Rule.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? condition = json["condition"];
    Map<String, dynamic>? trueResult = json["true_result"];
    Map<String, dynamic>? falseResult = json["false_result"];
    return Rule(
      condition: condition != null ? RuleCondition.fromJson(condition) : null,
      trueResult: trueResult != null ? RuleResult.fromJson(trueResult) : null,
      falseResult: falseResult != null ? RuleResult.fromJson(falseResult) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'condition': condition?.toJson(),
      'true_result': trueResult?.toJson(),
      'false_result': falseResult?.toJson(),
    };
  }

  static List<Rule> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<Rule> rules = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        rules.add(Rule.fromJson(json));
      }
    }
    return rules;
  }

  static List<Map<String, dynamic>> listToJson(List<Rule>? rules) {
    if (rules == null) {
      return [];
    }
    List<Map<String, dynamic>> rulesJson = [];
    for (Rule rule in rules) {
      rulesJson.add(rule.toJson());
    }
    return rulesJson;
  }

  dynamic evaluate(RuleEngine engine) {
    RuleResult? result;
    if (condition == null || condition!.evaluate(engine)) {
      result = trueResult;
    } else {
      result = falseResult;
    }

    if (result is RuleReference) {
      Rule? subRule = engine.subRules[result.ruleKey];
      if (subRule != null) {
        return subRule.evaluate(engine);
      }
    } else if (result is Rule) {
      return result.evaluate(engine);
    } else if (result is RuleAction) {
      return result.evaluate(engine);
    } else if (result is RuleActionList) {
      List<dynamic> actionResults = [];
      for (RuleAction action in result.actions) {
        actionResults.add(action.evaluate(engine));
      }
      return actionResults;
    }

    return null;
  }
}

abstract class RuleEngine {
  abstract final String id;
  abstract final String type;

  final Map<String, dynamic> constants;
  final Map<String, Map<String, String>> strings;
  final Map<String, Rule> subRules;
  dynamic resultData;

  final Map<String, List<RuleData>> _dataCache = {};

  RuleEngine({this.constants = const {}, this.strings = const {}, this.subRules = const {}, this.resultData});

  static Map<String, Rule> subRulesFromJson(Map<String, dynamic> json) {
    Map<String, Rule> subRules = {};
    dynamic subRulesJson = json["sub_rules"];
    if (subRulesJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> entry in subRulesJson.entries) {
        subRules[entry.key] = Rule.fromJson(entry.value);
      }
    }
    return subRules;
  }

  static Map<String, Map<String, String>> stringsFromJson(Map<String, dynamic> json) {
    Map<String, Map<String, String>> stringsMap = {};
    dynamic stringsJson = json["strings"];
    if (stringsJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> language in stringsJson.entries) {
        if (language.value is Map<String, dynamic>) {
          Map<String, String> strings = {};
          for (MapEntry<String, dynamic> string in language.value.entries) {
            if (string.value is String) {
              strings[string.key] = string.value;
            }
          }
          stringsMap[language.key] = strings;
        }
      }
    }
    return stringsMap;
  }

  static Map<String, dynamic> constantsFromJson(Map<String, dynamic> json) {
    Map<String, dynamic> constMap = {};
    dynamic constJson = json["constants"];
    if (constJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> constant in constJson.entries) {
        constMap[constant.key] = constant.value;
      }
    }
    return constMap;
  }

  dynamic getProperty(RuleKey? key) {
    switch (key?.key) {
      case "auth":
        return Auth2().getProperty(key?.subRuleKey);
    }
    return key?.toString();
  }

  Future<bool> save();

  void clearCache() {
    _dataCache.clear();
  }

  void evaluateRules(List<Rule> rules, {bool clearCache = true}) {
    if (clearCache) {
      this.clearCache();
    }
    RuleActionResult? topAction;
    for (Rule rule in rules) {
      try {
        RuleActionResult? action = rule.evaluate(this);
        if (action != null && (topAction == null || (topAction.priority ?? 0) < (action.priority ?? 0))) {
          topAction = action;
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    }

    if (topAction is RuleAction) {
      topAction.evaluate(this);
    } else if (topAction is RuleActionList) {
      for (RuleAction action in topAction.actions) {
        action.evaluate(this);
      }
    }
  }

  String localeString(String key) {
    String? currentLanguage = Localization().currentLocale?.languageCode;
    Map<String, String>? currentLanguageStrings = (currentLanguage != null) ? strings[currentLanguage] : null;
    dynamic currentResult = (currentLanguageStrings != null) ? currentLanguageStrings[key] : null;
    if (currentResult != null) {
      return currentResult;
    }

    String? defaultLanguage = Localization().defaultLocale?.languageCode;
    Map<String, String>? defaultLanguageStrings = (defaultLanguage != null) ? strings[defaultLanguage] : null;
    dynamic defaultResult = (defaultLanguageStrings != null) ? defaultLanguageStrings[key] : null;
    if (defaultResult is String) {
      return defaultResult;
    }

    return Localization().getString(key) ?? key;
  }

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

  String? interpolateString(String? string) {
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
          val = getDisplayVal(parts[0], parts[1]);
        } else {
          val = getDisplayVal(key, null);
        }
        string = string?.replaceFirst(full, val);
      }
    }
    return string;
  }

  String getDisplayVal(String key, dynamic param) {
    dynamic val = getVal(key, param);
    if (val is DateTime) {
      return AppDateTime().getDisplayDateTime(val);
    }
    return val.toString();
  }

  dynamic getValOrCollection(dynamic data) {
    if (data is String) {
      return getVal(data, null);
    } else if (data is Map<String, dynamic>) {
      Map<String, dynamic> out = {};
      for (MapEntry<String, dynamic> entry in data.entries) {
        if (entry.value is String) {
          out[entry.key] = getVal(entry.value, null);
        } else {
          out[entry.key] = getValOrCollection(entry.value);
        }
      }
      return out;
    } else if (data is List<dynamic>) {
      List<dynamic> out = [];
      for (int i = 0; i < data.length; i++) {
        if (data[i] is String) {
          out.add(getVal(data[i], null));
        } else {
          out.add(getValOrCollection(data[i]));
        }
      }
      return out;
    }
    return data;
  }

  dynamic getVal(String? key, dynamic param) {
    if (key == null) {
      return null;
    }

    List<RuleData> cached = _dataCache[key] ?? [];
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
    return getValDirect(key, param);
  }

  dynamic getValDirect(String? key, dynamic param) {
    if (key == null) {
      return null;
    }

    param = getValOrCollection(param);

    RuleKey ruleKey = RuleKey.fromKey(key);
    switch (ruleKey.key) {
      case "literal":
        _dataCache[key]?.add(RuleData(value: ruleKey.subKey, param: param));
        return ruleKey.subKey;
      case "constants":
        if (ruleKey.subKey != null) {
          dynamic constVal = constants[ruleKey.subKey!];
          _dataCache[key]?.add(RuleData(value: constVal, param: param));
          return constVal;
        }
        return null;
      case "strings":
        if (ruleKey.subKey != null) {
          String? stringVal = interpolateString(localeString(ruleKey.subKey!));
          _dataCache[key]?.add(RuleData(value: stringVal, param: param));
          return stringVal;
        }
        return null;
      case "current_time":
        Duration offset = JsonUtils.durationValue(param) ?? const Duration();
        return DateTime.now().subtract(offset);
      default:
        return getProperty(ruleKey);
    }
  }
}

class RuleKey {
  final String key;
  final String? subKey;

  RuleKey(this.key, this.subKey);

  factory RuleKey.fromKey(String key) {
    int dotIdx = key.indexOf('.');
    if (dotIdx >= 0) {
      return RuleKey(
        key.substring(0, dotIdx),
        key.substring(dotIdx + 1),
      );
    }
    return RuleKey(key, null);
  }

  RuleKey? get subRuleKey {
    if (subKey != null) {
      return RuleKey.fromKey(subKey!);
    }
    return null;
  }

  @override
  String toString() => subKey != null ? '$key.$subKey' : key;
}

class RuleData {
  final dynamic param;
  final dynamic value;

  RuleData({required this.value, this.param});

  bool match(dynamic param) {
    if (param is Map) {
      if (this.param is Map) {
        if (!mapEquals(param, this.param)) {
          return false;
        }
      } else {
        return false;
      }
    } else if (param is List) {
      if (this.param is List) {
        if (!listEquals(param, this.param)) {
          return false;
        }
      } else {
        return false;
      }
    } else {
      if (param != this.param) {
        return false;
      }
    }

    return true;
  }
}
