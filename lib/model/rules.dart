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
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:uuid/uuid.dart';

abstract class RuleElement {
  String id;

  RuleElement({String? id}) : id = id ?? const Uuid().v4();

  factory RuleElement.fromOther(RuleElement other) {
    if (other is RuleCondition) {
      return RuleCondition.fromOther(other);
    } else { // (other is RuleResult)
      return RuleResult.fromOther(other as RuleResult);
    }
  }

  Map<String, dynamic> toJson();

  String getSummary({String? prefix, String? suffix}) => "";

  RuleElement? findElement(String id) {
    return this.id == id ? this : null;
  }

  bool updateElement(RuleElement update) {
    return id == update.id;
  }

  void updateDataKeys(String oldKey, String newKey);
  void updateSupportedOption(String oldOption, String newOption);

  Map<String, String> get supportedAlternatives => const {
    "if": "If",
    "and": "AND",
    "or": "OR",
    "cases": "Cases",
    "action": "Action",
    "actions": "Actions",
    // "reference": "Reference",
  };
} 

abstract class RuleCondition extends RuleElement {

  RuleCondition({String? id}) : super(id: id);

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

  factory RuleCondition.fromOther(RuleCondition other) {
    if (other is RuleComparison) {
      return RuleComparison.fromOther(other);
    } else {  // (other is RuleLogic)
      return RuleLogic.fromOther(other as RuleLogic);
    }
  }
}           

class RuleComparison extends RuleCondition {
  String operator;
  String dataKey;
  dynamic dataParam;
  dynamic compareTo;
  dynamic compareToParam;
  bool? defaultResult;

  RuleComparison({String? id, required this.dataKey, required this.operator, this.dataParam,
    required this.compareTo, this.compareToParam, this.defaultResult = false}) : super(id: id);

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

  factory RuleComparison.fromOther(RuleComparison other) {
    return RuleComparison(
      id: other.id,
      operator: other.operator,
      dataKey: other.dataKey,
      dataParam: other.dataParam,
      compareTo: other.compareTo,
      compareToParam: other.compareToParam,
      defaultResult: other.defaultResult,
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
    // "in_range": "in range", //TODO: implement
    "any": "any of",
    "all": "all of",
  };

  @override
  String getSummary({String? prefix, String? suffix}) {
    String dataKeySummary = dataKey;
    if (dataKey.startsWith('data.')) {
      dataKeySummary = dataKey.substring(5);
    }
    dynamic compareToSummary = compareTo;
    if (compareTo is String && compareTo.startsWith('data.')) {
      compareToSummary = compareTo.substring(5);
    }

    String summary = "Is $dataKeySummary ${supportedOperators[operator]} $compareToSummary?";
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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    if (operator == oldOption) {
      operator = newOption;
    }
  }
}

class RuleLogic extends RuleCondition {
  String operator;
  List<RuleCondition> conditions;

  RuleLogic(this.operator, this.conditions, {String? id}) : super(id: id);

  factory RuleLogic.fromOther(RuleLogic other) {
    return RuleLogic(other.operator, other.conditions.map((e) => RuleCondition.fromOther(e)).toList(), id: other.id);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'operator': operator,
      'conditions': conditions.map((e) => e.toJson()).toList(),
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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    if (operator == oldOption) {
      operator = newOption;
    }
    for (int i = 0; i < conditions.length; i++) {
      conditions[i].updateSupportedOption(oldOption, newOption);
    }
  }
}

abstract class RuleResult extends RuleElement {

  RuleResult({String? id}) : super(id: id);

  factory RuleResult.fromJson(Map<String, dynamic> json) {
    dynamic ruleKey = json["rule_key"];
    if (ruleKey is String) {
      return RuleReference(ruleKey);
    }
    dynamic cases = json["cases"];
    if (cases is List<dynamic>) {
      List<Rule> caseList = [];
      for (dynamic caseItem in cases) {
        caseList.add(Rule.fromJson(caseItem));
      }
      return RuleCases(cases: caseList);
    }
    try {
      return RuleActionResult.fromJson(json);
    } catch (_) {
      return Rule.fromJson(json);
    }
  }

  factory RuleResult.fromOther(RuleResult other) {
    if (other is RuleAction) {
      return RuleAction.fromOther(other);
    } else if (other is RuleActionList) {
      return RuleActionList.fromOther(other);
    } else if (other is RuleReference) {
      return RuleReference.fromOther(other);
    } else if (other is Rule) {
      return Rule.fromOther(other);
    } else {  // (other is RuleCases)
      return RuleCases.fromOther(other as RuleCases);
    }
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

  List<RuleAction> get possibleActions => [];
}

abstract class RuleActionResult extends RuleResult {
  abstract final int? priority;

  RuleActionResult({String? id}) : super(id: id);

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

  RuleReference(this.ruleKey, {String? id}) : super(id: id);

  factory RuleReference.fromOther(RuleReference other) {
    return RuleReference(other.ruleKey, id: other.id);
  }

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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    ruleKey = ruleKey.replaceAll(oldOption, newOption);
  }
}

class RuleAction extends RuleActionResult {
  static const String endSurveySummary = 'END SURVEY';

  String action;
  dynamic data;
  String? dataKey;
  @override int? priority;

  RuleAction({String? id, required this.action, required this.data, this.dataKey, this.priority}) : super(id: id);

  factory RuleAction.fromJson(Map<String, dynamic> json) {
    dynamic data = json["data"];
    dynamic action = json["action"];
    if (action is String) {
      if (action == 'local_notify') {
        data = Alert.fromJson(json["data"]);
      } else if (action == 'notify') {
        data = SurveyAlert.fromJson(json["data"]);
      }
      return RuleAction(
        action: action,
        data: data,
        dataKey: JsonUtils.stringValue(json["data_key"]),
        priority: json["priority"],
      );
    } else {
      throw FormatException('RuleAction: Expected a non-null String for "action"');
    }
  }

  factory RuleAction.fromOther(RuleAction other) {
    return RuleAction(
      id: other.id,
      action: other.action,
      data: other.data,
      dataKey: other.dataKey,
      priority: other.priority,
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

  static Map<String, String> getSupportedActionsForSurvey(SurveyElement surveyElement) {
    switch (surveyElement) {
      case SurveyElement.defaultResponseRule: return {"set_to": "Set To"};
      case SurveyElement.scoreRule: return {"set_to": "Set To"};
      case SurveyElement.followUpRules: return {"show": "Show"};
      case SurveyElement.resultRules: return {
        "set_result": "Save Data",
        "alert": "Alert",
        "alert_result": "Alert and Save Data",
        "save": "Save",
        "local_notify": "Schedule Notification",
        // "notify": "Send Notification",
        // "show_survey": "Show Survey",
        // "sum": "Sum",
      };
      default: return {};
    }
  }

  static Map<String, String> get supportedActions => const {
    "show": "Show",
    "set_to": "Set To",
    "set_result": "Save Data",
    "alert": "Alert",
    "alert_result": "Alert and Save Data",
    "save": "Save",
    "local_notify": "Schedule Notification",
    // "notify": "Send Notification",
    // "show_survey": "Show Survey",
    // "sum": "Sum",
  };

  static List<String> get supportedPreviews => const ["alert", "alert_result", "local_notify"];

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = supportedActions[action] ?? '';
    if (data is Alert) {
      summary += " ${data.title}";
    } else if (data is SurveyAlert) {
      summary += " ${data.contactKey}";
    } else if (data is String && data.startsWith('data.')) {
      summary += " ${data.substring(5)}";
    } else if (action == 'show' && data == null) {
      summary = endSurveySummary;  
    } else if (action != 'save') {
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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    if (action == oldOption) {
      action = newOption;
    }
  }

  @override
  List<RuleAction> get possibleActions => [this];
}

class RuleActionList extends RuleActionResult {
  List<RuleAction> actions;
  @override int? priority;

  RuleActionList({String? id, required this.actions, this.priority}) : super(id: id);

  factory RuleActionList.fromOther(RuleActionList other) {
    return RuleActionList(
      id: other.id,
      actions: other.actions.map((e) => RuleAction.fromOther(e)).toList()
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'actions': actions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Actions";
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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    for (int i = 0; i < actions.length; i++) {
      actions[i].updateSupportedOption(oldOption, newOption);
    }
  }

  @override
  List<RuleAction> get possibleActions => actions;
}

class Rule extends RuleResult {
  RuleCondition? condition;
  RuleResult? trueResult;
  RuleResult? falseResult;

  Rule({String? id, this.condition, this.trueResult, this.falseResult}) : super(id: id);

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
      id: other.id,
      condition: other.condition != null ? RuleCondition.fromOther(other.condition!) : null,
      trueResult: other.trueResult != null ? RuleResult.fromOther(other.trueResult!) : null,
      falseResult: other.falseResult != null ? RuleResult.fromOther(other.falseResult!) : null,
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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    condition?.updateSupportedOption(oldOption, newOption);
    trueResult?.updateSupportedOption(oldOption, newOption);
    falseResult?.updateSupportedOption(oldOption, newOption);
  }

  @override
  List<RuleAction> get possibleActions {
    List<RuleAction> actions = [];
    if (trueResult != null) {
      actions.addAll(trueResult!.possibleActions);
    }
    if (falseResult != null) {
      actions.addAll(falseResult!.possibleActions);
    }
    return actions;
  }
}

class RuleCases extends RuleResult {
  List<Rule> cases;

  RuleCases({String? id, required this.cases}) : super(id: id);

  factory RuleCases.fromOther(RuleCases other) {
    return RuleCases(
      id: other.id,
      cases: other.cases.map((e) => Rule.fromOther(e)).toList()
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'cases': cases.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String getSummary({String? prefix, String? suffix}) {
    String summary = "Cases";
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

  @override
  void updateSupportedOption(String oldOption, String newOption) {
    for (int i = 0; i < cases.length; i++) {
      cases[i].updateSupportedOption(oldOption, newOption);
    }
  }

  @override
  List<RuleAction> get possibleActions {
    List<RuleAction> actions = [];
    for (Rule ruleCase in cases) {
      actions.addAll(ruleCase.possibleActions);
    }
    return actions;
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
