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
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Surveys with Service {

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

  // Service

  @override
  Future<void> initService() async {
    if (enabled) {
      await super.initService();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Config(), Auth2()};
  }

  // Accessories

  Future<Survey?> loadSurvey(String id) async {
    if (enabled) {
      String url = '${Config().surveysUrl}/surveys/$id';
      Response? response = await Network().get(url, auth: Auth2());
      int responseCode = response?.statusCode ?? -1;
      String? responseBody = response?.body;
      if (responseCode == 200) {
        Map<String, dynamic>? responseMap = JsonUtils.decodeMap(responseBody);
        if (responseMap != null) {
          Survey? survey = Survey.fromJson(responseMap);
          NotificationService().notify(notifySurveyLoaded);
          return survey;
        }
      }
    }
    return null;
  }

  Future<SurveyResponse?> createSurveyResponse(Survey survey) async {
    if (enabled) {
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