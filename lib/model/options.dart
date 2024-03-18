class OptionData {
  String title;
  String? hint;
  dynamic value;
  num? score;
  bool selected;

  bool isCorrect;

  dynamic get responseValue { return value ?? title; }

  OptionData({required this.title, this.hint, this.value, this.selected = false, this.score, this.isCorrect = false});

  factory OptionData.fromJson(Map<String, dynamic> json) {
    return OptionData(
      title: json['title'],
      hint: json['hint'],
      value: json['value'],
      score: json['score'],
      selected: json['selected'] ?? false,
    );
  }

  factory OptionData.fromOther(OptionData other) {
    return OptionData(
      title: other.title,
      hint: other.hint,
      value: other.value is Map ? Map.from(other.value) : (other.value is Iterable ? List.from(other.value) : other.value),
      score: other.score,
      isCorrect: other.isCorrect
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

  static List<dynamic>? listToJson(List<OptionData>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (OptionData? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
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
      'value': value,
      'score': score,
      'selected': selected,
    };
  }
}