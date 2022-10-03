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
import 'package:rokwire_plugin/utils/widget_utils.dart';
import 'package:uuid/uuid.dart';

class Quiz {
  List<QuizData> questions;
  DateTime? lastUpdated;
  bool scored;
  String type;
  Rule? resultRule;
  dynamic resultData;

  QuizStats? _stats;
  QuizStats? get stats { return _stats; }

  Quiz({required this.questions, this.lastUpdated, this.scored = true, this.resultRule, required this.type});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      questions: QuizData.listFromJson(json['questions']),
      scored: json['scored'] ?? true,
      type: json['type'] ?? false,
      resultRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['result_rule'])),
      lastUpdated: DateTimeUtils.dateTimeLocalFromJson(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': JsonUtils.encodeList(questions),
      'last_updated': DateTimeUtils.dateTimeLocalToJson(lastUpdated),
      'scored': scored,
      'result_rule': JsonUtils.encode(resultRule?.toJson()),
      'type': type,
      'stats': _stats?.toJson()
    };
  }

  factory Quiz.fromOther(Quiz other) {
    List<QuizData> questions = [];
    for (QuizData question in other.questions){
      questions.add(QuizData.fromOther(question));
    }
    return Quiz(
      questions: questions,
      lastUpdated: other.lastUpdated,
      scored: other.scored,
      resultRule: other.resultRule,
      type: other.type,
    );
  }

  dynamic getProperty(RuleKey? key) {
    QuizStats? stats = _stats;
    switch (key?.key) {
      case null:
        return this;
      case "completion":
        if (stats != null) {
          return stats.complete / stats.total;
        }
        return null;
      case "score":
        if (stats != null) {
          return stats.ok / stats.scored;
        }
        return null;
      case "last_updated":
        return lastUpdated;
      case "scored":
        return scored;
      case "type":
        return type;
      case "stats":
        if (stats != null) {
          return stats.getProperty(key?.subRuleKey);
        }
        return null;
      case "result_data":
        return resultData;
    }
    return null;
  }

  void evaluate(RuleSet? rules) {
    QuizStats stats = QuizStats();
    for (QuizData data in questions) {
      stats += data.stats(rules);
    }
    _stats = stats;
    _evaluateResult(rules);
  }

  void _evaluateResult(RuleSet? rules) {
    if (rules == null || resultRule == null) {
      return;
    }

    rules.clearCache();
    RuleActionResult? ruleResult = rules.evaluateRule(resultRule!);
    if (ruleResult is RuleAction) {
      dynamic data = rules.evaluateAction(ruleResult);
      resultData = data;
    }
  }

  bool canContinue(RuleSet? rules, {bool deep = true}) {
    for (QuizData question in questions) {
      if (!question.canContinue(rules, deep: deep)) {
        return false;
      }
    }
    return true;
  }
}

class QuizStats {
  final int total;
  final int complete;

  final int scored;
  final int ok;

  final Map<String, dynamic> responseData;

  QuizStats({this.total = 0, this.complete = 0, this.scored = 0, this.ok = 0, this.responseData = const {}});

  QuizStats operator +(QuizStats other) {
    Map<String, dynamic> newData = {};
    newData.addAll(responseData);
    newData.addAll(other.responseData);

    return QuizStats(
      total: total + other.total,
      complete: complete + other.complete,
      scored: scored + other.scored,
      ok: ok + other.ok,
      responseData: newData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'complete': complete,
      'scored': scored,
      'ok': ok
    };
  }

  dynamic getProperty(RuleKey? key) {
    switch (key?.key) {
      case null:
        return this;
      case "total":
        return total;
      case "complete":
        return complete;
      case "scored":
        return scored;
      case "ok":
        return ok;
      case "response_data":
        String? subKey = key?.subKey;
        if (subKey != null) {
          return responseData[subKey];
        }
        return null;
    }
    return null;
  }
}

abstract class QuizData {
  late final String id;
  final String? key;
  final bool allowSkip;
  final String text;
  final String? moreInfo;
  final Map<dynamic, QuizData>? followUps;
  final List<ResponseCheck>? responseFollowUps;
  final List<ResponseCheck>? responseScores;
  final bool scored;
  dynamic response;

  final Rule? displayRule;
  final Rule? defaultResponseRule;

  QuizData({String? id, this.key, required this.text, this.followUps, this.responseFollowUps, this.responseScores,
    this.displayRule, this.defaultResponseRule, this.moreInfo, this.response, this.scored = false, this.allowSkip = false}) {
    if (id == null) {
      this.id = const Uuid().v4();
    } else {
      this.id = id;
    }
  }

  factory QuizData.fromJson(Map<String, dynamic> json) {
    String? quizType = JsonUtils.stringValue(json["type"]);
    switch (quizType) {
      case "true_false": return QuizQuestionTrueFalse.fromJson(json);
      case "multiple_choice": return QuizQuestionMultipleChoice.fromJson(json);
      case "date_time": return QuizQuestionDateTime.fromJson(json);
      case "numeric": return QuizQuestionNumeric.fromJson(json);
      case "text": return QuizQuestionText.fromJson(json);
      case "entry": return QuizDataEntry.fromJson(json);
      case "response": return QuizDataResponse.fromJson(json);
      case "action": return QuizDataAction.fromJson(json);
      case "quiz": return QuizDataQuiz.fromJson(json);
      default: throw Exception("Invalid quiz data type");
    }
  }

  static List<QuizData> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<QuizData> list = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        list.add(QuizData.fromJson(json));
      }
    }
    return list;
  }

  factory QuizData.fromOther(QuizData other) {
    if (other is QuizQuestionTrueFalse) {
      return QuizQuestionTrueFalse.fromOther(other);
    } else if (other is QuizQuestionText) {
      return QuizQuestionText.fromOther(other);
    } else if (other is QuizQuestionMultipleChoice) {
      return QuizQuestionMultipleChoice.fromOther(other);
    } else if (other is QuizQuestionDateTime) {
      return QuizQuestionDateTime.fromOther(other);
    } else if (other is QuizQuestionNumeric) {
      return QuizQuestionNumeric.fromOther(other);
    } else if (other is QuizDataEntry) {
      return QuizDataEntry.fromOther(other);
    } else if (other is QuizDataResponse) {
      return QuizDataResponse.fromOther(other);
    } else if (other is QuizDataAction) {
      return QuizDataAction.fromOther(other);
    } else if (other is QuizDataQuiz) {
      return QuizDataQuiz.fromOther(other);
    }
    throw Exception("Invalid other quiz type");
  }

  static Map<dynamic, QuizData>? followUpsFromOther(QuizData other) {
    Map<dynamic, QuizData>? followUps;
    if (other.followUps != null) {
      followUps = {};
      for (MapEntry<dynamic, QuizData> entry in other.followUps!.entries) {
        followUps[entry.key] = QuizData.fromOther(entry.value);
      }
    }
    return followUps;
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() {
    return {
      'id': id,
      'key': key,
      'text': text,
      'more_info': moreInfo,
      'follow_ups': followUpsToJson(),
      'response_follow_ups': responseFollowUpsToJson(),
      'response_scores': responseScoresToJson(),
      'scored': scored,
      'response': response,
      'allow_skip': allowSkip,
      'display_rule': JsonUtils.encode(displayRule?.toJson()),
      'default_response_rule': JsonUtils.encode(defaultResponseRule?.toJson()),
    };
  }

  Map<String, dynamic>? followUpsToJson() {
    if (followUps == null) {
      return null;
    }
    Map<String, dynamic> json = {};
    for (MapEntry<dynamic, QuizData> entry in followUps!.entries) {
      json[entry.key] = entry.value.toJson();
    }
    return json;
  }

  List<Map<String, dynamic>>? responseFollowUpsToJson() {
    if (responseFollowUps == null) {
      return null;
    }
    List<Map<String, dynamic>> json = [];
    for (ResponseCheck entry in responseFollowUps!) {
      json.add(entry.toJson());
    }
    return json;
  }

  List<Map<String, dynamic>>? responseScoresToJson() {
    if (responseFollowUps == null) {
      return null;
    }
    List<Map<String, dynamic>> json = [];
    for (ResponseCheck entry in responseScores!) {
      json.add(entry.toJson());
    }
    return json;
  }

  // static Map<dynamic, QuizData>? responseFollowUpsFromJson(dynamic json) {
  //   if (json is List<dynamic>) {
  //     Map<dynamic, QuizData> followUps = {};
  //     for (dynamic followUp in json) {
  //       if (followUp is Map<String, dynamic>) {
  //         followUps[followUp['key']] = QuizData.fromJson(followUp['value']);
  //       }
  //     }
  //     return followUps;
  //   }
  //   return null;
  // }

  bool get isQuestion;

  bool shouldDisplay(RuleSet? rules) {
    if (rules == null) {
      if (displayRule == null) {
        return true;
      } else {
        return false;
      }
    }

    if (displayRule != null) {
      rules.clearCache();
      RuleActionResult? result = rules.evaluateRule(displayRule!);
      if (result is RuleAction) {
        dynamic data = rules.evaluateAction(result);
        if (data is bool) {
          return data;
        }
      }
      return false;
    }
    return true;
  }

  QuizData? get followUp {
    if (response == null) {
      return null;
    }
    QuizData? responseFollowUp = followUps?[response];
    if (responseFollowUp != null) {
      return responseFollowUp;
    }
    return defaultFollowUp;
  }

  QuizData? get defaultFollowUp => followUps?[''];

  QuizStats stats(RuleSet? rules) {
    //TODO: incorporate responseScores
    if (!shouldDisplay(rules)) {
      return QuizStats();
    }

    Map<String, dynamic> responseData = {};
    if (key != null) {
      responseData[key!] = response;
    }

    QuizStats stats = QuizStats(
      total: isQuestion ? 1 : 0,
      complete: response != null ? 1 : 0,
      scored: scored ? 1 : 0,
      ok: scored  ? 1 : 0,
      responseData: responseData,
    );

    QuizData? follow = followUp;
    if (follow != null) {
      stats += follow.stats(rules);
    }

    return stats;
  }

  bool canContinue(RuleSet? rules, {bool deep = true}) {
    if (!shouldDisplay(rules)) {
      return true;
    }

    if (!allowSkip && response == null) {
      return false;
    }

    if (deep) {
      QuizData? follow = followUp;
      if (follow != null) {
        return follow.canContinue(rules);
      }
    }

    return true;
  }
}

class QuizQuestionTrueFalse extends QuizData {
  final bool yesNo;
  final List<OptionData> options;

  QuizQuestionTrueFalse({required String question, this.yesNo = false,
    String? id, String? key, QuizData? defaultFollowUp, QuizData? okFollowUp, Map<dynamic, QuizData>? responseFollowUps,
    Rule? displayRule, Rule? defaultResponseRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false})
      : options = [OptionData(title: yesNo ? "Yes" : "True", value: true), OptionData(title: yesNo ? "No" : "False", value: false)],
        super(id: id, allowSkip: allowSkip, key: key, text: question, defaultFollowUp: defaultFollowUp, okFollowUp: okFollowUp,
                responseFollowUps: responseFollowUps, displayRule: displayRule, defaultResponseRule: defaultResponseRule, moreInfo: moreInfo, response: response, scored: scored);

  factory QuizQuestionTrueFalse.fromJson(Map<String, dynamic> json) {
    return QuizQuestionTrueFalse(
      yesNo: JsonUtils.boolValue(json['yes_no']) ?? false,

      question: json['text'],
      id: JsonUtils.stringValue(json['id']),
      key: JsonUtils.stringValue(json['key']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      okFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['ok_follow_up']),
      responseFollowUps: QuizData.responseFollowUpsFromJson(json['response_follow_ups']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory QuizQuestionTrueFalse.fromOther(QuizQuestionTrueFalse other) {
    return QuizQuestionTrueFalse(
      id: other.id,
      key: other.key,
      yesNo: other.yesNo,
      okAnswer: other.okAnswer,
      question: other.text,
      defaultFollowUp: other.defaultFollowUp != null ? QuizData.fromOther(other.defaultFollowUp!) : null,
      okFollowUp: other.okFollowUp != null ? QuizData.fromOther(other.okFollowUp!) : null,
      responseFollowUps: QuizData.followUpsFromOther(other),
      displayRule: other.displayRule,
      defaultResponseRule: other.defaultResponseRule,
      moreInfo: other.moreInfo,
      scored: other.scored,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['yes_no'] = yesNo;
    json['ok_answer'] = okAnswer;
    json['type'] = 'true_false';
    return json;
  }

  @override
  bool get isQuestion => true;

  @override
  bool? get ok {
    if (okAnswer == null) {
      return null;
    }
    return (response == okAnswer);
  }
}

class QuizQuestionMultipleChoice extends QuizData {
  final List<OptionData> options;
  final List<dynamic>? okAnswers;
  final bool checkAll;
  final bool allowMultiple;

  QuizQuestionMultipleChoice({required String question, required this.options, this.okAnswers, this.allowMultiple = false, this.checkAll = false,
    String? id, String? key, QuizData? defaultFollowUp, QuizData? okFollowUp, Map<dynamic, QuizData>? responseFollowUps,
    Rule? displayRule, Rule? defaultResponseRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false})
      : super(id: id, key: key, allowSkip: allowSkip, text: question, defaultFollowUp: defaultFollowUp, okFollowUp: okFollowUp,
                responseFollowUps: responseFollowUps, displayRule: displayRule, defaultResponseRule: defaultResponseRule, moreInfo: moreInfo, response: response, scored: scored);

  factory QuizQuestionMultipleChoice.fromJson(Map<String, dynamic> json) {
    return QuizQuestionMultipleChoice(
      options: OptionData.listFromJson(json['options']),
      okAnswers: json['ok_answers'],
      allowMultiple: JsonUtils.boolValue(json['allow_multiple']) ?? false,

      question: json['text'],
      id: JsonUtils.stringValue(json['id']),
      key: JsonUtils.stringValue(json['key']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      okFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['ok_follow_up']),
      responseFollowUps: QuizData.responseFollowUpsFromJson(json['response_follow_ups']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory QuizQuestionMultipleChoice.fromOther(QuizQuestionMultipleChoice other) {
    return QuizQuestionMultipleChoice(
      id: other.id,
      key: other.key,
      question: other.text,
      options: other.options,
      okAnswers: other.okAnswers,
      allowMultiple: other.allowMultiple,
      allowSkip: other.allowSkip,
      defaultFollowUp: other.defaultFollowUp != null ? QuizData.fromOther(other.defaultFollowUp!) : null,
      okFollowUp: other.okFollowUp != null ? QuizData.fromOther(other.okFollowUp!) : null,
      responseFollowUps: QuizData.followUpsFromOther(other),
      displayRule: other.displayRule,
      defaultResponseRule: other.defaultResponseRule,
      moreInfo: other.moreInfo,
      scored: other.scored,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['options'] = JsonUtils.encodeList(options);
    json['ok_answers'] = okAnswers;
    json['allow_multiple'] = allowMultiple;
    json['type'] = 'multiple_choice';
    return json;
  }

  @override
  bool get isQuestion => true;

  bool? listContains(List<dynamic>? list, dynamic item, {bool checkAll = false}) {
    if (list == null) {
      return null;
    }
    if (item is List<dynamic>) {
      for (dynamic val in item) {
        if (list.contains(val)) {
          if (!checkAll) {
            return true;
          }
        } else {
          if (checkAll) {
            return false;
          }
        }
      }
      if (checkAll) {
        return true;
      }
      return false;
    }
    return (list.contains(item));
  }

  @override
  bool? get ok {
    return listContains(okAnswers, response, checkAll: checkAll);
  }

  QuizData? get followUp {
    dynamic responseVal = response;
    if (responseVal == null) {
      return null;
    }
    if (responseFollowUps != null) {
      for (MapEntry<dynamic, QuizData> entry in responseFollowUps!.entries) {
        dynamic key = entry.key;
        if (key is List) {
          if (listContains(key, responseVal, checkAll: checkAll) == true) {
            return entry.value;
          }
        } else {
          if (responseVal is List && responseVal.contains(key)) {
            return entry.value;
          }
          if (responseVal == entry.key) {
            return entry.value;
          }
        }
      }
    }
    if (ok == true) {
      return okFollowUp;
    }
    return defaultFollowUp;
  }
}

class QuizQuestionDateTime extends QuizData {
  final DateTime? startTime;
  final DateTime? endTime;
  final bool askTime;

  QuizQuestionDateTime({required String question, this.startTime, this.endTime, this.askTime = true,
    String? id, String? key, QuizData? defaultFollowUp, QuizData? okFollowUp, Map<dynamic, QuizData>? responseFollowUps,
    Rule? displayRule, Rule? defaultResponseRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false})
      : super(id: id, key: key, text: question, defaultFollowUp: defaultFollowUp, okFollowUp: okFollowUp,
                responseFollowUps: responseFollowUps, displayRule: displayRule, defaultResponseRule: defaultResponseRule, moreInfo: moreInfo, response: response, scored: scored, allowSkip: allowSkip);

  factory QuizQuestionDateTime.fromJson(Map<String, dynamic> json) {
    return QuizQuestionDateTime(
      startTime: DateTimeUtils.dateTimeLocalFromJson(json['star_time']),
      endTime: DateTimeUtils.dateTimeLocalFromJson(json['end_time']),
      askTime: JsonUtils.boolValue(json['ask_time']) ?? true,

      question: json['text'],
      id: JsonUtils.stringValue(json['id']),
      key: JsonUtils.stringValue(json['key']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      okFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['ok_follow_up']),
      responseFollowUps: QuizData.responseFollowUpsFromJson(json['response_follow_ups']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory QuizQuestionDateTime.fromOther(QuizQuestionDateTime other) {
    return QuizQuestionDateTime(
      id: other.id,
      key: other.key,
      question: other.text,
      startTime: other.startTime,
      endTime: other.endTime,
      askTime: other.askTime,
      defaultFollowUp: other.defaultFollowUp != null ? QuizData.fromOther(other.defaultFollowUp!) : null,
      okFollowUp: other.okFollowUp != null ? QuizData.fromOther(other.okFollowUp!) : null,
      responseFollowUps: QuizData.followUpsFromOther(other),
      allowSkip: other.allowSkip,
      displayRule: other.displayRule,
      defaultResponseRule: other.defaultResponseRule,
      moreInfo: other.moreInfo,
      scored: other.scored,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['start_time'] = DateTimeUtils.dateTimeLocalToJson(startTime);
    json['end_time'] = DateTimeUtils.dateTimeLocalToJson(endTime);
    json['ask_time'] = askTime;
    json['type'] = 'date_time';
    return json;
  }

  @override
  bool get isQuestion => true;

  @override
  bool? get ok {
    if (startTime == null && endTime == null) {
      return null;
    }

    if (response is DateTime) {
      if (startTime != null && !startTime!.isBefore(response)) {
        return false;
      }
      if (endTime != null && endTime!.isBefore(response)) {
        return false;
      }
    }
    return false;
  }
}

class QuizQuestionNumeric extends QuizData {
  final double? minimum;
  final double? maximum;
  final bool wholeNum;
  final bool slider;

  QuizQuestionNumeric({required String question, this.minimum, this.maximum, this.wholeNum = false, this.slider = false,
    String? id, String? key, QuizData? defaultFollowUp, QuizData? okFollowUp, Map<dynamic, QuizData>? responseFollowUps,
    Rule? displayRule, Rule? defaultResponseRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false})
      : super(id: id, key: key, text: question, defaultFollowUp: defaultFollowUp, okFollowUp: okFollowUp,
                responseFollowUps: responseFollowUps, displayRule: displayRule, defaultResponseRule: defaultResponseRule, moreInfo: moreInfo, response: response, scored: scored, allowSkip: allowSkip);


  factory QuizQuestionNumeric.fromJson(Map<String, dynamic> json) {
    return QuizQuestionNumeric(
      minimum: JsonUtils.doubleValue(json['minimum']),
      maximum: JsonUtils.doubleValue(json['maximum']),
      wholeNum: JsonUtils.boolValue(json['whole_num']) ?? false,
      slider: JsonUtils.boolValue(json['slider']) ?? false,

      question: json['text'],
      id: JsonUtils.stringValue(json['id']),
      key: JsonUtils.stringValue(json['key']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      okFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['ok_follow_up']),
      responseFollowUps: QuizData.responseFollowUpsFromJson(json['response_follow_ups']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory QuizQuestionNumeric.fromOther(QuizQuestionNumeric other) {
    return QuizQuestionNumeric(
      id: other.id,
      key: other.key,
      question: other.text,
      minimum: other.minimum,
      maximum: other.maximum,
      wholeNum: other.wholeNum,
      slider: other.slider,
      defaultFollowUp: other.defaultFollowUp != null ? QuizData.fromOther(other.defaultFollowUp!) : null,
      okFollowUp: other.okFollowUp != null ? QuizData.fromOther(other.okFollowUp!) : null,
      responseFollowUps: QuizData.followUpsFromOther(other),
      allowSkip: other.allowSkip,
      displayRule: other.displayRule,
      defaultResponseRule: other.defaultResponseRule,
      moreInfo: other.moreInfo,
      scored: other.scored,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['minimum'] = minimum;
    json['maximum'] = maximum;
    json['whole_num'] = wholeNum;
    json['slider'] = slider;
    json['type'] = 'numeric';
    return json;
  }

  @override
  bool get isQuestion => true;

  @override
  bool? get ok {
    if (minimum == null && maximum == null) {
      return null;
    }

    if (response is double) {
      if (minimum != null && response < minimum!) {
        return false;
      }
      if (maximum != null && response >= maximum!) {
        return false;
      }
    }
    return false;
  }
}

class QuizQuestionText extends QuizData {
  final int minLength;
  final int? maxLength;

  QuizQuestionText({required String question, this.minLength = 0, this.maxLength,
    String? id, String? key, QuizData? defaultFollowUp, QuizData? okFollowUp, Map<dynamic, QuizData>? responseFollowUps,
    Rule? displayRule, Rule? defaultResponseRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false})
      : super(id: id, key: key, text: question, defaultFollowUp: defaultFollowUp, okFollowUp: okFollowUp,
      responseFollowUps: responseFollowUps, displayRule: displayRule, defaultResponseRule: defaultResponseRule, moreInfo: moreInfo, response: response, scored: scored, allowSkip: allowSkip);

  factory QuizQuestionText.fromJson(Map<String, dynamic> json) {
    return QuizQuestionText(
      minLength: JsonUtils.intValue(json['min_length']) ?? 0,
      maxLength: JsonUtils.intValue(json['max_length']),

      question: json['text'],
      id: JsonUtils.stringValue(json['id']),
      key: JsonUtils.stringValue(json['key']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      okFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['ok_follow_up']),
      responseFollowUps: QuizData.responseFollowUpsFromJson(json['response_follow_ups']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory QuizQuestionText.fromOther(QuizQuestionText other) {
    return QuizQuestionText(
      id: other.id,
      key: other.key,
      question: other.text,
      minLength: other.minLength,
      maxLength: other.maxLength,
      defaultFollowUp: other.defaultFollowUp != null ? QuizData.fromOther(other.defaultFollowUp!) : null,
      okFollowUp: other.okFollowUp != null ? QuizData.fromOther(other.okFollowUp!) : null,
      responseFollowUps: QuizData.followUpsFromOther(other),
      allowSkip: other.allowSkip,
      displayRule: other.displayRule,
      defaultResponseRule: other.defaultResponseRule,
      moreInfo: other.moreInfo,
      scored: other.scored,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['min_length'] = minLength;
    json['max_length'] = maxLength;
    json['type'] = 'text';
    return json;
  }

  @override
  bool get isQuestion => true;

  @override
  bool? get ok {
    dynamic responseVal = response;
    if (responseVal is String && responseVal.length > minLength && (maxLength == null || responseVal.length < maxLength!)) {
      return true;
    }
    return false;
  }
}

enum DataType { int, double, bool, string, date }

class QuizDataEntry extends QuizData {
  final Map<String, DataType> dataFormat;

  QuizDataEntry({required String text, required this.dataFormat,
    String? id, String? key, QuizData? defaultFollowUp,
    Rule? displayRule, Rule? defaultResponseRule, String? moreInfo, dynamic response, bool allowSkip = false})
      : super(id: id, key: key, text: text, defaultFollowUp: defaultFollowUp, displayRule: displayRule, defaultResponseRule: defaultResponseRule,
                moreInfo: moreInfo, response: response, allowSkip: allowSkip);

  factory QuizDataEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? dataFormatJson = JsonUtils.mapValue(json['data_format']);
    Map<String, DataType> dataFormat = {};
    if (dataFormatJson != null) {
      for (MapEntry<String, dynamic> entry in dataFormatJson.entries) {
        dataFormatJson[entry.key] = AppEnum.enumFromString<DataType>(DataType.values, entry.value);
      }
    }

    return QuizDataEntry(
      dataFormat: dataFormat,

      text: json['text'],
      id: JsonUtils.stringValue(json['id']),
      key: JsonUtils.stringValue(json['key']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory QuizDataEntry.fromOther(QuizDataEntry other) {
    return QuizDataEntry(
      id: other.id,
      key: other.key,
      text: other.text,
      dataFormat: other.dataFormat,
      defaultFollowUp: other.defaultFollowUp != null ? QuizData.fromOther(other.defaultFollowUp!) : null,
      allowSkip: other.allowSkip,
      displayRule: other.displayRule,
      defaultResponseRule: other.defaultResponseRule,
      moreInfo: other.moreInfo,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> dataFormatJson = {};
    for (MapEntry<String, DataType> entry in dataFormat.entries) {
      dataFormatJson[entry.key] = entry.value.name;
    }

    Map<String, dynamic> json = baseJson();
    json['data_format'] = dataFormatJson;
    json['type'] = 'entry';
    return json;
  }

  @override
  bool get isQuestion => false;

  @override
  bool? get ok {
    return null;
  }
}

class QuizDataResponse extends QuizData {
  String? body;
  ActionData? action;

  QuizDataResponse({required String text, this.body, this.action, String? moreInfo, String? id, Rule? displayRule}) :
        super(id: id, text: text, moreInfo: moreInfo, displayRule: displayRule, allowSkip: true);

  factory QuizDataResponse.fromJson(Map<String, dynamic> json) {
    return QuizDataResponse(
      body: json['body'],
      action: json['action'] is Map<String, dynamic> ? ActionData.fromJson(json['action']) : null,

      text: json['text'],
      id: JsonUtils.stringValue(json['id']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
    );
  }

  factory QuizDataResponse.fromOther(QuizDataResponse other) {
    return QuizDataResponse(
      id: other.id,
      text: other.text,
      body: other.body,
      action: other.action,
      moreInfo: other.moreInfo,
      displayRule: other.displayRule,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['body'] = body;
    json['action'] = action?.toJson();
    json['type'] = 'response';
    return json;
  }

  @override
  bool get isQuestion => false;

  @override
  bool? get ok {
    return null;
  }
}

class QuizDataAction extends QuizData {
  ActionData action;

  QuizDataAction({String? id, required this.action, QuizData? defaultFollowUp, Rule? displayRule}) :
        super(id: id, text: '', defaultFollowUp: defaultFollowUp, displayRule: displayRule, allowSkip: true);

  factory QuizDataAction.fromJson(Map<String, dynamic> json) {
    return QuizDataAction(
      action: ActionData.fromJson(json['action']),

      id: JsonUtils.stringValue(json['id']),
      defaultFollowUp: JsonUtils.orNull((json) => QuizData.fromJson(json), json['default_follow_up']),
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
    );
  }

  factory QuizDataAction.fromOther(QuizDataAction other) {
    return QuizDataAction(
      id: other.id,
      action: other.action,
      displayRule: other.displayRule,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['action'] = action.toJson();
    json['type'] = 'action';
    return json;
  }

  @override
  bool get isQuestion => false;

  @override
  bool? get ok {
    return null;
  }
}

class QuizDataQuiz extends QuizData {
  Quiz quiz;

  QuizDataQuiz({required String text, required this.quiz, String? moreInfo, String? id, Rule? displayRule}) :
        super(id: id, text: text, moreInfo: moreInfo, displayRule: displayRule, allowSkip: true);

  factory QuizDataQuiz.fromJson(Map<String, dynamic> json) {
    return QuizDataQuiz(
      quiz: Quiz.fromJson(json['quiz']),

      id: JsonUtils.stringValue(json['id']),
      text: json['text'],
      moreInfo: JsonUtils.stringValue(json['more_info']),
      displayRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['display_rule'])),
    );
  }

  factory QuizDataQuiz.fromOther(QuizDataQuiz other) {
    return QuizDataQuiz(
      id: other.id,
      text: other.text,
      quiz: other.quiz,
      moreInfo: other.moreInfo,
      displayRule: other.displayRule,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['quiz'] = quiz.toJson();
    json['type'] = 'quiz';
    return json;
  }

  @override
  bool get isQuestion => false;

  @override
  bool? get ok {
    return null;
  }
}


class ResponseCheck {
  final String operation;
  final dynamic key;
  final dynamic value;

  ResponseCheck({required this.operation, required this.key, required this.value});

  factory ResponseCheck.fromJson(Map<String, dynamic> json) {
    return ResponseCheck(
      operation: JsonUtils.stringValue(json['operation']) ?? '',
      key: json['key'],
      value: json['value']
    );
  }

  static List<ResponseCheck> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<ResponseCheck> list = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        list.add(ResponseCheck.fromJson(json));
      }
    }
    return list;
  }

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'key': key,
      'value': value,
    };
  }

  bool evaluate(dynamic result) {
    try {
      switch (operation) {
        case "<":
          if (key is DateTime && result is DateTime) {
            return result.isBefore(key);
          }
          return result < key;
        case ">":
          if (result is DateTime && key is DateTime) {
            return result.isAfter(key);
          }
          return key < result;
        case "<=":
          return result <= key;
        case ">=":
          return key <= result;
        case "==":
          if (result is DateTime && key is DateTime) {
            return result.isAtSameMomentAs(key);
          }
          return result == key;
        case "!=":
          if (result is DateTime && key is DateTime) {
            return !result.isAtSameMomentAs(key);
          }
          return result != key;
        case "in_range":
          if (key is! Iterable<num> || (key as Iterable<num>).length != 2) {
            return false;
          }
          num min = (key as Iterable<num>).elementAt(0);
          num max = (key as Iterable<num>).elementAt(1);
          if (result is num) {
            return result >= min && result <= max;
          } else if (result is Iterable<num>) {
            for (num item in result) {
              if (item < min || item > max) {
                return false;
              }
            }
            return true;
          }
          return false;
        case "all":
          if (key is Iterable) {
            if (result is Iterable) {
              for (dynamic item in key) {
                for (dynamic resultItem in result) {
                  if (resultItem != item) {
                    return false;
                  }
                }
              }
            } else {
              for (dynamic item in key) {
                if (result != item) {
                  return false;
                }
              }
            }
            return true;
          }
          return false;
        case "any":
          if (key is Iterable) {
            if (result is Iterable) {
              for (dynamic item in key) {
                for (dynamic resultItem in result) {
                  if (resultItem == item) {
                    return true;
                  }
                }
              }
            } else {
              for (dynamic item in key) {
                if (result == item) {
                  return true;
                }
              }
            }
          }
          return false;
        case "none":
          if (key is Iterable) {
            if (result is Iterable) {
              for (dynamic item in key) {
                for (dynamic resultItem in result) {
                  if (resultItem == item) {
                    return false;
                  }
                }
              }
            } else {
              for (dynamic item in key) {
                if (result == item) {
                  return false;
                }
              }
            }
            return true;
          }
          return false;
      }
    } catch(e) {
      debugPrint(e.toString());
    }
    return false;
  }
}