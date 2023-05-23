import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum ActionType {
  none,
  launchUri,
  showSurvey,
  showPanel,
  dismiss,
}

class ActionData {
  ActionType type;
  String? label;
  dynamic data;
  Map<String, dynamic> params;

  ActionData({this.type = ActionType.none, this.label, this.data, this.params = const {}});

  factory ActionData.fromJson(dynamic json, {String? engineId}) {
    if (json is Map<String, dynamic>) {
      ActionType? type;
      try {
        type = ActionType.values.byName(json['type']);
      } catch(e) { debugPrint(e.toString()); }

      dynamic data = json['data'];
      if (type == ActionType.showSurvey && json['data'] == 'this') {
        data = engineId;
      }
      return ActionData(
        type: type ?? ActionType.none,
        label: JsonUtils.stringValue(json['label']),
        data: data,
        params: JsonUtils.mapValue(json['params']) ?? {},
      );
    } else if (json is String) {
      ActionType? type;
      try {
        type = ActionType.values.byName(json);
      } catch(e) { debugPrint(e.toString()); }

      return ActionData(type: type ?? ActionType.none);
    }
    return ActionData(type: ActionType.none);
  }

  factory ActionData.fromOther(ActionData other) {
    return ActionData(
      type: other.type,
      label: other.label,
      data: other.data is Map ? Map.from(other.data) : (other.data is Iterable ? List.from(other.data) : other.data),
      params: Map.from(other.params),
    );
  }

  static List<ActionData>? listFromJson(List<dynamic>? jsonList, {String? engineId}) {
    if (jsonList != null) {
      List<ActionData> list = [];
      for (dynamic json in jsonList) {
        list.add(ActionData.fromJson(json, engineId: engineId));
      }
      return list;
    }
    return null;
  }

  static List<Map<String, dynamic>>? listToJson(List<ActionData>? actions) {
    if (actions != null) {
      List<Map<String, dynamic>> actionsJson = [];
      for (ActionData action in actions) {
        actionsJson.add(action.toJson());
      }
      return actionsJson;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      'data': data,
      'params': params
    };
  }

  static Map<String, String> get supportedTypes => const {
    // "none": "None",
    "launchUri": "Open Application",
    "showSurvey": "Show Survey",
    // "showPanel": "Show Panel",
    // "dismiss": "Dismiss",
  };

  bool? get isInternalUri => params["internal"] is bool ? params["internal"] : null;
  set isInternalUri(bool? value) {
    params["internal"] = value;
  }

  bool? get isPrimaryForNotification => params["primary"] is bool ? params["primary"] : null;
  set isPrimaryForNotification(bool? value) {
    params["primary"] = value;
  }

  Map<String, dynamic>? get defaultResponsesForNotification => params['default_responses'] is Map<String, dynamic> ? params['default_responses'] : null;
  set defaultResponsesForNotification(Map<String, dynamic>? responses) {
    params["default_responses"] = responses;
  }
}

class ButtonAction {
  String title;
  void Function()? action;

  ButtonAction(this.title, this.action);
}