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

import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/utils/widget_utils.dart';

class Survey extends RuleEngine {
  static const String defaultQuestionKey = 'default';

  late Map<String, SurveyData> questions;
  DateTime? lastUpdated;
  bool scored;
  String type;
  Rule? resultRule;
  dynamic resultData;

  SurveyStats? _stats;
  SurveyStats? get stats { return _stats; }

  Survey({Map<String, SurveyData>? questions, this.lastUpdated, this.scored = true, this.resultRule, required this.type,
    Map<String, dynamic> constants = const {}, Map<String, Map<String, String>> strings = const {}, Map<String, Rule> subRules = const {}})
      : super(constants: constants, strings: strings, subRules: subRules);

  factory Survey.fromJson(Map<String, dynamic> json) {
    Map<String, SurveyData> questionMap = {};
    Map<String, dynamic> questionData = JsonUtils.mapValue(json) ?? {};
    questionData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        questionMap[key] = SurveyData.fromJson(value);
      }
    });

    return Survey(
      scored: json['scored'] ?? true,
      type: json['type'] ?? false,
      resultRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['result_rule'])),
      lastUpdated: DateTimeUtils.dateTimeLocalFromJson(json['last_updated']),
      constants: RuleEngine.constantsFromJson(json),
      strings: RuleEngine.stringsFromJson(json),
      subRules: RuleEngine.subRulesFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': JsonUtils.encode(questions),
      'last_updated': DateTimeUtils.dateTimeLocalToJson(lastUpdated),
      'scored': scored,
      'result_rule': JsonUtils.encode(resultRule?.toJson()),
      'type': type,
      'stats': _stats?.toJson(),
    };
  }

  factory Survey.fromOther(Survey other) {
    Map<String, SurveyData> questions = {};
    for (MapEntry<String, SurveyData> question in other.questions.entries){
      questions[question.key] = (SurveyData.fromOther(question.value));
    }
    return Survey(
      questions: questions,
      lastUpdated: other.lastUpdated,
      scored: other.scored,
      resultRule: other.resultRule,
      type: other.type,
      constants: other.constants,
      strings: other.strings,
      subRules: other.subRules,
    );
  }

  dynamic getProperty(RuleKey? key) {
    SurveyStats? stats = _stats;
    switch (key?.key) {
      case null:
        return this;
      case "completion":
        if (stats != null) {
          return stats.complete / stats.total;
        }
        return null;
      case "scores":
        if (stats != null) {
          return stats.scores;
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
      case "question":
        RuleKey? questionKey = key?.subRuleKey;
        if (questionKey != null) {
          return questions[questionKey.key]?.getProperty(questionKey.subRuleKey);
        }
    }
    return null;
  }

  void evaluate() {
    //TODO: add params to be passed in on evaluate?
    SurveyStats stats = SurveyStats();
    //TODO: calculate stats by following question chain (depends on results of rules)
    for (SurveyData question in questions.values) {
      stats += question.stats(this);
    }
    _stats = stats;

    if (resultRule == null) {
      return;
    }

    clearCache();
    RuleActionResult? ruleResult = resultRule!.evaluate(this);
    if (ruleResult is RuleAction) {
      dynamic data = ruleResult.evaluate(this);
      resultData = data;
    }
  }

  bool canContinue({bool deep = true}) {
    for (SurveyData question in questions.values) {
      if (!question.canContinue(this, deep: deep)) {
        return false;
      }
    }
    return true;
  }

  SurveyData? get firstQuestion => questions[defaultQuestionKey];
}

class SurveyStats {
  final int total;
  final int complete;

  final int scored;
  final Map<String, num> scores;

  final Map<String, dynamic> responseData;

  SurveyStats({this.total = 0, this.complete = 0, this.scored = 0, this.scores = const {}, this.responseData = const {}});

  SurveyStats operator +(SurveyStats other) {
    Map<String, dynamic> newData = {};
    newData.addAll(responseData);
    newData.addAll(other.responseData);

    Map<String, num> newScores = {};
    newScores.addAll(scores);
    other.scores.forEach((key, value) {
      num currentScore = newScores[key] ?? 0;
      newScores[key] = currentScore + value;
    });

    return SurveyStats(
      total: total + other.total,
      complete: complete + other.complete,
      scored: scored + other.scored,
      scores: newScores,
      responseData: newData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'complete': complete,
      'scored': scored,
      'scores': scores,
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
      case "scores":
        return scores;
      case "total_score":
        return totalScore;
      case "response_data":
        String? subKey = key?.subKey;
        if (subKey != null) {
          return responseData[subKey];
        }
        return null;
    }
    return null;
  }

  num get totalScore => scores.values.fold(0, (partialSum, current) => partialSum + current);
}

abstract class SurveyData {
  final String key;
  final String? section;
  final bool allowSkip;
  final String text;
  final String? moreInfo;
  dynamic response;
  
  final String? defaultFollowUpKey;
  final Rule? defaultResponseRule;
  final Rule? followUpRule;
  final Rule? scoreRule;
  SurveyData({required this.key, this.section, required this.text, this.defaultFollowUpKey, this.defaultResponseRule, this.followUpRule, this.scoreRule, 
    this.moreInfo, this.response, this.allowSkip = false});

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    String? surveyType = JsonUtils.stringValue(json["type"]);
    switch (surveyType) {
      case "true_false": return SurveyQuestionTrueFalse.fromJson(json);
      case "multiple_choice": return SurveyQuestionMultipleChoice.fromJson(json);
      case "date_time": return SurveyQuestionDateTime.fromJson(json);
      case "numeric": return SurveyQuestionNumeric.fromJson(json);
      case "text": return SurveyQuestionText.fromJson(json);
      case "entry": return SurveyDataEntry.fromJson(json);
      case "response": return SurveyDataResponse.fromJson(json);
      case "action": return SurveyDataAction.fromJson(json);
      case "survey": return SurveyDataSurvey.fromJson(json);
      default: throw Exception("Invalid survey data type");
    }
  }

  static List<SurveyData> listFromJson(List<dynamic>? jsonList) {
    if (jsonList == null) {
      return [];
    }
    List<SurveyData> list = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        list.add(SurveyData.fromJson(json));
      }
    }
    return list;
  }

  factory SurveyData.fromOther(SurveyData other) {
    if (other is SurveyQuestionTrueFalse) {
      return SurveyQuestionTrueFalse.fromOther(other);
    } else if (other is SurveyQuestionText) {
      return SurveyQuestionText.fromOther(other);
    } else if (other is SurveyQuestionMultipleChoice) {
      return SurveyQuestionMultipleChoice.fromOther(other);
    } else if (other is SurveyQuestionDateTime) {
      return SurveyQuestionDateTime.fromOther(other);
    } else if (other is SurveyQuestionNumeric) {
      return SurveyQuestionNumeric.fromOther(other);
    } else if (other is SurveyDataEntry) {
      return SurveyDataEntry.fromOther(other);
    } else if (other is SurveyDataResponse) {
      return SurveyDataResponse.fromOther(other);
    } else if (other is SurveyDataAction) {
      return SurveyDataAction.fromOther(other);
    } else if (other is SurveyDataSurvey) {
      return SurveyDataSurvey.fromOther(other);
    }
    throw Exception("Invalid other survey type");
  }

  Map<String, dynamic> toJson();
  // num? get score;

  Map<String, dynamic> baseJson() {
    return {
      'key': key,
      'section': section,
      'text': text,
      'more_info': moreInfo,
      'response': response,
      'allow_skip': allowSkip,
      'default_follow_up_key': defaultFollowUpKey,
      'default_response_rule': JsonUtils.encode(defaultResponseRule?.toJson()),
      'follow_up_rule': JsonUtils.encode(followUpRule?.toJson()),
      'score_rule': JsonUtils.encode(scoreRule?.toJson()),
    };
  }

  dynamic getProperty(RuleKey? key) {
    switch (key?.key) {
      case null:
        return this;
      case "response":
        return response;
    }
    return null;
  }

  bool get isQuestion;

  void evaluateDefaultResponse(Survey survey, {bool deep = true}) {
    if (defaultResponseRule != null) {
      survey.clearCache();
      RuleActionResult? result = defaultResponseRule!.evaluate(survey);
      if (result is RuleAction) {
        response = result.evaluate(survey);
      }
    }
    if (deep) {
      followUp(survey)?.evaluateDefaultResponse(survey);
    }
  }

  SurveyData? followUp(Survey survey) {
    if (response != null) {
      if (followUpRule != null) {
        RuleActionResult? result = followUpRule!.evaluate(survey);
        if (result is RuleAction) {
          dynamic data = result.evaluate(survey);
          if (data is SurveyData) {
            return data;
          }
        }
      } else {
        return defaultFollowUp(survey);
      }
    }

    return null;
  }

  SurveyData? defaultFollowUp(Survey survey) => defaultFollowUpKey != null ? survey.questions[defaultFollowUpKey] : null;

  SurveyStats stats(Survey survey) {
    Map<String, dynamic> responseData = {};
    responseData[key] = response;

    Map<String, num> scores = {};
    RuleActionResult? ruleResult = scoreRule?.evaluate(survey);
    if (ruleResult is RuleAction) {
      dynamic data = ruleResult.evaluate(survey);
      if (data is num) {
        scores[section ?? ''] = data;
      }
    }

    SurveyStats stats = SurveyStats(
      total: isQuestion ? 1 : 0,
      complete: response != null ? 1 : 0,
      scored: scoreRule != null ? 1 : 0,
      scores: scores,
      responseData: responseData,
    );

    return stats;
  }

  bool canContinue(Survey survey, {bool deep = true}) {
    if (!allowSkip && response == null) {
      return false;
    }

    if (deep) {
      SurveyData? follow = followUp(survey);
      if (follow != null) {
        return follow.canContinue(survey);
      }
    }

    return true;
  }

  bool get scored => scoreRule != null;
}

class SurveyQuestionTrueFalse extends SurveyData {
  final bool yesNo;
  final List<OptionData> options;

  SurveyQuestionTrueFalse({required String question, this.yesNo = false, required String key, String? section, String? defaultFollowUpKey, Rule? defaultResponseRule, 
    Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false})
      : options = [OptionData(title: yesNo ? "Yes" : "True", value: true), OptionData(title: yesNo ? "No" : "False", value: false)],
        super(allowSkip: allowSkip, key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, 
          followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response);

  factory SurveyQuestionTrueFalse.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionTrueFalse(
      yesNo: JsonUtils.boolValue(json['yes_no']) ?? false,

      question: json['text'],
      key: JsonUtils.stringValue(json['key']) ?? '',
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: Rule.fromJson(json['follow_up_rule']),
      scoreRule: Rule.fromJson(json['score_rule']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionTrueFalse.fromOther(SurveyQuestionTrueFalse other) {
    return SurveyQuestionTrueFalse(
      key: other.key,
      section: other.section,
      yesNo: other.yesNo,
      question: other.text,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['yes_no'] = yesNo;
    json['type'] = 'true_false';
    return json;
  }

  @override
  bool get isQuestion => true;
}

class SurveyQuestionMultipleChoice extends SurveyData {
  final List<OptionData> options;
  final List<dynamic>? okAnswers;
  final bool checkAll;
  final bool allowMultiple;

  SurveyQuestionMultipleChoice({required String question, required this.options, this.okAnswers, this.allowMultiple = false, this.checkAll = false, required String key, 
    String? section, String? defaultFollowUpKey, Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false})
      : super(key: key, section: section, allowSkip: allowSkip, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, 
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response);

  factory SurveyQuestionMultipleChoice.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionMultipleChoice(
      options: OptionData.listFromJson(json['options']),
      okAnswers: json['ok_answers'],
      allowMultiple: JsonUtils.boolValue(json['allow_multiple']) ?? false,

      question: json['text'],
      key: JsonUtils.stringValue(json['key']) ?? '',
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: Rule.fromJson(json['follow_up_rule']),
      scoreRule: Rule.fromJson(json['score_rule']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionMultipleChoice.fromOther(SurveyQuestionMultipleChoice other) {
    return SurveyQuestionMultipleChoice(
      key: other.key,
      section: other.section,
      question: other.text,
      options: other.options,
      okAnswers: other.okAnswers,
      allowMultiple: other.allowMultiple,
      allowSkip: other.allowSkip,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
    );
  }

  @override
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

  //TODO: add operators to RuleComparison for simpler multi-select rules
}

class SurveyQuestionDateTime extends SurveyData {
  final DateTime? startTime;
  final DateTime? endTime;
  final bool askTime;

  SurveyQuestionDateTime({required String question, this.startTime, this.endTime, this.askTime = true, required String key, String? section, String? defaultFollowUpKey, 
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false})
      : super(key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, 
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip);

  factory SurveyQuestionDateTime.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionDateTime(
      startTime: DateTimeUtils.dateTimeLocalFromJson(json['star_time']),
      endTime: DateTimeUtils.dateTimeLocalFromJson(json['end_time']),
      askTime: JsonUtils.boolValue(json['ask_time']) ?? true,

      question: json['text'],
      section: JsonUtils.stringValue(json['section']),
      key: JsonUtils.stringValue(json['key']) ?? '',
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: Rule.fromJson(json['follow_up_rule']),
      scoreRule: Rule.fromJson(json['score_rule']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionDateTime.fromOther(SurveyQuestionDateTime other) {
    return SurveyQuestionDateTime(
      key: other.key,
      section: other.section,
      question: other.text,
      startTime: other.startTime,
      endTime: other.endTime,
      askTime: other.askTime,
      allowSkip: other.allowSkip,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
    );
  }

  @override
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
}

class SurveyQuestionNumeric extends SurveyData {
  final double? minimum;
  final double? maximum;
  final bool wholeNum;
  final bool slider;
  final bool selfScore;

  SurveyQuestionNumeric({required String question, this.minimum, this.maximum, this.wholeNum = false, this.slider = false, this.selfScore = false, required String key, 
    String? section, String? defaultFollowUpKey, Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false})
      : super(key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, followUpRule: followUpRule, 
        scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip);

  factory SurveyQuestionNumeric.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionNumeric(
      minimum: JsonUtils.doubleValue(json['minimum']),
      maximum: JsonUtils.doubleValue(json['maximum']),
      wholeNum: JsonUtils.boolValue(json['whole_num']) ?? false,
      slider: JsonUtils.boolValue(json['slider']) ?? false,
      selfScore: JsonUtils.boolValue(json['self_score']) ?? false,

      question: json['text'],
      key: JsonUtils.stringValue(json['key']) ?? '',
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: Rule.fromJson(json['follow_up_rule']),
      scoreRule: Rule.fromJson(json['score_rule']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionNumeric.fromOther(SurveyQuestionNumeric other) {
    return SurveyQuestionNumeric(
      key: other.key,
      section: other.section,
      question: other.text,
      minimum: other.minimum,
      maximum: other.maximum,
      wholeNum: other.wholeNum,
      slider: other.slider,
      selfScore: other.selfScore,
      allowSkip: other.allowSkip,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['minimum'] = minimum;
    json['maximum'] = maximum;
    json['whole_num'] = wholeNum;
    json['slider'] = slider;
    json['self_score'] = selfScore;
    json['type'] = 'numeric';
    return json;
  }

  @override
  bool get isQuestion => true;

  @override
  SurveyStats stats(Survey survey) {
    Map<String, dynamic> responseData = {};
    responseData[key] = response;

    Map<String, num> scores = {};
    if (scoreRule != null) {
      RuleActionResult? ruleResult = scoreRule!.evaluate(survey);
      if (ruleResult is RuleAction) {
        dynamic data = ruleResult.evaluate(survey);
        if (data is num) {
          scores[section ?? ''] = data;
        }
      }
    } else if (selfScore && response is num) {
      scores[section ?? ''] = response;
    }
    

    SurveyStats stats = SurveyStats(
      total: isQuestion ? 1 : 0,
      complete: response != null ? 1 : 0,
      scored: scoreRule != null ? 1 : 0,
      scores: scores,
      responseData: responseData,
    );

    return stats;
  }

  @override
  bool get scored => scoreRule != null;
}

class SurveyQuestionText extends SurveyData {
  final int minLength;
  final int? maxLength;

  SurveyQuestionText({required String question, this.minLength = 0, this.maxLength, required String key, String? section, String? defaultFollowUpKey, 
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false})
      : super(key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, 
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip);

  factory SurveyQuestionText.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionText(
      minLength: JsonUtils.intValue(json['min_length']) ?? 0,
      maxLength: JsonUtils.intValue(json['max_length']),

      question: json['text'],
      key: JsonUtils.stringValue(json['key']) ?? '',
      section: JsonUtils.stringValue(json['section']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: Rule.fromJson(json['follow_up_rule']),
      scoreRule: Rule.fromJson(json['score_rule']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionText.fromOther(SurveyQuestionText other) {
    return SurveyQuestionText(
      key: other.key,
      section: other.section,
      question: other.text,
      minLength: other.minLength,
      maxLength: other.maxLength,
      allowSkip: other.allowSkip,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['min_length'] = minLength;
    json['max_length'] = maxLength;
    json['type'] = 'text';
    return json;
  }

  @override
  bool get isQuestion => true;

  bool? get ok {
    dynamic responseVal = response;
    if (responseVal is String && responseVal.length > minLength && (maxLength == null || responseVal.length < maxLength!)) {
      return true;
    }
    return false;
  }
}

enum DataType { int, double, bool, string, date }

class SurveyDataEntry extends SurveyData {
  final Map<String, DataType> dataFormat;

  SurveyDataEntry({required String text, required this.dataFormat, required String key, String? section, String? defaultFollowUpKey, 
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false})
      : super(key: key, section:section, defaultFollowUpKey: defaultFollowUpKey, text: text, defaultResponseRule: defaultResponseRule, 
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip);

  factory SurveyDataEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? dataFormatJson = JsonUtils.mapValue(json['data_format']);
    Map<String, DataType> dataFormat = {};
    if (dataFormatJson != null) {
      for (MapEntry<String, dynamic> entry in dataFormatJson.entries) {
        dataFormatJson[entry.key] = EnumUtils.enumFromString<DataType>(DataType.values, entry.value);
      }
    }

    return SurveyDataEntry(
      dataFormat: dataFormat,

      text: json['text'],
      key: JsonUtils.stringValue(json['key']) ?? '',
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.orNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: Rule.fromJson(json['follow_up_rule']),
      scoreRule: Rule.fromJson(json['score_rule']),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyDataEntry.fromOther(SurveyDataEntry other) {
    return SurveyDataEntry(
      key: other.key,
      section: other.section,
      text: other.text,
      dataFormat: other.dataFormat,
      allowSkip: other.allowSkip,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
    );
  }

  @override
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
}

class SurveyDataResponse extends SurveyData {
  String? body;
  ActionData? action;

  SurveyDataResponse({required String text, this.body, this.action, String? moreInfo, required String key}) :
        super(key: key, text: text, moreInfo: moreInfo, allowSkip: true);

  factory SurveyDataResponse.fromJson(Map<String, dynamic> json) {
    return SurveyDataResponse(
      body: json['body'],
      action: json['action'] is Map<String, dynamic> ? ActionData.fromJson(json['action']) : null,

      text: json['text'],
      key: JsonUtils.stringValue(json['key']) ?? '',
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyDataResponse.fromOther(SurveyDataResponse other) {
    return SurveyDataResponse(
      key: other.key,
      text: other.text,
      body: other.body,
      action: other.action,
      moreInfo: other.moreInfo,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['body'] = body;
    json['action'] = action?.toJson();
    json['type'] = 'response';
    return json;
  }

  @override
  bool get isQuestion => false;
}

class SurveyDataAction extends SurveyData {
  ActionData action;

  SurveyDataAction({required String key, required this.action, SurveyData? defaultFollowUp}) :
        super(key: key, text: '', allowSkip: true);

  factory SurveyDataAction.fromJson(Map<String, dynamic> json) {
    return SurveyDataAction(
      action: ActionData.fromJson(json['action']),

      key: JsonUtils.stringValue(json['key']) ?? '',
      defaultFollowUp: JsonUtils.orNull((json) => SurveyData.fromJson(json), json['default_follow_up']),
    );
  }

  factory SurveyDataAction.fromOther(SurveyDataAction other) {
    return SurveyDataAction(
      key: other.key,
      action: other.action,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['action'] = action.toJson();
    json['type'] = 'action';
    return json;
  }

  @override
  bool get isQuestion => false;
}

class SurveyDataSurvey extends SurveyData {
  Survey survey;

  SurveyDataSurvey({required String text, required this.survey, String? moreInfo, required String key, String? section, String? defaultFollowUpKey, Rule? followUpRule, Rule? scoreRule}) :
        super(key: key, section: section, text: text, moreInfo: moreInfo, allowSkip: true, defaultFollowUpKey: defaultFollowUpKey, followUpRule: followUpRule, scoreRule: scoreRule);

  factory SurveyDataSurvey.fromJson(Map<String, dynamic> json) {
    return SurveyDataSurvey(
      survey: Survey.fromJson(json['survey']),

      key: JsonUtils.stringValue(json['key']) ?? '',
      text: json['text'],
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyDataSurvey.fromOther(SurveyDataSurvey other) {
    return SurveyDataSurvey(
      key: other.key,
      text: other.text,
      survey: other.survey,
      moreInfo: other.moreInfo,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['survey'] = survey.toJson();
    json['type'] = 'survey';
    return json;
  }

  @override
  bool get isQuestion => false;
}
