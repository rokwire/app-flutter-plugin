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
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:uuid/uuid.dart';

abstract class RuleElement {
  String id = const Uuid().v4();

  RuleElement();

  Map<String, dynamic> toJson();

  String getSummary({String? prefix, String? suffix}) => "";

  RuleElement? findElement(String id) {
    return this.id == id ? this : null;
  }

  bool updateElement(RuleElement update) {
    return id == update.id;
  }

  void updateDataKeys(String oldKey, String newKey);

  Map<String, String> get supportedAlternatives => const {
    "if": "If",
    "and": "AND",
    "or": "OR",
    "cases": "Cases",
    "action": "Action",
    "action_list": "Actions",
    // "reference": "Reference",
  };
} 

abstract class RuleCondition extends RuleElement {

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
}           

class RuleComparison extends RuleCondition {
  String operator;
  String dataKey;
  dynamic dataParam;
  dynamic compareTo;
  dynamic compareToParam;
  bool? defaultResult;

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

  static Map<String, String> get supportedOperators => const {
    "<": "less than",
    ">": "greater than",
    "<=": "less than or equal to",
    ">=": "greater than or equal to",
    "==": "equal to",
    "!=": "not equal to",
    "in_range": "in range",
    "any": "any of",
    "all": "all of",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Is $dataKey ${supportedOperators[operator]} $compareTo?";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    dataKey = dataKey.replaceAll(oldKey, newKey);
    if (compareTo is String) {
      compareTo = (compareTo as String).replaceAll(oldKey, newKey);
    }
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

  static Map<String, String> get supportedOperators => const {
    "or": "OR",
    "and": "AND",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = supportedOperators[operator] ?? 'Invalid operator';
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  RuleElement? findElement(String id) {
    RuleElement? elem = super.findElement(id);
    if (elem != null) {
      return elem;
    }

    for (RuleCondition condition in conditions) {
      elem = condition.findElement(id);
      if (elem != null) {
        return elem;
      }
    }
    return null;
  }

  @override
  bool updateElement(RuleElement update) {
    for (int i = 0; i < conditions.length; i++) {
      if (conditions[i].id == update.id && update is RuleCondition) {
        conditions[i] = update;
        return true;
      }
      if (conditions[i].updateElement(update)) {
        return true;
      }
    }
    return false;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    for (int i = 0; i < conditions.length; i++) {
      conditions[i].updateDataKeys(oldKey, newKey);
    }
  }
}

abstract class RuleResult extends RuleElement {

  RuleResult();

  factory RuleResult.fromJson(Map<String, dynamic> json) {
    dynamic ruleKey = json["rule_key"];
    if (ruleKey is String) {
      return RuleReference(ruleKey);
    }
    dynamic cases = json["cases"];
    if (cases is List<dynamic>) {
      List<Rule> caseList = [];
      for (dynamic caseItem in caseList) {
        caseList.add(Rule.fromJson(caseItem));
      }
      return RuleCases(cases: caseList);
    }
    dynamic condition = json["condition"];
    if (condition != null) {
      return Rule.fromJson(json);
    }
    return RuleActionResult.fromJson(json);
  }

  static List<RuleResult> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<RuleResult> ruleResults = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        ruleResults.add(RuleResult.fromJson(json));
      }
    }
    return ruleResults;
  }

  static List<Map<String, dynamic>> listToJson(List<RuleResult>? resultRules) {
    if (resultRules == null) {
      return [];
    }
    List<Map<String, dynamic>> resultsJson = [];
    for (RuleResult ruleResult in resultRules) {
      resultsJson.add(ruleResult.toJson());
    }
    return resultsJson;
  }
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

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Evaluate $ruleKey";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    ruleKey = ruleKey.replaceAll(oldKey, newKey);
  }
}

class RuleAction extends RuleActionResult {
  String action;
  dynamic data;
  String? dataKey;
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

  static Map<String, String> get supportedActions => const {
    "return": "Return",
    // "sum": "Sum",
    "set_result": "Set Result",
    // "show_survey": "Show Survey",
    "alert": "Alert",
    "alert_result": "Alert Result",
    // "notify": "Notify",
    "save": "Save",
    // "local_notify": "Local Notify",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "${supportedActions[action]}";
    if (data != null) {
      summary += " $data";
    }
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    dataKey = dataKey?.replaceAll(oldKey, newKey);
    if (data is String) {
      data = (data as String).replaceAll(oldKey, newKey);
    }
  }
}

class RuleActionList extends RuleActionResult {
  List<RuleAction> actions;
  @override int? priority;

  RuleActionList({required this.actions, this.priority});

  @override
  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'actions': actions.map((e) => e.toJson()),
    };
  }

  @override
  RuleElement? findElement(String id) {
    RuleElement? elem = super.findElement(id);
    if (elem != null) {
      return elem;
    }

    for (RuleAction action in actions) {
      if (action.id == id) {
        return action;
      }
    }
    return null;
  }

  @override
  bool updateElement(RuleElement update) {
    for (int i = 0; i < actions.length; i++) {
      if (actions[i].id == update.id && update is RuleAction) {
        actions[i] = update;
        return true;
      }
    }
    return false;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    for (int i = 0; i < actions.length; i++) {
      actions[i].updateDataKeys(oldKey, newKey);
    }
  }
}

class Rule extends RuleResult {
  RuleCondition? condition;
  RuleResult? trueResult;
  RuleResult? falseResult;

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

  factory Rule.fromOther(Rule other) {
    return Rule(
      condition: other.condition,
      trueResult: other.trueResult,
      falseResult: other.falseResult,
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

  @override
  RuleElement? findElement(String id) {
    RuleElement? elem = super.findElement(id);
    if (elem != null) {
      return elem;
    }

    elem = condition?.findElement(id);
    if (elem != null) {
      return elem;
    }
    elem = trueResult?.findElement(id);
    if (elem != null) {
      return elem;
    }
    elem = falseResult?.findElement(id);
    if (elem != null) {
      return elem;
    }

    return null;
  }
  
  @override
  bool updateElement(RuleElement update) {
    if (condition?.id == update.id && update is RuleCondition) {
      condition = update;
      return true;
    }
    if (condition?.updateElement(update) ?? false) {
      return true;
    }
    
    if (trueResult?.id == update.id && update is RuleResult) {
      trueResult = update;
      return true;
    }
    if (trueResult?.updateElement(update) ?? false) {
      return true;
    }

    if (falseResult?.id == update.id && update is RuleResult) {
      falseResult = update;
      return true;
    }
    if (falseResult?.updateElement(update) ?? false) {
      return true;
    }

    return false;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    condition?.updateDataKeys(oldKey, newKey);
    trueResult?.updateDataKeys(oldKey, newKey);
    falseResult?.updateDataKeys(oldKey, newKey);
  }
}

class RuleCases extends RuleResult {
  List<Rule> cases;

  RuleCases({required this.cases});

  @override
  Map<String, dynamic> toJson() {
    return {
      'cases': cases.map((e) => e.toJson()),
    };
  }

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Cases:";
    if (prefix != null) {
      summary = "$prefix $summary";
    }
    if (suffix != null) {
      summary = "$summary $suffix";
    }
    return summary;
  }

  @override
  RuleElement? findElement(String id) {
    RuleElement? elem = super.findElement(id);
    if (elem != null) {
      return elem;
    }

    for (Rule rule in cases) {
      elem = rule.findElement(id);
      if (elem != null) {
        return elem;
      }
    }
    return null;
  }

  @override
  bool updateElement(RuleElement update) {
    for (int i = 0; i < cases.length; i++) {
      if (cases[i].id == update.id && update is Rule) {
        cases[i] = update;
        return true;
      }
      if (cases[i].updateElement(update)) {
        return true;
      }
    }
    return false;
  }

  @override
  void updateDataKeys(String oldKey, String newKey) {
    for (int i = 0; i < cases.length; i++) {
      cases[i].updateDataKeys(oldKey, newKey);
    }
  }
}

abstract class RuleEngine {
  abstract final String id;
  abstract final String type;

  final Map<String, dynamic> constants;
  final Map<String, Map<String, String>> strings;
  final Map<String, Rule> subRules;
  dynamic resultData;

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

  static Map<String, dynamic> subRulesToJson(Map<String, Rule> subRules) {
    Map<String, dynamic> json = {};
    for (MapEntry<String, Rule> entry in subRules.entries) {
      json[entry.key] = entry.value.toJson();
    }
    return json;
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
