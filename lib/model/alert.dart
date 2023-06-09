import 'package:rokwire_plugin/model/actions.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Alert {
  String? id;
  String? title;
  String? text;
  List<ActionData>? actions;
  Map<String, dynamic>? params;

  Alert({this.id, this.title, this.text, this.actions, this.params});

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: JsonUtils.stringValue(json["id"]),
      title: JsonUtils.stringValue(json["title"]),
      text: JsonUtils.stringValue(json["text"]),
      actions: ActionData.listFromJson(JsonUtils.listValue(json["actions"])),
      params: JsonUtils.mapValue(json["params"]),
    );
  }
}