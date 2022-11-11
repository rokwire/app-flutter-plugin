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
import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyResponse {
  final String id;
  final Survey survey;
  final DateTime dateCreated;
  final DateTime? dateUpdated;

  DateTime get dateTaken => dateUpdated ?? dateCreated;

  SurveyResponse(this.id, this.survey, this.dateCreated, this.dateUpdated);

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      JsonUtils.stringValue(json["id"]) ?? "",
      Survey.fromJson(json['survey']),
      AppDateTime().dateTimeLocalFromJson(json['date_created']) ?? DateTime.now(),
      AppDateTime().dateTimeLocalFromJson(json['date_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'survey': survey.toJson(),
      'date_created': AppDateTime().dateTimeLocalToJson(dateCreated),
      'date_updated': AppDateTime().dateTimeLocalToJson(dateUpdated),
    };
  }

  static List<SurveyResponse>? listFromJson(List<dynamic>? jsonList) {
    List<SurveyResponse>? result;
    if (jsonList != null) {
      result = <SurveyResponse>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          try {
            ListUtils.add(result, SurveyResponse.fromJson(mapVal));
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    }
    return result;
  }
}

class SurveyAlert {
  final String contactKey;
  final dynamic content;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  SurveyAlert({required this.contactKey, required this.content, this.dateCreated, this.dateUpdated});

  factory SurveyAlert.fromJson(Map<String, dynamic> json) {
    return SurveyAlert(
      contactKey: JsonUtils.stringValue(json['contact_key']) ?? '',
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_key': contactKey,
      'content': content,
    };
  }
}

class Survey extends RuleEngine {
  static const String defaultQuestionKey = 'default';

  @override final String id;
  @override final String type;
  final Map<String, SurveyData> data;
  final bool scored;
  final String title;
  final String? moreInfo;
  final String? defaultDataKey;
  final Rule? defaultDataKeyRule;
  final List<Rule>? resultRules;
  final List<String>? responseKeys;
  DateTime dateCreated;
  DateTime? dateUpdated;
  SurveyStats? stats;

  Survey({required this.id, required this.data, required this.type, this.scored = true, required this.title, this.moreInfo, this.defaultDataKey, this.defaultDataKeyRule, this.resultRules,
    this.responseKeys, this.dateUpdated, required this.dateCreated, this.stats, dynamic resultData, Map<String, dynamic> constants = const {}, Map<String, Map<String, String>> strings = const {}, Map<String, Rule> subRules = const {}})
      : super(constants: constants, strings: strings, subRules: subRules, resultData: resultData);

  factory Survey.fromJson(Map<String, dynamic> json) {
    Map<String, SurveyData> dataMap = {};
    Map<String, dynamic> surveyDataMap = JsonUtils.mapValue(json['data']) ?? {};
    surveyDataMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        dataMap[key] = SurveyData.fromJson(key, value);
      }
    });

    return Survey(
      id: json['id'],
      data: dataMap,
      type: JsonUtils.stringValue(json['type']) ?? '',
      scored: JsonUtils.boolValue(json['scored']) ?? true,
      title: JsonUtils.stringValue(json['title']) ?? 'Survey',
      moreInfo: JsonUtils.stringValue(json['more_info']),
      defaultDataKey: JsonUtils.stringValue(json['default_data_key']),
      defaultDataKeyRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_data_key_rule'])),
      resultRules: JsonUtils.listOrNull((json) => Rule.listFromJson(json), JsonUtils.decode(json['result_rules'])),
      resultData: JsonUtils.decode(json['result_json']),
      responseKeys: JsonUtils.listStringsValue(json['response_keys']),
      dateCreated: AppDateTime().dateTimeLocalFromJson(json['date_created']) ?? DateTime.now(),
      dateUpdated: AppDateTime().dateTimeLocalFromJson(json['date_updated']),
      constants: RuleEngine.constantsFromJson(json),
      strings: RuleEngine.stringsFromJson(json),
      subRules: RuleEngine.subRulesFromJson(json),
      stats: JsonUtils.mapOrNull((json) => SurveyStats.fromJson(json), json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': JsonUtils.encodeMap(data),
      'type': type,
      'scored': scored,
      'title': title,
      'more_info': moreInfo,
      'default_data_key': defaultDataKey,
      'default_data_key_rule': defaultDataKeyRule,
      'result_rules': JsonUtils.encode(Rule.listToJson(resultRules)),
      'result_json': JsonUtils.encode(resultData),
      'response_keys': responseKeys,
      'constants': constants,
      'strings': strings,
      'sub_rules': subRules,
      'date_created': AppDateTime().dateTimeLocalToJson(dateCreated),
      'date_updated': AppDateTime().dateTimeLocalToJson(dateUpdated),
      'stats': stats?.toJson(),
    };
  }

  factory Survey.fromOther(Survey other) {
    Map<String, SurveyData> data = {};
    for (MapEntry<String, SurveyData> surveyData in other.data.entries){
      data[surveyData.key] = (SurveyData.fromOther(surveyData.value));
    }
    return Survey(
      id: other.id,
      data: data,
      type: other.type,
      scored: other.scored,
      title: other.title,
      moreInfo: other.moreInfo,
      defaultDataKey: other.defaultDataKey,
      defaultDataKeyRule: other.defaultDataKeyRule,
      resultRules: other.resultRules,
      resultData: other.resultData,
      responseKeys: other.responseKeys,
      dateCreated: other.dateCreated,
      dateUpdated: other.dateUpdated,
      constants: other.constants,
      strings: other.strings,
      subRules: other.subRules,
      stats: other.stats,
    );
  }

  static List<Survey>? listFromJson(List<dynamic>? jsonList) {
    List<Survey>? result;
    if (jsonList != null) {
      result = <Survey>[];
      for (dynamic jsonEntry in jsonList) {
        Map<String, dynamic>? mapVal = JsonUtils.mapValue(jsonEntry);
        if (mapVal != null) {
          ListUtils.add(result, Survey.fromJson(mapVal));
        }
      }
    }
    return result;
  }

  @override
  dynamic getProperty(RuleKey? key) {
    SurveyStats? stats = this.stats;
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
      case "date_updated":
        return dateUpdated;
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
      case "response_keys":
        return responseKeys;
      case "data":
        RuleKey? dataKey = key?.subRuleKey;
        if (dataKey != null) {
          return data[dataKey.key]?.getProperty(dataKey.subRuleKey, this);
        }
    }
    return super.getProperty(key);
  }

  void evaluate({bool evalResultRules = false}) {
    SurveyStats surveyStats = SurveyStats();
    for (SurveyData? data = firstQuestion; data != null; data = data.followUp(this)) {
      surveyStats += data.stats(this);
    }
    stats = surveyStats;

    if (evalResultRules && CollectionUtils.isNotEmpty(resultRules)) {
      clearCache();
      for (Rule rule in resultRules!) {
        rule.evaluate(this);
      }
    }
  }

  @override
  Future<bool> save() async {
    SurveyResponse? response = await Polls().createSurveyResponse(this);
    if (response != null) {
      return true;
    }
    return false;
  }

  bool canContinue() {
    for (SurveyData? data = firstQuestion; data != null; data = data.followUp(this)) {
      if (!data.canContinue) {
        return false;
      }
    }
    return true;
  }

  SurveyData? get firstQuestion => data[defaultDataKey ?? defaultQuestionKey];
}

class SurveyStats {
  final int total;
  final int complete;

  final int scored;
  final Map<String, num> scores;

  final Map<String, dynamic> responseData;

  SurveyStats({this.total = 0, this.complete = 0, this.scored = 0, this.scores = const {}, this.responseData = const {}});

  factory SurveyStats.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? scoresDynamic = JsonUtils.mapValue(json['scores']);
    Map<String, num> scores = {};
    if (scoresDynamic != null) {
      for (MapEntry<String, dynamic> entry in scoresDynamic.entries) {
        if (entry.value is num) {
          scores[entry.key] = entry.value;
        }
      }
    }
    return SurveyStats(
      total: JsonUtils.intValue(json['total']) ?? 0,
      complete: JsonUtils.intValue(json['complete']) ?? 0,
      scored: JsonUtils.intValue(json['scored']) ?? 0,
      scores: scores,
      responseData: JsonUtils.mapValue(json['response_data']) ?? {},
    );
  }

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
      'response_data': responseData,
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
        return responseData;
    }
    return null;
  }

  num get totalScore => scores.values.fold(0, (partialSum, current) => partialSum + current);
}

abstract class SurveyData {
  final String key;
  final String? section;
  final bool allowSkip;
  final bool replace;
  final String text;
  final String? moreInfo;
  dynamic response;
  
  final String? defaultFollowUpKey;
  final Rule? defaultResponseRule;
  final Rule? followUpRule;
  final Rule? scoreRule;
  SurveyData({required this.key, this.section, required this.text, this.defaultFollowUpKey, this.defaultResponseRule, this.followUpRule, this.scoreRule,
    this.moreInfo, this.response, this.allowSkip = false, this.replace = false});

  factory SurveyData.fromJson(String key, Map<String, dynamic> json) {
    String? surveyType = JsonUtils.stringValue(json["type"]);
    switch (surveyType) {
      case "survey_data.true_false": return SurveyQuestionTrueFalse.fromJson(key, json);
      case "survey_data.multiple_choice": return SurveyQuestionMultipleChoice.fromJson(key, json);
      case "survey_data.date_time": return SurveyQuestionDateTime.fromJson(key, json);
      case "survey_data.numeric": return SurveyQuestionNumeric.fromJson(key, json);
      case "survey_data.text": return SurveyQuestionText.fromJson(key, json);
      case "survey_data.entry": return SurveyDataEntry.fromJson(key, json);
      case "survey_data.result": return SurveyDataResult.fromJson(key, json);
      case "survey_data.survey": return SurveyDataSurvey.fromJson(key, json);
      default:
        throw Exception("Invalid survey data type");
    }
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
    } else if (other is SurveyDataResult) {
      return SurveyDataResult.fromOther(other);
    } else if (other is SurveyDataSurvey) {
      return SurveyDataSurvey.fromOther(other);
    }
    throw Exception("Invalid other survey type");
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() {
    return {
      'key': key,
      'section': section,
      'text': text,
      'more_info': moreInfo,
      'response': response,
      'allow_skip': allowSkip,
      'replace': replace,
      'default_follow_up_key': defaultFollowUpKey,
      'default_response_rule': JsonUtils.encode(defaultResponseRule?.toJson()),
      'follow_up_rule': JsonUtils.encode(followUpRule?.toJson()),
      'score_rule': JsonUtils.encode(scoreRule?.toJson()),
    };
  }

  dynamic getProperty(RuleKey? key, Survey survey) {
    switch (key?.key) {
      case null:
        return this;
      case "response":
        return response;
      case "score":
        return getScore(survey);
    }
    return null;
  }

  bool get isQuestion;

  void evaluateDefaultResponse(Survey survey, {Map<String, dynamic>? defaultResponses, bool deep = true}) {
    if (defaultResponses?[key] != null){
      survey.clearCache();
      response = defaultResponses![key];
    } else if (defaultResponseRule != null) {
      survey.clearCache();
      response = defaultResponseRule!.evaluate(survey);
    }
    if (deep) {
      followUp(survey)?.evaluateDefaultResponse(survey, defaultResponses: defaultResponses);
    }
  }

  SurveyData? followUp(Survey survey) {
    if (followUpRule != null) {
      dynamic result = followUpRule!.evaluate(survey);
      if (result is SurveyData) {
        return result;
      }
    } else {
      return defaultFollowUp(survey);
    }

    return null;
  }

  SurveyData? defaultFollowUp(Survey survey) => defaultFollowUpKey != null ? survey.data[defaultFollowUpKey] : null;

  SurveyStats stats(Survey survey) {
    Map<String, dynamic> responseData = {};
    if (response != null) {
      responseData[key] = response;
    }

    Map<String, num> scores = {};
    num? score = getScore(survey);
    if (score != null) {
      scores[section ?? ''] = score;
    }

    SurveyStats stats = SurveyStats(
      total: isQuestion ? 1 : 0,
      complete: response != null ? 1 : 0,
      scored: scored ? 1 : 0,
      scores: scores,
      responseData: responseData,
    );

    return stats;
  }

  num? getScore(Survey survey) {
    dynamic ruleResult = scoreRule?.evaluate(survey);
    if (ruleResult is num) {
      return ruleResult;
    }
    return null;
  }

  bool get canContinue => allowSkip || response != null;
  bool get scored => scoreRule != null;
}

class SurveyQuestionTrueFalse extends SurveyData {
  final String? style;
  final bool? correctAnswer;
  final List<OptionData> options;

  SurveyQuestionTrueFalse({required String question, this.style, this.correctAnswer, required String key, String? section, String? defaultFollowUpKey,
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false, bool replace = false})
      : options = [OptionData(title: style == "yes_no" ? "Yes" : "True", value: true), OptionData(title: style == "yes_no" ? "No" : "False", value: false)],
        super(allowSkip: allowSkip, replace: replace, key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, 
          followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response);

  factory SurveyQuestionTrueFalse.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionTrueFalse(
      style: JsonUtils.stringValue(json['style']),
      correctAnswer: JsonUtils.boolValue(json['correct_answer']),

      question: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionTrueFalse.fromOther(SurveyQuestionTrueFalse other) {
    return SurveyQuestionTrueFalse(
      key: other.key,
      section: other.section,
      style: other.style,
      correctAnswer: other.correctAnswer,
      question: other.text,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
      allowSkip: other.allowSkip,
      replace: other.replace,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['style'] = style;
    json['correct_answer'] = correctAnswer;
    json['type'] = 'survey_data.true_false';
    return json;
  }

  @override
  dynamic getProperty(RuleKey? key, Survey survey) {
    switch (key?.key) {
      case "correct_answer":
        return correctAnswer;
    }
    return super.getProperty(key, survey);
  }

  @override
  bool get isQuestion => true;
}

class SurveyQuestionMultipleChoice extends SurveyData {
  final List<OptionData> options;
  final List<dynamic>? correctAnswers;
  final bool allowMultiple;
  final bool selfScore;

  SurveyQuestionMultipleChoice({required String question, required this.options, this.correctAnswers, this.allowMultiple = false, this.selfScore = false, required String key, 
    String? section, String? defaultFollowUpKey, Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false, bool replace = false})
      : super(key: key, section: section, allowSkip: allowSkip, replace: replace, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule,
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response);

  factory SurveyQuestionMultipleChoice.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionMultipleChoice(
      options: OptionData.listFromJson(json['options']),
      correctAnswers: json['correct_answers'],
      allowMultiple: JsonUtils.boolValue(json['allow_multiple']) ?? false,
      selfScore: JsonUtils.boolValue(json['self_score']) ?? false,

      question: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
    );
  }

  factory SurveyQuestionMultipleChoice.fromOther(SurveyQuestionMultipleChoice other) {
    return SurveyQuestionMultipleChoice(
      key: other.key,
      section: other.section,
      question: other.text,
      options: other.options,
      correctAnswers: other.correctAnswers,
      allowMultiple: other.allowMultiple,
      selfScore: other.selfScore,
      allowSkip: other.allowSkip,
      replace: other.replace,
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
    json['correct_answers'] = correctAnswers;
    json['allow_multiple'] = allowMultiple;
    json['self_score'] = selfScore;
    json['type'] = 'survey_data.multiple_choice';
    return json;
  }

  @override
  num? getScore(Survey survey) {
    if (scoreRule != null) {
      dynamic ruleResult = scoreRule?.evaluate(survey);
      if (ruleResult is num) {
        return ruleResult;
      }
    } else if (selfScore) {
      num score = 0;
      for (OptionData data in options) {
        if (response is List<dynamic>) {
          if (response.contains(data.value)) {
            score += data.score ?? 0;
          }
        } else if (response == data.value) {
          score += data.score ?? 0;
        }
      }
      return score;
    }
    return null;
  } 

  @override
  dynamic getProperty(RuleKey? key, Survey survey) {
    switch (key?.key) {
      case "correct_answers":
        return correctAnswers;
    }
    return super.getProperty(key, survey);
  }

  @override
  bool get isQuestion => true;

  @override
  bool get scored => scoreRule != null || selfScore;
}

class SurveyQuestionDateTime extends SurveyData {
  final DateTime? startTime;
  final DateTime? endTime;
  final bool askTime;

  SurveyQuestionDateTime({required String question, this.startTime, this.endTime, this.askTime = true, required String key, String? section, String? defaultFollowUpKey, 
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false, bool replace = false})
      : super(key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule,
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip, replace: replace);

  factory SurveyQuestionDateTime.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionDateTime(
      startTime: AppDateTime().dateTimeLocalFromJson(json['star_time']),
      endTime: AppDateTime().dateTimeLocalFromJson(json['end_time']),
      askTime: JsonUtils.boolValue(json['ask_time']) ?? true,

      question: json['text'],
      section: JsonUtils.stringValue(json['section']),
      key: key,
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
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
      replace: other.replace,
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
    json['start_time'] = AppDateTime().dateTimeLocalToJson(startTime);
    json['end_time'] = AppDateTime().dateTimeLocalToJson(endTime);
    json['ask_time'] = askTime;
    json['type'] = 'survey_data.date_time';
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
    String? section, String? defaultFollowUpKey, Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false, bool replace = false})
      : super(key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, followUpRule: followUpRule,
        scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip, replace: replace);

  factory SurveyQuestionNumeric.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionNumeric(
      minimum: JsonUtils.doubleValue(json['minimum']),
      maximum: JsonUtils.doubleValue(json['maximum']),
      wholeNum: JsonUtils.boolValue(json['whole_num']) ?? false,
      slider: JsonUtils.boolValue(json['slider']) ?? false,
      selfScore: JsonUtils.boolValue(json['self_score']) ?? false,

      question: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
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
      replace: other.replace,
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
    json['type'] = 'survey_data.numeric';
    return json;
  }

  @override
  num? getScore(Survey survey) {
    if (scoreRule != null) {
      dynamic ruleResult = scoreRule?.evaluate(survey);
      if (ruleResult is num) {
        return ruleResult;
      }
    } else if (selfScore && response is num) {
      return response;
    }
    return null;
  } 

  @override
  bool get isQuestion => true;

  @override
  bool get scored => scoreRule != null || selfScore;
}

class SurveyQuestionText extends SurveyData {
  final int minLength;
  final int? maxLength;

  SurveyQuestionText({required String question, this.minLength = 0, this.maxLength, required String key, String? section, String? defaultFollowUpKey, 
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool scored = false, bool allowSkip = false, bool replace = false})
      : super(key: key, section: section, text: question, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule,
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip, replace: replace);

  factory SurveyQuestionText.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionText(
      minLength: JsonUtils.intValue(json['min_length']) ?? 0,
      maxLength: JsonUtils.intValue(json['max_length']),

      question: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
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
      replace: other.replace,
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
    json['type'] = 'survey_data.text';
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
    Rule? defaultResponseRule, Rule? followUpRule, Rule? scoreRule, String? moreInfo, dynamic response, bool allowSkip = false, bool replace = false})
      : super(key: key, section:section, defaultFollowUpKey: defaultFollowUpKey, text: text, defaultResponseRule: defaultResponseRule,
        followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, response: response, allowSkip: allowSkip, replace: replace);

  factory SurveyDataEntry.fromJson(String key, Map<String, dynamic> json) {
    Map<String, dynamic>? dataFormatJson = JsonUtils.mapValue(json['data_format']);
    Map<String, DataType> dataFormat = {};
    if (dataFormatJson != null) {
      for (MapEntry<String, dynamic> entry in dataFormatJson.entries) {
        String? type;
        try { DataType.values.byName(entry.value); } catch(e) { debugPrint(e.toString()); }
        dataFormatJson[entry.key] = type;
      }
    }

    return SurveyDataEntry(
      dataFormat: dataFormat,

      text: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
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
      replace: other.replace,
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
    json['type'] = 'survey_data.entry';
    return json;
  }

  @override
  bool get isQuestion => false;
}

class SurveyDataResult extends SurveyData {
  List<ActionData>? actions;

  SurveyDataResult({required String text, this.actions, String? moreInfo, required String key,
    bool replace = false, String? defaultFollowUpKey, Rule? followUpRule}) :
        super(key: key, text: text, moreInfo: moreInfo, allowSkip: true, replace: replace,
        defaultFollowUpKey: defaultFollowUpKey, followUpRule: followUpRule, );

  factory SurveyDataResult.fromJson(String key, Map<String, dynamic> json) {
    return SurveyDataResult(
      actions: ActionData.listFromJson(json['actions']),
      text: json['text'],
      key: key,
      moreInfo: JsonUtils.stringValue(json['more_info']),
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
    );
  }

  factory SurveyDataResult.fromOther(SurveyDataResult other) {
    return SurveyDataResult(
      key: other.key,
      text: other.text,
      actions: other.actions,
      moreInfo: other.moreInfo,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      followUpRule: other.followUpRule,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['actions'] = ActionData.listToJson(actions);
    json['type'] = 'survey_data.result';
    return json;
  }

  @override
  bool get isQuestion => false;
}

class SurveyDataSurvey extends SurveyData {
  Survey survey;

  SurveyDataSurvey({required String text, required this.survey, String? moreInfo, required String key, String? section, String? defaultFollowUpKey, Rule? followUpRule, Rule? scoreRule}) :
        super(key: key, section: section, text: text, moreInfo: moreInfo, allowSkip: true, defaultFollowUpKey: defaultFollowUpKey, followUpRule: followUpRule, scoreRule: scoreRule);

  factory SurveyDataSurvey.fromJson(String key, Map<String, dynamic> json) {
    return SurveyDataSurvey(
      survey: Survey.fromJson(json['survey']),

      key: key,
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
    json['type'] = 'survey_data.survey';
    return json;
  }

  @override
  bool get isQuestion => false;
}
