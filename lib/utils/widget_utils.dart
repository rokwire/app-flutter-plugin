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

import 'package:rokwire_plugin/utils/utils.dart';

enum ActionType {
  contact,
  showQuiz,
  dismiss,
  none
}

class ActionData {
  ActionType type;
  String? label;
  dynamic data;

  ActionData({this.type = ActionType.none, this.label, this.data});

  factory ActionData.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      dynamic data = json['data'];
      if (data is String) {
        dynamic decoded = JsonUtils.decode(data);
        if (decoded != null) {
          data = decoded;
        }
      }
      return ActionData(
        type: EnumUtils.enumFromString<ActionType>(ActionType.values, json['type']) ?? ActionType.none,
        label: JsonUtils.stringValue(json['label']),
        data: data,
      );
    } else if (json is String) {
      return ActionData(type: EnumUtils.enumFromString<ActionType>(ActionType.values, json) ?? ActionType.none);
    }
    return ActionData(type: ActionType.none);
  }

  static List<ActionData> listFromJson(List<dynamic>? jsonList) {
    List<ActionData> list = [];
    for (dynamic json in jsonList ?? []) {
      list.add(ActionData.fromJson(json));
    }
    return list;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': EnumUtils.enumToString(type),
      'label': label,
      'data': JsonUtils.encode(data),
    };
  }
}

class ButtonAction {
  String title;
  Function? action;

  ButtonAction(this.title, this.action);
}

class OptionData {
  final String title;
  final dynamic _value;
  bool selected;

  dynamic get value { return _value ?? title; }

  OptionData({required this.title, dynamic value, this.selected = false}) : _value = value;

  factory OptionData.fromJson(Map<String, dynamic> json) {
    return OptionData(
      title: json['title'],
      value: json['value'],
      selected: json['selected'] ?? false,
    );
  }

  static List<OptionData> listFromJson(List<dynamic> jsonList) {
    List<OptionData> list = [];
    for (dynamic json in jsonList) {
      if (json is Map<String, dynamic>) {
        list.add(OptionData.fromJson(json));
      }
    }
    return list;
  }

  @override
  String toString() {
    return title;
  }

  static List<String> getTitles(List<OptionData> options, {bool selectedOnly = false}) {
    List<String> titles = [];
    for (OptionData option in options) {
      if (!selectedOnly || option.selected) {
        titles.add(option.title);
      }
    }
    return titles;
  }

  static List<T> getValues<T>(List<OptionData> options, {bool selectedOnly = false}) {
    List<T> values = [];
    for (OptionData option in options) {
      if (!selectedOnly || option.selected) {
        dynamic value = option.value;
        if (value is T) {
          values.add(value);
        }
      }
    }
    return values;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': _value,
      'selected': selected,
    };
  }
}