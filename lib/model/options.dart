class OptionData {
  final String title;
  final String? hint;
  final dynamic _value;
  final num? score;
  bool selected;

  dynamic get value { return _value ?? title; }

  OptionData({required this.title, this.hint, dynamic value, this.selected = false, this.score}) : _value = value;

  factory OptionData.fromJson(Map<String, dynamic> json) {
    return OptionData(
      title: json['title'],
      hint: json['hint'],
      value: json['value'],
      score: json['score'],
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
      'hint': hint,
      'value': _value,
      'score': score,
      'selected': selected,
    };
  }
}