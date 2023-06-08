/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/rules.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Surveys service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Surveys /* with Service */ {

  static const String notifySurveyLoaded = "edu.illinois.rokwire.survey.loaded";
  static const String notifySurveyResponseCreated = "edu.illinois.rokwire.survey_response.created";

  // Singletone Factory

  static Surveys? _instance;

  static Surveys? get instance => _instance;

  @protected
  static set instance(Surveys? value) => _instance = value;

  factory Surveys() => _instance ?? (_instance = Surveys.internal());

  @protected
  Surveys.internal();

  // Survey
  
  bool canContinue(Survey survey) {
    for (SurveyData? data = getFirstQuestion(survey); data != null; data = getFollowUp(survey, data)) {
      if (!data.canContinue) {
        return false;
      }
    }
    return true;
  }

  dynamic getProperty(Survey survey, RuleKey? key) {
    SurveyStats? stats = survey.stats;
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
        return survey.dateUpdated;
      case "scored":
        return survey.scored;
      case "type":
        return survey.type;
      case "stats":
        return _getStatsProperty(survey, key?.subRuleKey);
      case "result_data":
        return survey.resultData;
      case "response_keys":
        return survey.responseKeys;
      case "data":
        RuleKey? dataKey = key?.subRuleKey;
        return _getDataProperty(survey, dataKey?.key != null ? survey.data[dataKey!.key] : null, dataKey?.subRuleKey);
    }
    return Rules().getEngineProperty(key);
  }

  Future<dynamic> evaluate(Survey survey, {bool evalResultRules = false, bool summarizeResultRules = false}) async {
    SurveyStats surveyStats = SurveyStats();
    for (SurveyData? data = getFirstQuestion(survey); data != null; data = getFollowUp(survey, data)) {
      surveyStats += _getDataStats(survey, data);
    }
    survey.stats = surveyStats;

    dynamic result;
    List<RuleAction> resultActions = [];
    if (evalResultRules && CollectionUtils.isNotEmpty(survey.resultRules)) {
      Rules().clearDataCache(survey.id);
      for (RuleResult rule in survey.resultRules!) {
        dynamic ruleResult;
        if (rule is RuleActionList) {
          for (RuleAction action in rule.actions) {
            ruleResult = Rules().evaluateAction(survey, action, summarize: summarizeResultRules);
            if (summarizeResultRules) {
              resultActions.add(ruleResult);
            }
          }
        } else {
          ruleResult = Rules().evaluateRuleResult(survey, rule, summarize: summarizeResultRules);
          if (summarizeResultRules) {
            if (ruleResult is Iterable<dynamic>) {
              for (dynamic result in ruleResult) {
                if (result is RuleAction) {
                  resultActions.add(result);
                }
              }
            } else {
              resultActions.add(ruleResult);
            }
          }
        }
        if (ruleResult is Future) {
          ruleResult = await ruleResult;
        }
        if (ruleResult != null) {
          result = ruleResult;
        }
      }
    }
    return summarizeResultRules ? resultActions : result;
  }

  SurveyData? getFirstQuestion(Survey survey) {
    if (survey.defaultDataKeyRule != null) {
      dynamic result = Rules().evaluateRuleResult(survey, survey.defaultDataKeyRule!);
      return result is SurveyData ? result : null;
    }
    return survey.data[survey.defaultDataKey ?? Survey.defaultQuestionKey];
  }

  static Map<String, String> get properties => {
    "completion": "Completion",
    // "scores": "Scores",
    // "date_updated": "Date Updated",
    "scored": "Scored",
    // "type": "Type",
    "result_data": "Result Data",
    // "response_keys": "Response Keys",
    // "auth": "Authentication Info",
  };

  // SurveyStats

  dynamic _getStatsProperty(Survey survey, RuleKey? key) {
    SurveyStats? stats = survey.stats;
    switch (key?.key) {
      case null:
        return this;
      case "total":
        return stats?.total;
      case "complete":
        return stats?.complete;
      case "scored":
        return stats?.scored;
      case "scores":
        return stats?.scores;
      case "maximum_scores":
        return stats?.maximumScores;
      case "percentage":
        String subKey = key?.subKey ?? '';
        if (stats?.scores[subKey] != null && stats?.maximumScores[subKey] != null) {
          return stats!.scores[subKey]! / stats.maximumScores[subKey]!;
        }
        return null;
      case "total_score":
        return stats?.totalScore;
      case "response_data":
        String? subKey = key?.subKey;
        if (subKey != null) {
          return stats?.responseData[subKey];
        }
        return stats?.responseData;
    }
    return null;
  }

  static Map<String, String> get statsProperties => {
    "total": "Total",
    "complete": "Complete",
    "scored": "Scored",
    // "scores": "Scores",
    // "maximum_scores": "Maximum Scores",
    "percentage": "Percentage",
    "total_score": "Total Score",
    // "response_data": "Response Data",
  };

  // SurveyData

  dynamic _getDataProperty(Survey survey, SurveyData? data, RuleKey? key) {
    switch (key?.key) {
      case null:
        return data;
      case "response":
        return data?.response;
      case "score":
        return _getDataScore(survey, data);
      case "maximum_score":
        return data?.maximumScore;
      case "correct_answer":
        return data is SurveyQuestionTrueFalse ? data.correctAnswer : null;
      case "correct_answers":
        return data is SurveyQuestionMultipleChoice ? data.correctAnswers : null;
    }
    return null;
  }


  void evaluateDefaultDataResponse(Survey survey, SurveyData? data, {Map<String, dynamic>? defaultResponses, bool deep = true}) {
    if (data != null) {
      if (defaultResponses?[data.key] != null){
        Rules().clearDataCache(survey.id);
        data.response = defaultResponses![data.key];
      } else if (data.defaultResponseRule != null) {
        Rules().clearDataCache(survey.id);
        data.response = Rules().evaluateRuleResult(survey, data.defaultResponseRule!);
      }
      if (deep) {
        evaluateDefaultDataResponse(survey, getFollowUp(survey, data), defaultResponses: defaultResponses);
      }
    }
  }

  SurveyData? getFollowUp(Survey survey, SurveyData? data) {
    if (data?.followUpRule != null) {
      dynamic result = Rules().evaluateRuleResult(survey, data!.followUpRule!);
      if (result is SurveyData) {
        return result;
      }
    }
    return data?.defaultFollowUpKey != null ? survey.data[data!.defaultFollowUpKey] : null;
  }

  SurveyStats _getDataStats(Survey survey, SurveyData data) {
    Map<String, dynamic> responseData = {};
    if (data.response != null) {
      responseData[data.key] = data.response;
    }

    Map<String, num> scores = {};
    num? score = _getDataScore(survey, data);
    if (score != null) {
      if (CollectionUtils.isNotEmpty(data.sections)) {
        for (String section in data.sections!) {
          scores[section] = score;
        }
      } else {
        scores[data.section ?? ''] = score;
      }
    }
    Map<String, num> maximumScores = {};
    if (data.maximumScore != null) {
      if (CollectionUtils.isNotEmpty(data.sections)) {
        for (String section in data.sections!) {
          maximumScores[section] = data.maximumScore!;
        }
      } else {
        maximumScores[data.section ?? ''] = data.maximumScore!;
      }
    }

    SurveyStats stats = SurveyStats(
      total: data.isQuestion ? 1 : 0,
      complete: data.response != null ? 1 : 0,
      scored: data.scored ? 1 : 0,
      scores: scores,
      maximumScores: maximumScores,
      responseData: responseData,
    );

    return stats;
  }

  num? _getDataScore(Survey survey, SurveyData? data) {
    if (data?.scoreRule != null) {
      dynamic ruleResult = Rules().evaluateRuleResult(survey, data!.scoreRule!);
      if (ruleResult is num) {
        return ruleResult;
      }
    } else if (data is SurveyQuestionMultipleChoice && data.selfScore) {
      num score = 0;
      for (OptionData option in data.options) {
        if (data.response is List<dynamic>) {
          if (data.response.contains(option.responseValue)) {
            score += option.score ?? 0;
          }
        } else if (data.response == option.responseValue) {
          score += option.score ?? 0;
        }
      }
      return score;
    } else if (data is SurveyQuestionNumeric && data.selfScore && data.response is num) {
      return data.response;
    }
    return null;
  }

  static Map<String, String> get dataProperties => {
    "response": "Response",
    "score": "Score",
    "maximum_score": "Maximum Score",
    "correct_answer": "Correct Answer",
    "correct_answers": "Correct Answers",
  };

  // Accessories

  Future<List<Survey>?> loadCreatorSurveys() async {
    if (enabled) {
      String url = '${Config().surveysUrl}/creator/surveys';
      Response? response = await Network().get(url, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if (responseCode == 200) {
        List<dynamic>? responseList = JsonUtils.decodeList(responseBody);
        if (responseList != null) {
          List<Survey>? surveys = Survey.listFromJson(responseList);
          return surveys;
        }
      }
    }
    return null;
  }

  Future<Survey?> loadSurvey(String id) async {
    if (enabled) {
      String url = '${Config().surveysUrl}/surveys/$id';
      Response? response = await Network().get(url, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if (responseCode == 200) {
        Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseBody);
        if (responseMap != null) {
          Survey survey = Survey.fromJson(responseMap);
          NotificationService().notify(notifySurveyLoaded);
          return survey;
        }
      }
    }
    return null;
  }

  Future<bool?> createSurvey(Survey survey) async {
    if (enabled) {
      String url = '${Config().surveysUrl}/surveys';
      Response? response = await Network().post(url, body: JsonUtils.encode(survey.toJson()), auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      if (responseCode == 200) {
        return true;
      }
      String? responseBody = response?.body;
      debugPrint(responseBody);
      return false;
    }
    return null;
  }

  Future<bool?> updateSurvey(Survey survey) async {
    if (enabled) {
      String url = '${Config().surveysUrl}/surveys/${survey.id}';
      Response? response = await Network().put(url, body: JsonUtils.encode(survey.toJson()), auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      if (responseCode == 200) {
        return true;
      }
      String? responseBody = response?.body;
      debugPrint(responseBody);
      return false;
    }
    return null;
  }

  Future<SurveyResponse?> createSurveyResponse(Survey survey) async {
    if (enabled && Storage().assessmentsSaveResultsMap?[survey.type] != false) {
      String? body = JsonUtils.encode(survey.toJson());
      String url = '${Config().surveysUrl}/survey-responses';
      Response? response = await Network().post(url, body: body, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseString = response?.body;
      if ((response != null) && (responseCode == 200)) {
        Map<String, dynamic>? responseJson = JsonUtils.decode(responseString);
        if (responseJson != null) {
          SurveyResponse? response = SurveyResponse.fromJson(responseJson);
          NotificationService().notify(notifySurveyResponseCreated);
          return response;
        }
      }
    }
    return null;
  }

  Future<List<SurveyResponse>?> loadSurveyResponses(
      {List<String>? surveyIDs, List<
          String>? surveyTypes, DateTime? startDate, DateTime? endDate, int? limit, int? offset}) async {
    if (enabled) {
      Map<String, String> queryParams = {};
      if (CollectionUtils.isNotEmpty(surveyIDs)) {
        queryParams['survey_ids'] = surveyIDs!.join(',');
      }
      if (CollectionUtils.isNotEmpty(surveyTypes)) {
        queryParams['survey_types'] = surveyTypes!.join(',');
      }
      if (startDate != null) {
        String? startDateFormatted = AppDateTime().dateTimeLocalToJson(
            startDate);
        queryParams['start_date'] = startDateFormatted!;
      }
      if (endDate != null) {
        String? endDateFormatted = AppDateTime().dateTimeLocalToJson(endDate);
        queryParams['end_date'] = endDateFormatted!;
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }

      String url = '${Config().surveysUrl}/survey-responses';
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      Response? response = await Network().get(url, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if (responseCode == 200) {
        List<dynamic>? responseMap = JsonUtils.decodeList(responseBody);
        if (responseMap != null) {
          List<SurveyResponse>? surveys = SurveyResponse.listFromJson(
              responseMap);
          return surveys;
        }
      }
    }
    return null;
  }

  Future<bool> deleteSurveyResponses({List<String>? surveyIDs, List<
      String>? surveyTypes, DateTime? startDate, DateTime? endDate}) async {
    if (enabled) {
      Map<String, String> queryParams = {};
      if (CollectionUtils.isNotEmpty(surveyIDs)) {
        queryParams['survey_ids'] = surveyIDs!.join(',');
      }
      if (CollectionUtils.isNotEmpty(surveyTypes)) {
        queryParams['survey_types'] = surveyTypes!.join(',');
      }
      if (startDate != null) {
        String? startDateFormatted = AppDateTime().dateTimeLocalToJson(
            startDate);
        queryParams['start_date'] = startDateFormatted!;
      }
      if (endDate != null) {
        String? endDateFormatted = AppDateTime().dateTimeLocalToJson(endDate);
        queryParams['end_date'] = endDateFormatted!;
      }

      String url = '${Config().surveysUrl}/survey-responses';
      if (queryParams.isNotEmpty) {
        url = UrlUtils.addQueryParameters(url, queryParams);
      }
      Response? response = await Network().delete(url, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      return responseCode == 200;
    }
    return false;
  }

  Future<bool> createSurveyAlert(SurveyAlert alert) async {
    if (enabled) {
      String? body = JsonUtils.encode(alert.toJson());
      String url = '${Config().surveysUrl}/survey-alerts';
      Response? response = await Network().post(url, body: body, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      return (response != null) && (responseCode == 200);
    }
    return false;
  }

  /////////////////////////
  // Enabled

  bool get enabled => StringUtils.isNotEmpty(Config().surveysUrl);
}