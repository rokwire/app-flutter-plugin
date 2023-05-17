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

// TODO: Add localization support
class Survey extends RuleEngine {
  static const String defaultQuestionKey = 'default';

  @override final String id;
  @override final String type;
  final Map<String, SurveyData> data;
  final bool scored;
  final String title;
  final String? moreInfo;
  final String? defaultDataKey;
  final RuleResult? defaultDataKeyRule;
  final List<RuleResult>? resultRules;
  final List<String>? responseKeys;
  DateTime? dateCreated;
  DateTime? dateUpdated;
  SurveyStats? stats;

  Survey({required this.id, required this.data, required this.type, this.scored = true, required this.title, this.moreInfo, this.defaultDataKey, this.defaultDataKeyRule, this.resultRules,
    this.responseKeys, this.dateUpdated, this.dateCreated, this.stats, dynamic resultData, Map<String, dynamic> constants = const {}, Map<String, Map<String, String>> strings = const {}, Map<String, Rule> subRules = const {}})
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
      defaultDataKeyRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['default_data_key_rule'])),
      resultRules: JsonUtils.listOrNull((json) => RuleResult.listFromJson(json), JsonUtils.decode(json['result_rules'])),
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
    List<Map<String, dynamic>> resultRulesJson = RuleResult.listToJson(resultRules);
    String? encodedJson = JsonUtils.encode(resultRulesJson);
    return {
      'id': id,
      'data': JsonUtils.encodeMap(data),
      'type': type,
      'scored': scored,
      'title': title,
      'more_info': moreInfo,
      'default_data_key': defaultDataKey,
      'default_data_key_rule': defaultDataKeyRule,
      'result_rules': encodedJson,
      'result_json': JsonUtils.encode(resultData),
      'response_keys': responseKeys,
      'constants': constants,
      'strings': strings,
      'sub_rules': RuleEngine.subRulesToJson(subRules),
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
      defaultDataKeyRule: other.defaultDataKeyRule != null ? RuleResult.fromOther(other.defaultDataKeyRule!) : null,
      resultRules: other.resultRules != null ? List.from(other.resultRules!) : null,
      resultData: other.resultData is Map ? Map.from(other.resultData) : (other.resultData is Iterable ? List.from(other.resultData) : other.resultData),
      responseKeys: other.responseKeys != null ? List.from(other.responseKeys!) : null,
      dateCreated: other.dateCreated,
      dateUpdated: other.dateUpdated,
      constants: Map.of(other.constants),
      strings: Map.of(other.strings),
      subRules: Map.of(other.subRules),
      stats: other.stats != null ? SurveyStats.fromOther(other.stats!) : null,
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
}

class SurveyStats {
  final int total;
  final int complete;

  final int scored;
  final Map<String, num> scores;
  final Map<String, num> maximumScores;

  final Map<String, dynamic> responseData;

  SurveyStats({this.total = 0, this.complete = 0, this.scored = 0, this.scores = const {}, this.maximumScores = const {}, this.responseData = const {}});

  factory SurveyStats.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? scoresDynamic = JsonUtils.mapValue(json['scores']);
    Map<String, dynamic>? maxScoresDynamic = JsonUtils.mapValue(json['maximum_scores']);

    Map<String, num> scores = {};
    if (scoresDynamic != null) {
      for (MapEntry<String, dynamic> entry in scoresDynamic.entries) {
        if (entry.value is num) {
          scores[entry.key] = entry.value;
        }
      }
    }
    Map<String, num> maxScores = {};
    if (maxScoresDynamic != null) {
      for (MapEntry<String, dynamic> entry in maxScoresDynamic.entries) {
        if (entry.value is num) {
          maxScores[entry.key] = entry.value;
        }
      }
    }
    return SurveyStats(
      total: JsonUtils.intValue(json['total']) ?? 0,
      complete: JsonUtils.intValue(json['complete']) ?? 0,
      scored: JsonUtils.intValue(json['scored']) ?? 0,
      scores: scores,
      maximumScores: maxScores,
      responseData: JsonUtils.mapValue(json['response_data']) ?? {},
    );
  }

  factory SurveyStats.fromOther(SurveyStats other) {
    return SurveyStats(
      total: other.total,
      complete: other.complete,
      scored: other.scored,
      scores: Map.of(other.scores),
      maximumScores: Map.of(other.maximumScores),
      responseData: Map.of(other.responseData),
    );
  }

  SurveyStats operator +(SurveyStats other) {
    Map<String, dynamic> newData = {};
    newData.addAll(responseData);
    newData.addAll(other.responseData);

    Map<String, num> newScores = {};
    newScores.addAll(scores);
    other.scores.forEach((key, value) {
      newScores[key] = (newScores[key] ?? 0) + value;
    });
    Map<String, num> newMaxScores = {};
    newMaxScores.addAll(maximumScores);
    other.maximumScores.forEach((key, value) {
      newMaxScores[key] = (newMaxScores[key] ?? 0) + value;
    });

    return SurveyStats(
      total: total + other.total,
      complete: complete + other.complete,
      scored: scored + other.scored,
      scores: newScores,
      maximumScores: newMaxScores,
      responseData: newData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'complete': complete,
      'scored': scored,
      'scores': scores,
      'maximum_scores': maximumScores,
      'response_data': responseData,
    };
  }

  num get totalScore => scores.values.fold(0, (partialSum, current) => partialSum + current);

  Map<String, num> get percentages {
    Map<String, num> percentageMap = {};
    for (MapEntry<String, num> score in scores.entries) {
      if (maximumScores[score.key] != null) {
        percentageMap[score.key] = score.value / maximumScores[score.key]!;
      }
    }
    return percentageMap;
  }
}

abstract class SurveyData {
  String key;
  String? section;
  List<String>? sections;
  bool allowSkip;
  bool replace;
  String text;
  String? moreInfo;
  String? style;
  dynamic response;
  
  String? defaultFollowUpKey;
  RuleResult? defaultResponseRule;
  RuleResult? followUpRule;
  RuleResult? scoreRule;
  num? _maximumScore;
  SurveyData({required this.key, this.section, this.sections, required this.text, this.defaultFollowUpKey, this.defaultResponseRule, this.followUpRule, this.scoreRule,
    this.moreInfo, this.style, this.response, this.allowSkip = false, this.replace = false, num? maximumScore}) : _maximumScore = maximumScore;

  factory SurveyData.fromJson(String key, Map<String, dynamic> json) {
    String? surveyType = JsonUtils.stringValue(json["type"]);
    switch (surveyType) {
      case "survey_data.true_false": return SurveyQuestionTrueFalse.fromJson(key, json);
      case "survey_data.multiple_choice": return SurveyQuestionMultipleChoice.fromJson(key, json);
      case "survey_data.date_time": return SurveyQuestionDateTime.fromJson(key, json);
      case "survey_data.numeric": return SurveyQuestionNumeric.fromJson(key, json);
      case "survey_data.text": return SurveyQuestionText.fromJson(key, json);
      // case "survey_data.entry": return SurveyDataEntry.fromJson(key, json);
      case "survey_data.result": return SurveyDataResult.fromJson(key, json);
      // case "survey_data.page": return SurveyDataPage.fromJson(key, json);
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
    } else if (other is SurveyDataResult) {
      return SurveyDataResult.fromOther(other);
    }
    // else if (other is SurveyDataPage) {
    //   return SurveyDataPage.fromOther(other);
    // } else if (other is SurveyDataEntry) {
    //   return SurveyDataEntry.fromOther(other);
    // }
    throw Exception("Invalid other survey type");
  }

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() {
    return {
      'key': key,
      'section': section,
      'sections': sections,
      'text': text,
      'more_info': moreInfo,
      'response': response,
      'allow_skip': allowSkip,
      'replace': replace,
      'style': style,
      'default_follow_up_key': defaultFollowUpKey,
      'default_response_rule': JsonUtils.encode(defaultResponseRule?.toJson()),
      'follow_up_rule': JsonUtils.encode(followUpRule?.toJson()),
      'score_rule': JsonUtils.encode(scoreRule?.toJson()),
    };
  }

  static Map<String, String> get supportedTypes => const {
    "survey_data.true_false": "True/False",
    "survey_data.multiple_choice": "Multiple Choice",
    "survey_data.date_time": "Date/Time",
    "survey_data.numeric": "Numeric",
    "survey_data.text": "Text",
    "survey_data.info": "Info",
    // "survey_data.action": "Action" // do not include because not allowed to switch to or from this type
  };

  bool get isQuestion;
  bool get canContinue => allowSkip || response != null;
  bool get scored => scoreRule != null;
  bool get isAction => false;
  String get type;

  num? get maximumScore {
    if (_maximumScore == null) {
      if (scoreRule != null) {
        num maxScore = double.negativeInfinity;
        for (RuleAction scoreAction in scoreRule!.possibleActions) {
          if (scoreAction.data is num && scoreAction.data > maxScore) {
            maxScore = scoreAction.data;
          }
        }
        return _maximumScore = maxScore;
      }
      return _maximumScore = null;
    }
    return _maximumScore;
  }
}

class SurveyQuestionTrueFalse extends SurveyData {
  bool? correctAnswer;
  final List<OptionData> options;

  SurveyQuestionTrueFalse({required String text, this.correctAnswer, required String key, String? section, List<String>? sections, String? defaultFollowUpKey, RuleResult? defaultResponseRule,
    RuleResult? followUpRule, RuleResult? scoreRule, String? moreInfo, String? style, dynamic response, bool allowSkip = false, bool replace = false, num? maximumScore})
      : options = [OptionData(title: style == "yes_no" ? "Yes" : "True", value: true), OptionData(title: style == "yes_no" ? "No" : "False", value: false)],
        super(allowSkip: allowSkip, replace: replace, key: key, section: section, sections: sections, text: text, defaultFollowUpKey: defaultFollowUpKey,
          defaultResponseRule: defaultResponseRule, followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, style: style, response: response, maximumScore: maximumScore);

  factory SurveyQuestionTrueFalse.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionTrueFalse(
      correctAnswer: JsonUtils.boolValue(json['correct_answer']),

      text: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      sections: JsonUtils.stringListValue(json['sections']),
      response: json['response'] ?? false,
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyQuestionTrueFalse.fromOther(SurveyQuestionTrueFalse other) {
    return SurveyQuestionTrueFalse(
      key: other.key,
      section: other.section,
      sections: other.sections != null ? List.from(other.sections!) : null,
      correctAnswer: other.correctAnswer,
      text: other.text,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule != null ? RuleResult.fromOther(other.defaultResponseRule!) : null,
      followUpRule: other.followUpRule != null ? RuleResult.fromOther(other.followUpRule!) : null,
      scoreRule: other.scoreRule != null ? RuleResult.fromOther(other.scoreRule!) : null,
      moreInfo: other.moreInfo,
      allowSkip: other.allowSkip,
      replace: other.replace,
      style: other.style,
      maximumScore: other.maximumScore,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['correct_answer'] = correctAnswer;
    json['type'] = type;
    return json;
  }

  static Map<String, String> get supportedStyles => const {
    "true_false": "True/False",
    "yes_no": "Yes/No",
    "toggle": "Toggle",
    "checkbox": "Checkbox",
  };

  @override
  bool get isQuestion => true;

  @override
  String get type => 'survey_data.true_false';
}

class SurveyQuestionMultipleChoice extends SurveyData {
  List<OptionData> options;
  List<dynamic>? correctAnswers;
  bool allowMultiple;
  bool selfScore;

  SurveyQuestionMultipleChoice({required String text, required this.options, this.correctAnswers, this.allowMultiple = false, this.selfScore = false, required String key, String? section, List<String>? sections,
    String? defaultFollowUpKey, RuleResult? defaultResponseRule, RuleResult? followUpRule, RuleResult? scoreRule, String? moreInfo, String? style, dynamic response, bool allowSkip = false, bool replace = false, num? maximumScore})
      : super(key: key, section: section, sections: sections, allowSkip: allowSkip, replace: replace, text: text, defaultFollowUpKey: defaultFollowUpKey,
        defaultResponseRule: defaultResponseRule, followUpRule: followUpRule, scoreRule: scoreRule, moreInfo: moreInfo, style: style, response: response, maximumScore: maximumScore);

  factory SurveyQuestionMultipleChoice.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionMultipleChoice(
      options: OptionData.listFromJson(json['options']),
      correctAnswers: json['correct_answers'],
      allowMultiple: JsonUtils.boolValue(json['allow_multiple']) ?? false,
      selfScore: JsonUtils.boolValue(json['self_score']) ?? false,

      text: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      sections: JsonUtils.stringListValue(json['sections']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyQuestionMultipleChoice.fromOther(SurveyQuestionMultipleChoice other) {
    return SurveyQuestionMultipleChoice(
      key: other.key,
      section: other.section,
      sections: other.sections != null ? List.from(other.sections!) : null,
      text: other.text,
      options: List.generate(other.options.length, (index) => OptionData.fromOther(other.options[index])),
      correctAnswers: other.correctAnswers != null ? List.from(other.correctAnswers!) : null,
      allowMultiple: other.allowMultiple,
      selfScore: other.selfScore,
      allowSkip: other.allowSkip,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule != null ? RuleResult.fromOther(other.defaultResponseRule!) : null,
      followUpRule: other.followUpRule != null ? RuleResult.fromOther(other.followUpRule!) : null,
      scoreRule: other.scoreRule != null ? RuleResult.fromOther(other.scoreRule!) : null,
      moreInfo: other.moreInfo,
      style: other.style,
      maximumScore: other.maximumScore,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['options'] = JsonUtils.encodeList(options);
    json['correct_answers'] = correctAnswers;
    json['allow_multiple'] = allowMultiple;
    json['self_score'] = selfScore;
    json['type'] = type;
    return json;
  }

  static Map<String, String> get supportedStyles => const {
    "vertical": "Vertical",
    "horizontal": "Horizontal",
  };

  @override
  bool get isQuestion => true;

  @override
  bool get scored => scoreRule != null || selfScore;

  @override
  String get type => 'survey_data.multiple_choice';

  @override
  num? get maximumScore {
    num? scoreRuleMax = super.maximumScore;
    if (scoreRuleMax == null && selfScore) {
      num maxScore = double.negativeInfinity;
      for (OptionData scoreOption in options) {
        if (scoreOption.score is num && scoreOption.score! > maxScore) {
          maxScore = scoreOption.score!;
        }
      }
      return maxScore;
    }
    return scoreRuleMax;
  }
}

class SurveyQuestionDateTime extends SurveyData {
  DateTime? startTime;
  DateTime? endTime;
  bool askTime;

  SurveyQuestionDateTime({required String text, this.startTime, this.endTime, this.askTime = true, required String key, String? section, List<String>? sections, String? defaultFollowUpKey,
    RuleResult? defaultResponseRule, RuleResult? followUpRule, RuleResult? scoreRule, String? moreInfo, String? style, dynamic response, bool allowSkip = false, bool replace = false, num? maximumScore})
      : super(key: key, section: section, sections: sections, text: text, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, followUpRule: followUpRule,
        scoreRule: scoreRule, moreInfo: moreInfo, style: style, response: response, allowSkip: allowSkip, replace: replace, maximumScore: maximumScore);

  factory SurveyQuestionDateTime.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionDateTime(
      startTime: AppDateTime().dateTimeLocalFromJson(json['star_time']),
      endTime: AppDateTime().dateTimeLocalFromJson(json['end_time']),
      askTime: JsonUtils.boolValue(json['ask_time']) ?? true,

      text: json['text'],
      section: JsonUtils.stringValue(json['section']),
      sections: JsonUtils.stringListValue(json['sections']),
      key: key,
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyQuestionDateTime.fromOther(SurveyQuestionDateTime other) {
    return SurveyQuestionDateTime(
      key: other.key,
      section: other.section,
      sections: other.sections != null ? List.from(other.sections!) : null,
      text: other.text,
      startTime: other.startTime,
      endTime: other.endTime,
      askTime: other.askTime,
      allowSkip: other.allowSkip,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule != null ? RuleResult.fromOther(other.defaultResponseRule!) : null,
      followUpRule: other.followUpRule != null ? RuleResult.fromOther(other.followUpRule!) : null,
      scoreRule: other.scoreRule != null ? RuleResult.fromOther(other.scoreRule!) : null,
      moreInfo: other.moreInfo,
      style: other.style,
      maximumScore: other.maximumScore,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['start_time'] = AppDateTime().dateTimeLocalToJson(startTime);
    json['end_time'] = AppDateTime().dateTimeLocalToJson(endTime);
    json['ask_time'] = askTime;
    json['type'] = type;
    return json;
  }

  @override
  bool get isQuestion => true;

  @override
  String get type => 'survey_data.date_time';
}

class SurveyQuestionNumeric extends SurveyData {
  double? minimum;
  double? maximum;
  bool wholeNum;
  bool selfScore;

  SurveyQuestionNumeric({required String text, this.minimum, this.maximum, this.wholeNum = false, this.selfScore = false, required String key, String? section, List<String>? sections, String? defaultFollowUpKey, 
    RuleResult? defaultResponseRule, RuleResult? followUpRule, RuleResult? scoreRule, String? moreInfo, String? style, dynamic response, bool allowSkip = false, bool replace = false, num? maximumScore})
      : super(key: key, section: section, sections: sections, text: text, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, followUpRule: followUpRule,
        scoreRule: scoreRule, moreInfo: moreInfo, style: style, response: response, allowSkip: allowSkip, replace: replace, maximumScore: maximumScore);

  factory SurveyQuestionNumeric.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionNumeric(
      minimum: JsonUtils.doubleValue(json['minimum']),
      maximum: JsonUtils.doubleValue(json['maximum']),
      wholeNum: JsonUtils.boolValue(json['whole_num']) ?? false,
      selfScore: JsonUtils.boolValue(json['self_score']) ?? false,

      text: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      sections: JsonUtils.stringListValue(json['sections']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyQuestionNumeric.fromOther(SurveyQuestionNumeric other) {
    return SurveyQuestionNumeric(
      key: other.key,
      section: other.section,
      sections: other.sections != null ? List.from(other.sections!) : null,
      text: other.text,
      minimum: other.minimum,
      maximum: other.maximum,
      wholeNum: other.wholeNum,
      selfScore: other.selfScore,
      allowSkip: other.allowSkip,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule != null ? RuleResult.fromOther(other.defaultResponseRule!) : null,
      followUpRule: other.followUpRule != null ? RuleResult.fromOther(other.followUpRule!) : null,
      scoreRule: other.scoreRule != null ? RuleResult.fromOther(other.scoreRule!) : null,
      moreInfo: other.moreInfo,
      style: other.style,
      maximumScore: other.maximumScore,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['minimum'] = minimum;
    json['maximum'] = maximum;
    json['whole_num'] = wholeNum;
    json['self_score'] = selfScore;
    json['type'] = type;
    return json;
  }

  static Map<String, String> get supportedStyles => const {
    "text": "Text",
    "slider": "Slider",
  };

  @override
  bool get isQuestion => true;

  @override
  bool get scored => scoreRule != null || selfScore;

  @override
  String get type => 'survey_data.numeric';

  @override
  num? get maximumScore {
    num? scoreRuleMax = super.maximumScore;
    if (scoreRuleMax == null && selfScore) {
      return maximum;
    }
    return scoreRuleMax;
  }
}

class SurveyQuestionText extends SurveyData {
  int minLength;
  int? maxLength;

  SurveyQuestionText({required String text, this.minLength = 0, this.maxLength, required String key, String? section, List<String>? sections, String? defaultFollowUpKey, RuleResult? defaultResponseRule, 
    RuleResult? followUpRule, RuleResult? scoreRule, String? moreInfo, String? style, dynamic response, bool scored = false, bool allowSkip = false, bool replace = false, num? maximumScore})
      : super(key: key, section: section, sections: sections, text: text, defaultFollowUpKey: defaultFollowUpKey, defaultResponseRule: defaultResponseRule, followUpRule: followUpRule,
        scoreRule: scoreRule, moreInfo: moreInfo, style: style, response: response, allowSkip: allowSkip, replace: replace, maximumScore: maximumScore);

  factory SurveyQuestionText.fromJson(String key, Map<String, dynamic> json) {
    return SurveyQuestionText(
      minLength: JsonUtils.intValue(json['min_length']) ?? 0,
      maxLength: JsonUtils.intValue(json['max_length']),

      text: json['text'],
      key: key,
      section: JsonUtils.stringValue(json['section']),
      sections: JsonUtils.stringListValue(json['sections']),
      scored: json['scored'],
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyQuestionText.fromOther(SurveyQuestionText other) {
    return SurveyQuestionText(
      key: other.key,
      section: other.section,
      sections: other.sections != null ? List.from(other.sections!) : null,
      text: other.text,
      minLength: other.minLength,
      maxLength: other.maxLength,
      allowSkip: other.allowSkip,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule != null ? RuleResult.fromOther(other.defaultResponseRule!) : null,
      followUpRule: other.followUpRule != null ? RuleResult.fromOther(other.followUpRule!) : null,
      scoreRule: other.scoreRule != null ? RuleResult.fromOther(other.scoreRule!) : null,
      moreInfo: other.moreInfo,
      style: other.style,
      maximumScore: other.maximumScore,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['min_length'] = minLength;
    json['max_length'] = maxLength;
    json['type'] = type;
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

  @override
  String get type => 'survey_data.text';
}

/*
enum DataType { int, double, bool, string, date }

class SurveyDataEntry extends SurveyData {
  final Map<String, DataType> dataFormat;

  SurveyDataEntry({required String text, required this.dataFormat, required String key, String? section, List<String>? sections, String? defaultFollowUpKey, Rule? defaultResponseRule,
    Rule? followUpRule, Rule? scoreRule, String? moreInfo, String? style, dynamic response, bool allowSkip = false, bool replace = false, num? maximumScore})
      : super(key: key, section: section, sections: sections, defaultFollowUpKey: defaultFollowUpKey, text: text, defaultResponseRule: defaultResponseRule, followUpRule: followUpRule, 
        scoreRule: scoreRule, moreInfo: moreInfo, style: style, response: response, allowSkip: allowSkip, replace: replace, maximumScore: maximumScore);

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
      sections: JsonUtils.stringListValue(json['sections']),
      response: json['response'],
      allowSkip: JsonUtils.boolValue(json['allow_skip']) ?? false,
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      defaultResponseRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['default_response_rule'])),
      followUpRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      scoreRule: JsonUtils.mapOrNull((json) => Rule.fromJson(json), JsonUtils.decode(json['score_rule'])),
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyDataEntry.fromOther(SurveyDataEntry other) {
    return SurveyDataEntry(
      key: other.key,
      section: other.section,
      sections: other.sections != null ? List.from(other.sections!) : null,
      text: other.text,
      dataFormat: other.dataFormat,
      allowSkip: other.allowSkip,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      defaultResponseRule: other.defaultResponseRule,
      followUpRule: other.followUpRule,
      scoreRule: other.scoreRule,
      moreInfo: other.moreInfo,
      style: other.style,
      maximumScore: other.maximumScore,
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
*/

class SurveyDataResult extends SurveyData {
  List<ActionData>? actions;

  SurveyDataResult({required String text, this.actions, String? moreInfo, required String key,
    bool replace = false, String? defaultFollowUpKey, RuleResult? followUpRule, String? style}) :
        super(key: key, text: text, moreInfo: moreInfo, allowSkip: true, replace: replace,
        defaultFollowUpKey: defaultFollowUpKey, followUpRule: followUpRule, style: style);

  factory SurveyDataResult.fromJson(String key, Map<String, dynamic> json) {
    return SurveyDataResult(
      actions: ActionData.listFromJson(json['actions']),
      text: json['text'],
      key: key,
      moreInfo: JsonUtils.stringValue(json['more_info']),
      replace: JsonUtils.boolValue(json['replace']) ?? false,
      defaultFollowUpKey: JsonUtils.stringValue(json['default_follow_up_key']),
      followUpRule: JsonUtils.mapOrNull((json) => RuleResult.fromJson(json), JsonUtils.decode(json['follow_up_rule'])),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyDataResult.fromOther(SurveyDataResult other) {
    return SurveyDataResult(
      key: other.key,
      text: other.text,
      actions: other.actions != null ? List.generate(other.actions!.length, (index) => ActionData.fromOther(other.actions![index])) : null,
      moreInfo: other.moreInfo,
      replace: other.replace,
      defaultFollowUpKey: other.defaultFollowUpKey,
      followUpRule: other.followUpRule != null ? RuleResult.fromOther(other.followUpRule!) : null,
      style: other.style,
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

  @override
  bool get isAction => actions != null;

  @override
  String get type => actions != null ? 'survey_data.action' : 'survey_data.info';
}

/*
class SurveyDataPage extends SurveyData {
  List<String> dataKeys;

  SurveyDataPage({required String text, required this.dataKeys, String? moreInfo, bool allowSkip = false, String? style, required String key, String? defaultFollowUpKey, Rule? followUpRule, Rule? scoreRule}) :
    super(key: key, text: text, moreInfo: moreInfo, allowSkip: allowSkip, style: style, defaultFollowUpKey: defaultFollowUpKey, followUpRule: followUpRule, scoreRule: scoreRule);

  factory SurveyDataPage.fromJson(String key, Map<String, dynamic> json) {
    return SurveyDataPage(
      dataKeys: JsonUtils.stringListValue(json['data_keys']) ?? [],

      key: key,
      text: json['text'],
      moreInfo: JsonUtils.stringValue(json['more_info']),
      style: JsonUtils.stringValue(json['style']),
    );
  }

  factory SurveyDataPage.fromOther(SurveyDataPage other) {
    return SurveyDataPage(
      key: other.key,
      dataKeys: other.dataKeys,
      text: other.text,
      moreInfo: other.moreInfo,
      style: other.style,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = baseJson();
    json['data_keys'] = dataKeys;
    json['type'] = 'survey_data.page';
    return json;
  }

  @override
  bool get isQuestion => false;
}
*/

enum SurveyElement { questionData, actionData, sections, followUpRules, resultRules, defaultResponseRule, scoreRule }