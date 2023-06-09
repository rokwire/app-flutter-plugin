import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Alert {
  String? id;
  String? title;
  String? text;
  List<ActionData>? actions;
  Map<String, dynamic>? params;

  Alert({this.id, this.title, this.text, this.actions, this.params});

  factory Alert.fromJson(Map<String, dynamic> json, {String? engineId}) {
    return Alert(
      id: JsonUtils.stringValue(json["id"]),
      title: JsonUtils.stringValue(json["title"]),
      text: JsonUtils.stringValue(json["text"]),
      actions: ActionData.listFromJson(JsonUtils.listValue(json["actions"]), engineId: engineId),
      params: JsonUtils.mapValue(json["params"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'actions': actions?.map((e) => e.toJson()).toList(),
      'params': params
    };
  }

  Duration? get timeToAlert {
    switch (JsonUtils.stringValue(params?["type"])) {
      case "relative":
        return JsonUtils.durationValue(params?["schedule"]);
      case "absolute":
        //TODO: implement
      case "cron":
        //TODO: implement
    }
    return null;
  }
}