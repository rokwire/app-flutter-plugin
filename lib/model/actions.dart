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

  static List<ActionData> listFromJson(List<dynamic>? jsonList, {String? engineId}) {
    List<ActionData> list = [];
    for (dynamic json in jsonList ?? []) {
      list.add(ActionData.fromJson(json, engineId: engineId));
    }
    return list;
  }

  static List<Map<String, dynamic>> listToJson(List<ActionData>? actions) {
    List<Map<String, dynamic>> actionsJson = [];
    for (ActionData action in actions ?? []) {
      actionsJson.add(action.toJson());
    }
    return actionsJson;
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
    "launchUri": "Launch URI",
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
}

class ButtonAction {
  String title;
  void Function()? action;

  ButtonAction(this.title, this.action);
}