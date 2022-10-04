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
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
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
}

class RuleComparison extends RuleCondition {
  String operator;
  String dataKey;
  dynamic dataParam;
  dynamic compareTo;
  dynamic compareToParam;
  bool defaultResult;

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
}

class RuleLogic extends RuleCondition {
  String operator;
  List<RuleCondition> conditions;

  RuleLogic(this.operator, this.conditions);

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'conditions': conditions.map((e) => e.toJson()),
    };
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
  abstract int priority;

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
  String ruleKey;

  RuleReference(this.ruleKey);

  @override
  Map<String, dynamic> toJson() {
    return {
      'rule_key': ruleKey,
    };
  }
}

class RuleAction extends RuleActionResult {
  String action;
  dynamic data;
  String? dataKey;
  @override int priority;

  RuleAction({required this.action, required this.data, this.dataKey, this.priority = 0});

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    return RuleAction(
      action: json["action"],
      data: json["data"],
      dataKey: JsonUtils.stringValue(json["data_key"]),
      priority: json["priority"] ?? 0,
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
}

class RuleActionList extends RuleActionResult {
  List<RuleAction> actions;
  @override int priority;

  RuleActionList({required this.actions, required this.priority});

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
}

class RuleData {
  dynamic param;
  dynamic value;

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

class RuleSet {
  Map<String, dynamic> constants;
  Map<String, Map<String, String>> strings;
  List<Rule> rules;
  Map<String, Rule> subRules;
  final Map<String, List<RuleData>> _dataCache = {};

  RuleSet({this.constants = const {}, this.strings = const {}, required this.rules, this.subRules = const {}});

  factory RuleSet.fromJson(Map<String, dynamic> json) {
    Map<String, Rule> subRules = {};
    dynamic subRulesJson = json["sub_rules"];
    if (subRulesJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> entry in subRulesJson.entries) {
        subRules[entry.key] = Rule.fromJson(entry.value);
      }
    }

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

    Map<String, dynamic> constMap = {};
    dynamic constJson = json["constants"];
    if (constJson is Map<String, dynamic>) {
      for (MapEntry<String, dynamic> constant in constJson.entries) {
        constMap[constant.key] = loadConstant(constant.value);
      }
    }

    return RuleSet(
      constants: constMap,
      strings: stringsMap,
      rules: Rule.listFromJson(json["rules"]),
      subRules: subRules,
    );
  }

  static dynamic loadConstant(dynamic constant) {
    if (constant is Map<String, dynamic>) {
      dynamic type = constant["type"];
      dynamic data = constant["data"];
      if (type is String && data is Map<String, dynamic>) {
        return objectFromJson(type, data);
      }
    }
    return constant;
  }

  static dynamic objectFromJson(String type, Map<String, dynamic> json) {
    try {
      switch (type) {
        case "MetricValue":
          return MetricValue.fromJson(json);
      }
    } catch(e) {
      return null;
    }
    return null;
  }

  void update() {
    evaluateRules();
  }

  void clearCache() {
    _dataCache.clear();
  }

  void evaluateRules({bool clearCache = true}) {
    if (clearCache) {
      this.clearCache();
    }
    RuleActionResult? topAction;
    for (Rule rule in rules) {
      try {
        RuleActionResult? action = evaluateRule(rule);
        if (action != null && (topAction == null || topAction.priority < action.priority)) {
          topAction = action;
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    }

    if (topAction is RuleAction) {
      evaluateAction(topAction);
    } else if (topAction is RuleActionList) {
      for (RuleAction action in topAction.actions) {
        evaluateAction(action);
      }
    }
  }

  dynamic evaluateAction(RuleAction? action) {
    if (action == null) {
      return;
    }

    switch (action.action) {
      case "return":
        return getValOrCollection(action.data);
      case "sum":
        dynamic data = getValOrCollection(action.data);
        if (data is List<dynamic>) {
          num sum = 0;
          for (dynamic item in data) {
            if (item is num) {
              sum += item;
            }
          }
          return sum;
        } else if (data is num) {
          return data;
        }
        return null;
      case "notify":
        //TODO: Send notification to providers/emergency contacts
    }
    return null;
  }

  RuleActionResult? evaluateRule(Rule rule) {
    RuleResult? result;
    if (evaluateCondition(rule.condition)) {
      result = rule.trueResult;
    } else {
      result = rule.falseResult;
    }

    if (result is RuleReference) {
      Rule? subRule = subRules[result.ruleKey];
      if (subRule != null) {
        return evaluateRule(subRule);
      }
    } else if (result is Rule) {
      return evaluateRule(result);
    } else if (result is RuleAction) {
      return result;
    } else if (result is RuleActionList) {
      return result;
    }

    return null;
  }

  bool evaluateCondition(RuleCondition? condition) {
    if (condition == null) {
      return true;
    }

    if (condition is RuleLogic) {
      bool defaultResult = (condition.operator == "and");
      for (RuleCondition subCondition in condition.conditions) {
        if (condition.operator == "and") {
          if (evaluateCondition(subCondition) == false) {
            return false;
          }
        } else if (condition.operator == "or") {
          if (evaluateCondition(subCondition) == true) {
            return true;
          }
        }
      }
      return defaultResult;
    }

    if (condition is RuleComparison) {
      dynamic dataVal = getVal(condition.dataKey, condition.dataParam);

      dynamic compareTo = condition.compareTo;
      if (compareTo is String) {
        compareTo = getVal(compareTo, condition.compareToParam);
      }
      return compare(condition.operator, dataVal, compareTo, defaultResult: condition.defaultResult);
    }

    return false;
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
      return DateTimeUtils.getDisplayDateTime(val);
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
          out[entry.key] = entry.value;
        }
      }
      return out;
    } else if (data is List<dynamic>) {
      List<dynamic> out = [];
      for (int i = 0; i < data.length; i++) {
        if (data[i] is String) {
          out.add(getVal(data[i], null));
        } else {
          out.add(data[i]);
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

    dynamic val = getValDirect(key, param);
    if (val != null) {
      cached.add(RuleData(value: val, param: param));
      _dataCache[key] = cached;
    }
    return val;
  }

  dynamic getValDirect(String? key, dynamic param) {
    if (key == null) {
      return null;
    }

    param = getValOrCollection(param);

    RuleKey ruleKey = RuleKey.fromKey(key);
    switch (ruleKey.key) {
      case "literal":
        return ruleKey.subKey;
      case "constants":
        if (ruleKey.subKey != null) {
          return constants[ruleKey.subKey!];
        }
        return null;
      case "strings":
        if (ruleKey.subKey != null) {
          return interpolateString(localeString(ruleKey.subKey!));
        }
        return null;
      case "current_time":
        Duration offset = JsonUtils.durationValue(param) ?? const Duration();
        return DateTime.now().subtract(offset);
      default:
        return null;
    }
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
          if (val is MetricValue && ruleVal is MetricRange) {
            return ruleVal.inRange(val);
          }
          return defaultResult;
        default:
          return defaultResult;
      }
    } catch(e) {
      return defaultResult;
    }
  }
}

class Metric {
  final String name;
  final String unit;
  final String type;
  final List<String> valueLabels;
  final String explanation;
  final bool wholeNum;
  final Quiz? quiz;

  Metric({required this.name, required this.unit, required this.type, required this.valueLabels, this.quiz, this.wholeNum = false, required this.explanation});

  factory Metric.fromJson(Map<String, dynamic> json) {
    return Metric(
      name: json['name'],
      unit: json['unit'],
      type: json['type'],
      wholeNum: json['whole_num'] ?? false,
      valueLabels: JsonUtils.stringListValue(json['value_labels']) ?? [],
      explanation: json['explanation'] as String? ?? '',
      quiz: JsonUtils.orNull((json) => Quiz.fromJson(json), json['quiz']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'type': type,
      'whole_num': wholeNum,
      'value_labels': valueLabels,
      'explanation': explanation,
      'quiz': quiz,
    };
  }

  dynamic getProperty(RuleKey? key, dynamic param) {
    switch (key?.key) {
      case null:
        return this;
      case "name":
        return name;
      case "unit":
        return unit;
      case "type":
        return type;
      case "value_labels":
        return valueLabels;
      case "whole_num":
        return wholeNum;
      case "explanation":
        return explanation;
      case "quiz":
        return quiz;
    }
    return null;
  }

  String? valueDisplayString(MetricValue? val) {
    if (val == null || val.values.isEmpty || val.type != type) {
      return null;
    }

    if (val.values.length == 1) {
      if (wholeNum) {
        return val.values.first.toInt().toString();
      } else {
        return val.values.first.toString();
      }
    }

    String out = "";
    for (int i = 0; i < valueLabels.length; i++) {
      if (out.isNotEmpty) {
        out += ", ";
      }
      out += valueLabels[i] + ": ";
      if (i < val.values.length) {
        if (wholeNum) {
          out += val.values[i].toInt().toString();
        } else {
          out += val.values[i].toString();
        }
      }
    }
    return out;
  }
}

class MetricBoundary {
  final MetricValue value;
  final int severity;

  MetricBoundary({required this.value, required this.severity});

  factory MetricBoundary.fromJson(Map<String, dynamic> json) {
    return MetricBoundary(
      value: MetricValue.fromJson(json['value']),
      severity: json['severity'],
    );
  }

  static List<MetricBoundary> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<MetricBoundary> list = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        list.add(MetricBoundary.fromJson(json));
      }
    }
    return list;
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value.toJson(),
      'severity': severity,
    };
  }
}

class MetricRange {
  final MetricValue? maximum; //Exclusive maximum target value
  final MetricValue? minimum; //Inclusive minimum target value

  MetricRange({this.maximum, this.minimum});

  factory MetricRange.fromJson(Map<String, dynamic> json) {
    return MetricRange(
      maximum: JsonUtils.orNull((json) => MetricValue.fromJson(json), json['maximum']),
      minimum: JsonUtils.orNull((json) => MetricValue.fromJson(json), json['minimum']),
    );
  }

  factory MetricRange.fromOther(MetricRange other) {
    return MetricRange(
      minimum: other.minimum,
      maximum: other.maximum,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maximum': maximum?.toJson(),
      'minimum': minimum?.toJson(),
    };
  }

  dynamic getProperty(RuleKey? key, dynamic param) {
    switch (key?.key) {
      case null:
        return this;
      case "minimum":
        return minimum?.getProperty(key?.subRuleKey, param);
      case "maximum":
        return maximum?.getProperty(key?.subRuleKey, param);
    }
    return null;
  }

  bool inRange(MetricValue value) {
    return compare(value) == 0;
  }

  int? compare(MetricValue value) {
    if ((maximum == null && minimum == null)) {
      return null;
    }
    if (maximum != null && value > maximum) {
      return 1;
    }
    if (minimum != null && value < minimum) {
      return -1;
    }
    return 0;
  }
}

class MetricValue {
  List<double> values;
  String type;

  MetricValue({required this.values, required this.type});

  factory MetricValue.fromJson(Map<String, dynamic> json) {
    return MetricValue(
        values: JsonUtils.doubleListValue(json['values']) ?? [],
        type: json['type']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'values': values,
      'type': type
    };
  }

  @override
  bool operator ==(other) {
    if (other is! MetricValue || type != other.type || values.length != other.values.length) {
      return false;
    }
    for (int i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) {
        return false;
      }
    }
    return true;
  }

  bool operator <(other) {
    if (other is! MetricValue || type != other.type || values.length != other.values.length) {
      return false;
    }
    for (int i = 0; i < values.length; i++) {
      if (values[i] < other.values[i]) {
        return true;
      }
    }
    return false;
  }

  bool operator <=(other) {
    if (other! is MetricValue || type != other.type || values.length != other.values.length) {
      return false;
    }
    for (int i = 0; i < values.length; i++) {
      if (values[i] <= other.values[i]) {
        return true;
      }
    }
    return false;
  }

  bool operator >(other) {
    if (other is! MetricValue || type != other.type || values.length != other.values.length) {
      return false;
    }
    for (int i = 0; i < values.length; i++) {
      if (values[i] > other.values[i]) {
        return true;
      }
    }
    return false;
  }

  bool operator >=(other) {
    if (other is! MetricValue || type != other.type || values.length != other.values.length) {
      return false;
    }
    for (int i = 0; i < values.length; i++) {
      if (values[i] >= other.values[i]) {
        return true;
      }
    }
    return false;
  }

  MetricValue operator +(MetricValue other) {
    if (type != other.type || values.length != other.values.length) {
      throw const FormatException("Cannot add unrelated metric value types");
    }
    List<double> result = [];
    for (int i = 0; i < values.length; i++) {
      result.add(values[i] + other.values[i]);
    }
    return MetricValue(values: result, type: type);
  }

  MetricValue operator -(MetricValue other) {
    if (type != other.type || values.length != other.values.length) {
      throw const FormatException("Cannot subtract unrelated metric value types");
    }
    List<double> result = [];
    for (int i = 0; i < values.length; i++) {
      result.add(values[i] - other.values[i]);
    }
    return MetricValue(values: result, type: type);
  }

  MetricValue operator /(double other) {
    List<double> result = [];
    for (int i = 0; i < values.length; i++) {
      result.add(values[i] / other);
    }
    return MetricValue(values: result, type: type);
  }

  MetricValue abs() {
    return MetricValue(values: values.map((e) => e.abs()).toList(), type: type);
  }

  @override
  int get hashCode {
    int code = 0;
    for (double val in values) {
      code ^= val.hashCode;
    }
    return code;
  }

  double percentage(MetricValue start, MetricValue end) {
    if (type != start.type || values.length != start.values.length
        || type != end.type || values.length != end.values.length  ) {
      return 0.0;
    }

    double sum = 0;
    for (int i = 0; i < values.length; i++) {
      sum += MetricValue.percentageHelper(values[i], start.values[i], end.values[i]);
    }
    return sum / values.length;
  }

  dynamic getProperty(RuleKey? key, dynamic param) {
    switch (key?.key) {
      case null:
        return this;
      case "values":
        return values;
      case "type":
        return type;
      case "abs":
        return abs();
    }
    return null;
  }

  static double percentageHelper(double value, double start, double end) {
    double progress = (value - start) / (end - start);
    if (progress < 0) {
      return 0.0;
    }
    if (progress > 1.0) {
      return 1.0;
    }
    return progress;
  }
}
