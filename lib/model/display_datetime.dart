/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

abstract class DisplayDateTime {

  DateTime? get startDateTimeUtcValue;
  DateTime? get endDateTimeUtcValue;
  bool? get isAllDay;

  ////////////////////////////////////////

  String? get shortDisplayDateAndTime => _buildDisplayDateAndTime(longFormat: false);
  String? get longDisplayDateAndTime => _buildDisplayDateAndTime(longFormat: true);

  String? get shortDisplayDate => _buildDisplayDate(longFormat: false);
  String? get longDisplayDate => _buildDisplayDate(longFormat: true);

  String? get shortDisplayTime => _buildDisplayTime(longFormat: false);
  String? get longDisplayTime => _buildDisplayTime(longFormat: true);

  String? _buildDisplayDateAndTime({bool longFormat = false}) {
    if (startDateTimeUtcValue != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = startDateTimeUtcValue!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endDateTimeUtcValue?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowUni.year != startDateTimeUni.year);
      String startDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {

        String displayDay;
        switch(statDaysDiff) {
          case 0: displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today'); break;
          case 1: displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow'); break;
          default: displayDay = DateFormat(startDateFormat).format(startDateTimeUni);
        }

        if (isAllDay != true) {
          String displayStartTime = DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
          if ((endDateTimeUni != null) && (TimeOfDay.fromDateTime(startDateTimeUni) != TimeOfDay.fromDateTime(endDateTimeUni))) {
            String displayEndTime = DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
            return Localization().getStringEx('model.explore.date_time.from_to.format', '{{day}} from {{start_time}} to {{end_time}}').
            replaceAll('{{day}}', displayDay).
            replaceAll('{{start_time}}', displayStartTime).
            replaceAll('{{end_time}}', displayEndTime);
          }
          else {
            return Localization().getStringEx('model.explore.date_time.at.format', '{{day}} at {{time}}').
            replaceAll('{{day}}', displayDay).
            replaceAll('{{time}}', displayStartTime);
          }
        }
        else {
          return displayDay;
        }
      }
      else {
        String displayDateTime = DateFormat(startDateFormat).format(startDateTimeUni);
        if (isAllDay != true) {
          displayDateTime += showStartYear ? ' ' : ', ';
          displayDateTime += DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
        }

        if ((endDateTimeUni != null) && (differentStartAndEndDays || (isAllDay != true))) {
          bool showEndYear = (nowUni.year != endDateTimeUni.year);
          String endDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showEndYear ? ', yyyy' : '');

          displayDateTime += ' - ';
          if (differentStartAndEndDays) {
            displayDateTime += DateFormat(endDateFormat).format(endDateTimeUni);
          }
          if (isAllDay != true) {
            displayDateTime += differentStartAndEndDays ? ', ' : '';
            displayDateTime += DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
          }
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? _buildDisplayDate({bool longFormat = false}) {
    if (startDateTimeUtcValue != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = startDateTimeUtcValue!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endDateTimeUtcValue?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowUni.year != startDateTimeUni.year);
      String startDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {

        String displayDay;
        switch(statDaysDiff) {
          case 0: displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today'); break;
          case 1: displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow'); break;
          default: displayDay = DateFormat(startDateFormat).format(startDateTimeUni);
        }

        return displayDay;
      }
      else {
        String displayDateTime = DateFormat(startDateFormat).format(startDateTimeUni);
        if ((endDateTimeUni != null) && differentStartAndEndDays) {
          bool showEndYear = (nowUni.year != endDateTimeUni.year);
          String endDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showEndYear ? ', yyyy' : '');

          displayDateTime += ' - ';
          if (differentStartAndEndDays) {
            displayDateTime += DateFormat(endDateFormat).format(endDateTimeUni);
          }
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? _buildDisplayTime({bool longFormat = false}) {
    if (startDateTimeUtcValue != null) {
      TZDateTime nowUni = DateTimeUni.nowUniOrLocal();
      TZDateTime nowMidnightUni = TZDateTimeUtils.dateOnly(nowUni);

      TZDateTime startDateTimeUni = startDateTimeUtcValue!.toUniOrLocal();
      TZDateTime startDateTimeMidnightUni = TZDateTimeUtils.dateOnly(startDateTimeUni);
      int statDaysDiff = startDateTimeMidnightUni.difference(nowMidnightUni).inDays;

      TZDateTime? endDateTimeUni = endDateTimeUtcValue?.toUniOrLocal();
      TZDateTime? endDateTimeMidnightUni = (endDateTimeUni != null) ? TZDateTimeUtils.dateOnly(endDateTimeUni) : null;
      int? endDaysDiff = (endDateTimeMidnightUni != null) ? endDateTimeMidnightUni.difference(nowMidnightUni).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {

        if (isAllDay != true) {
          String displayStartTime = DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
          if ((endDateTimeUni != null) && (TimeOfDay.fromDateTime(startDateTimeUni) != TimeOfDay.fromDateTime(endDateTimeUni))) {
            String displayEndTime = DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
            return Localization().getStringEx('model.explore.time.from_to.format', '{{start_time}} to {{end_time}}').
            replaceAll('{{start_time}}', displayStartTime).
            replaceAll('{{end_time}}', displayEndTime);
          }
          else {
            return Localization().getStringEx('model.explore.time.at.format', '{{time}}').
            replaceAll('{{time}}', displayStartTime);
          }
        }
        else {
          return null;
        }
      }
      else {
        String displayDateTime = DateFormat((startDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeUni).toLowerCase();
        if ((endDateTimeUni != null) && (differentStartAndEndDays || (isAllDay != true))) {
          displayDateTime += ' - ';
          displayDateTime += DateFormat((endDateTimeUni.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeUni).toLowerCase();
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

}