import 'package:rokwire_plugin/model/actions.dart';

class Alert {
  String? id;
  String? title;
  String? text;
  List<ActionData>? actions;
  Map<String, dynamic> params;

  Alert({this.id, this.title, this.text, this.actions, this.params = const {}});
}