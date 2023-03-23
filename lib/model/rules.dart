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

  static Map<String, String> get supportedOperators => const {
    "<": "Less than",
    ">": "Greater than",
    "<=": "Less than or equal to",
    ">=": "Greater than or equal to",
    "==": "Equal to",
    "!=": "Not equal to",
    "in_range": "In range",
    "any": "Any of",
    "all": "All of",
  };
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

  static Map<String, String> get supportedOperators => const {
    "or": "OR",
    "and": "AND",
  };
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

  static Map<String, String> get supportedActions => const {
    "return": "Return",
    "sum": "Sum",
    "set_result": "Set Result",
    "show_survey": "Show Survey",
    "alert": "Alert",
    "alert_result": "Alert Result",
    "notify": "Notify",
    "save": "Save",
    "local_notify": "Local Notify",
  };      
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
