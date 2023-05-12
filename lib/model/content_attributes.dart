
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////////////
// ContentAttributes

class ContentAttributes {
  final List<ContentAttribute>? attributes;
  final ContentAttributeRequirements? requirements;

  ContentAttributes({this.attributes, this.requirements});

  // JSON serialization

  static ContentAttributes? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributes(
      attributes: ContentAttribute.listFromJson(JsonUtils.listValue(json['attributes'])) ,
      requirements: ContentAttributeRequirements.fromJson(JsonUtils.mapValue(json['requirements'])),
    ) : null;
  }

  toJson() => {
    'attributes': attributes,
    'requirements': requirements,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributes) &&
    (requirements == other.requirements) &&
    const DeepCollectionEquality().equals(attributes, other.attributes);

  @override
  int get hashCode =>
    (requirements?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(attributes));

  // Copy

  static ContentAttributes? fromOther(ContentAttributes? other, { String? scope }) {
    return (other != null) ? ContentAttributes(
      attributes: ContentAttribute.listFromOther(other.attributes, scope: scope),
      requirements: other.requirements,
    ) : null;
  }

  // Accessories

  bool get isEmpty => attributes?.isEmpty ?? true;
  bool get isNotEmpty => !isEmpty;

  ContentAttribute? findAttribute({String? id, String? title}) {
    if ((attributes != null) && ((id != null) || (title != null))) {
      for (ContentAttribute attribute in attributes!) {
        if (((id == null) || (attribute.id == id)) &&
            ((title == null) || (attribute.title == title))) {
          return attribute;
        }
      }
    }
    return null;
  }

  static Map<String, LinkedHashSet<String>>? selectionFromAttributesSelection(Map<String, dynamic>? attributesSelection) {
    Map<String, LinkedHashSet<String>>? selection;
    attributesSelection?.forEach((String attributeId, dynamic value) {
      if (value is String) {
        selection ??= <String, LinkedHashSet<String>>{};
        // ignore: prefer_collection_literals
        selection![attributeId] = LinkedHashSet<String>.from(<String>[value]);
      }
      else if (value is List) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![attributeId] = LinkedHashSet<String>.from(JsonUtils.listStringsValue(value)?.reversed ?? <String>[]);
      }
    });
    return selection;
  }

  static Map<String, dynamic>? selectionToAttributesSelection(Map<String, LinkedHashSet<String>>? selection) {
    Map<String, dynamic>? attributesSelection;
    selection?.forEach((String attributeId, LinkedHashSet<String> values) {
      if (values.length == 1) {
        attributesSelection ??= <String, dynamic>{};
        attributesSelection![attributeId] = values.first;
      }
      else if (values.length > 1) {
        attributesSelection ??= <String, dynamic>{};
        attributesSelection![attributeId] = List.from(List.from(values).reversed);
      }
    });
    return attributesSelection;
  }

  void validateSelection(Map<String, LinkedHashSet<String>> selection) {
    bool modified;
    do {
      modified = false;
      for (String attributeId in selection.keys) {
        ContentAttribute? attribute = findAttribute(id: attributeId);
        if (attribute == null) {
          selection.remove(attributeId);
          modified = true;
          break;
        }
        else if (!attribute.validateSelection(selection)) {
          modified = true;
          break;
        }
      }
    }
    while (modified);
  }

  void extendSelection(Map<String, LinkedHashSet<String>> selection, String? attributeId ) {
    Queue<String> attributeIds = (attributeId != null) ? Queue<String>.from([attributeId]) : Queue<String>();
    while (attributeIds.isNotEmpty) {
      ContentAttribute? attribute = findAttribute(id: attributeIds.removeFirst());
      if (attribute?.requirements?.mode == ContentAttributeRequirementsMode.inclusive) {
        LinkedHashSet<String>? attributeLabels = selection[attribute?.id];
        if ((attributeLabels != null) && attributeLabels.isNotEmpty) {
          for (String attributeLabel in attributeLabels) {
            ContentAttributeValue? attributeValue = attribute?.findValue(label: attributeLabel);
            attributeValue?.requirements?.forEach((String requirementAttributeId, dynamic requirementValue) {
              if (requirementValue is String) {
                LinkedHashSet<String>? selectedRequiremntAttributeLabels = selection[requirementAttributeId];
                if (selectedRequiremntAttributeLabels == null) {
                  // ignore: prefer_collection_literals
                  selection[requirementAttributeId] = selectedRequiremntAttributeLabels = LinkedHashSet<String>();
                }
                if (selectedRequiremntAttributeLabels.isEmpty) {
                  selectedRequiremntAttributeLabels.add(requirementValue);
                  if (!attributeIds.contains(requirementValue)) {
                    attributeIds.addLast(requirementValue);
                  }
                }
              }
            });
          }
        }
      }
    }
  }

  bool isAttributesSelectionValid(Map<String, dynamic>? selection) {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        dynamic attributeSelection = (selection != null) ? selection[attribute.id] : null;
        if (!attribute.isSatisfiedFromSelection(attributeSelection)) {
          return false;
        }
      }
    }
    return true;
  }

  bool isSelectionValid(Map<String, LinkedHashSet<String>>? selection) =>
    isAttributesSelectionValid(selection) && (requirements?.isAttributesSelectionValid(selection) ?? true);

  bool get hasRequiredAttributes {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (attribute.isRequired) {
          return true;
        }
      }
    }
    return false;
  }

  bool get hasRequired => hasRequiredAttributes || (requirements?.hasRequired ?? false);

  List<String> displayAttributeValuesListFromSelection(Map<String, dynamic>? selection, { ContentAttributeUsage? usage, bool complete = false }) {
    List<String> displayList = <String>[];
    if ((attributes != null) && (selection != null)) {
      for (ContentAttribute attribute in attributes!) {
        if ((usage == null) || (attribute.usage == usage)) {
          displayList.addAll(attribute.displayAttributeValuesListFromSelection(selection, complete: complete) ?? <String>[]);
        }
      }
    }
    return displayList;
  }
}

/////////////////////////////////////
// ContentAttribute

class ContentAttribute {
  final String? id;
  final String? title;
  final String? longTitle;
  final String? description;
  final String? text;
  final String? emptyHint;
  final String? emptyFilterHint;
  final String? semanticsHint;
  final String? semanticsFilterHint;
  final dynamic nullValue;
  final ContentAttributeWidget? widget;
  final ContentAttributeUsage? usage;
  final ContentAttributeRequirements? requirements;
  final Set<String>? scope;
  final List<ContentAttributeValue>? values;
  final Map<String, dynamic>? translations;

  ContentAttribute({this.id, this.title, this.longTitle, this.description, this.text,
    this.emptyHint, this.emptyFilterHint, this.semanticsHint, this.semanticsFilterHint,
    this.nullValue, this.widget, this.usage, this.requirements,
    this.scope, this.values, this.translations});

  // JSON serialization

  static ContentAttribute? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttribute(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      longTitle: JsonUtils.stringValue(json['long-title']),
      description: JsonUtils.stringValue(json['description']),
      text: JsonUtils.stringValue(json['text']),
      emptyHint: JsonUtils.stringValue(json['empty-hint']),
      emptyFilterHint: JsonUtils.stringValue(json['empty-filter-hint']),
      semanticsHint: JsonUtils.stringValue(json['semantics-hint']),
      semanticsFilterHint: JsonUtils.stringValue(json['semantics-filter-hint']),
      nullValue: json['null-value'],
      widget: contentAttributeWidgetFromString(JsonUtils.stringValue(json['widget'])),
      usage: contentAttributeUsageFromString(JsonUtils.stringValue(json['usage'])),
      requirements: ContentAttributeRequirements.fromJson(JsonUtils.mapValue(json['requirements'])),
      scope: JsonUtils.setStringsValue(json['scope']),
      values: ContentAttributeValue.listFromJson(JsonUtils.listValue(json['values'])),
      translations: JsonUtils.mapValue(json['translations'])
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'long-title' : longTitle,
    'description': description,
    'text': text,
    'empty-hint': emptyHint,
    'empty-filter-hint': emptyFilterHint,
    'semantics-hint': semanticsHint,
    'semantics-filter-hint': semanticsFilterHint,
    'null-value': nullValue,
    'widget': contentAttributeWidgetToString(widget),
    'usage': contentAttributeUsageToString(usage),
    'requirements': requirements,
    'scope': JsonUtils.listStringsValue(scope),
    'values': values,
    'translations': translations,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttribute) &&
    (id == other.id) &&
    (title == other.title) &&
    (longTitle == other.longTitle) &&
    (description == other.description) &&
    (text == other.text) &&
    (emptyHint == other.emptyHint) &&
    (emptyFilterHint == other.emptyFilterHint) &&
    (semanticsHint == other.semanticsHint) &&
    (semanticsFilterHint == other.semanticsFilterHint) &&
    (nullValue == other.nullValue) &&
    (widget == other.widget) &&
    (usage == other.usage) &&
    (requirements == other.requirements) &&
    const DeepCollectionEquality().equals(scope, other.scope) &&
    const DeepCollectionEquality().equals(values, other.values) &&
    const DeepCollectionEquality().equals(translations, other.translations);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (longTitle?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (text?.hashCode ?? 0) ^
    (emptyHint?.hashCode ?? 0) ^
    (emptyFilterHint?.hashCode ?? 0) ^
    (semanticsHint?.hashCode ?? 0) ^
    (semanticsFilterHint?.hashCode ?? 0) ^
    (nullValue?.hashCode ?? 0) ^
    (widget?.hashCode ?? 0) ^
    (usage?.hashCode ?? 0) ^
    (requirements?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(scope)) ^
    (const DeepCollectionEquality().hash(values)) ^
    (const DeepCollectionEquality().hash(translations));

  // Accessories

  String? get displayTitle => displayString(title);
  String? get displayLongTitle => displayString(longTitle);
  String? get displayDescription => displayString(description);
  String? get displayText => displayString(text);
  String? get displayEmptyHint => displayString(emptyHint);
  String? get displayEmptyFilterHint => displayString(emptyFilterHint);
  String? get displaySemanticsHint => displayString(semanticsHint);
  String? get displaySemanticsFilterHint => displayString(semanticsFilterHint);

  bool get isRequired => requirements?.hasRequired ?? false;
  bool get isMultipleSelection => (requirements?.maxSelectedCount != 1);
  bool get isSingleSelection => (requirements?.maxSelectedCount == 1);

  bool get isDropdownWidget => (widget == ContentAttributeWidget.dropdown);
  bool get isCheckboxWidget => (widget == ContentAttributeWidget.checkbox);

  bool get isTagUsage => (usage == ContentAttributeUsage.tag);
  bool get isLabelUsage => (usage == ContentAttributeUsage.label);
  bool get isCategoryUsage => (usage == ContentAttributeUsage.category);
  bool get isPropertyUsage => (usage == ContentAttributeUsage.property);

  bool inScope(String scopeItem) => scope?.contains(scopeItem) ?? true; // apply to all scopes if no particular scope defined

  ContentAttributeValue? findValue({String? label, dynamic value}) =>
    ContentAttributeValue.findInList(values, label: label, value: value);

  bool validateSelection(Map<String, LinkedHashSet<String>> selection) {
    LinkedHashSet<String>? attributeLabels = selection[id];
    if (attributeLabels != null) {
      for (String attributeLabel in attributeLabels) {
        ContentAttributeValue? attributeValue = findValue(label: attributeLabel);
        if ((attributeValue == null) || !attributeValue.fulfillsSelection(selection, requirementsMode: requirements?.mode)) {
          attributeLabels.remove(attributeLabel);
          return false;
        }
      }
    }
    return true;
  }

  bool isSatisfiedFromSelection(dynamic selection) =>
    requirements?.isAttributeValuesSelectionValid(selection) ?? true;

  List<ContentAttributeValue>? attributeValuesFromSelection(Map<String, LinkedHashSet<String>> selection) {
    List<ContentAttributeValue>? filteredAttributeValues;
    if (values != null) {
      for (ContentAttributeValue attributeValue in values!) {
        if (attributeValue.fulfillsSelection(selection, requirementsMode: requirements?.mode)) {
          filteredAttributeValues ??= <ContentAttributeValue>[];
          filteredAttributeValues.add(attributeValue);
        }
      }
    }
    return filteredAttributeValues;
  }

  List<String>? displayAttributeValuesListFromSelection(Map<String, dynamic>? selection, { bool complete = false } ) {
    dynamic value = (selection != null) ? selection[id] : null;
    if (value is String) {
      String? displayValue = displayAttributeValue(value, complete: complete);
      if (displayValue != null) {
        return <String>[displayValue];
      }
    }
    else if (value is List) {
      List<String> displayList = <String>[];
      for (dynamic entry in value) {
        if (entry is String) {
          String? displayValue = displayAttributeValue(entry, complete: complete);
          if (displayValue != null) {
            displayList.add(displayValue);
          }
        }
      }
      return displayList.isNotEmpty ? displayList : null;
    }
    return null;
  }

  String? displayAttributeValue(String attributeLabel, { bool complete = false }) {
    String? displayValue = attributeLabel;
    if ((complete != true) && (widget == ContentAttributeWidget.checkbox) && (usage == ContentAttributeUsage.label)) {
      ContentAttributeValue? attributeValue = findValue(label: attributeLabel);
      displayValue = (attributeValue?.value == true) ? title : null;
    }
    return (displayValue != null) ? (displayString(displayValue) ?? displayValue) : null;
  }

  String? displayString(String? key, { String? languageCode }) {
    if ((translations != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(translations![languageCode]) ??
        JsonUtils.mapValue(translations![Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(translations![Localization().defaultLocale?.languageCode]);
      String? value = (mapping != null) ? JsonUtils.stringValue(mapping[key]) : null;
      if (value != null) {
        return value;
      }
    }
    return key;
  }

  // List<ContentAttribute> JSON Serialization

  static List<ContentAttribute>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttribute>? values;
    if (jsonList != null) {
      values = <ContentAttribute>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttribute.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentAttribute>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentAttribute value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  static List<ContentAttribute>? listFromOther(List<ContentAttribute>? otherList, { String? scope }) =>
    (otherList != null) ? List<ContentAttribute>.from((scope != null) ? otherList.where((ContentAttribute attribute) => attribute.inScope(scope)) : otherList) : null;
}

/////////////////////////////////////
// ContentAttributeWidget

enum ContentAttributeWidget { dropdown, checkbox }

ContentAttributeWidget? contentAttributeWidgetFromString(String? value) {
  switch(value) {
    case 'dropdown': return ContentAttributeWidget.dropdown;
    case 'checkbox': return ContentAttributeWidget.checkbox;
    default: return null;
  }
}

String? contentAttributeWidgetToString(ContentAttributeWidget? value) {
  switch(value) {
    case ContentAttributeWidget.dropdown: return 'dropdown';
    case ContentAttributeWidget.checkbox: return 'checkbox';
    default: return null;
  }
}

/////////////////////////////////////
// ContentAttributeUsage

enum ContentAttributeUsage { tag, label, category, property }

ContentAttributeUsage? contentAttributeUsageFromString(String? value) {
  switch(value) {
    case 'tag': return ContentAttributeUsage.tag;
    case 'label': return ContentAttributeUsage.label;
    case 'category': return ContentAttributeUsage.category;
    case 'property': return ContentAttributeUsage.property;
    default: return null;
  }
}

String? contentAttributeUsageToString(ContentAttributeUsage? value) {
  switch(value) {
    case ContentAttributeUsage.tag: return 'tag';
    case ContentAttributeUsage.label: return 'label';
    case ContentAttributeUsage.category: return 'category';
    case ContentAttributeUsage.property: return 'property';
    default: return null;
  }
}

/////////////////////////////////////
// ContentAttributeValue

class ContentAttributeValue {
  final String? label;
  final dynamic value;
  final Map<String, dynamic>? requirements;

  ContentAttributeValue({this.label, this.value, this.requirements});

  // JSON serialization

  static ContentAttributeValue? fromJson(dynamic json) {
    if (json is String) {
      return ContentAttributeValue(
        label: json,
      );
    }
    else if (json is Map) {
      return ContentAttributeValue(
        label: JsonUtils.stringValue(json['label']),
        value: json['value'],
        requirements: JsonUtils.mapValue(json['requirements']),
      );
    }
    else {
      return null;
    }
  }

  toJson() => {
    'label': label,
    'value': value,
    'requirements': requirements,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributeValue) &&
    (label == other.label) &&
    (value == other.value) &&
    const DeepCollectionEquality().equals(requirements, other.requirements);

  @override
  int get hashCode =>
    (label?.hashCode ?? 0) ^
    (value?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(requirements));

  // Accessories

  static ContentAttributeValue? findInList(List<ContentAttributeValue>? attributeValues, {String? label, dynamic value}) {
    if (attributeValues != null) {
      for (ContentAttributeValue attributeValue in attributeValues) {
        if (((label == null) || (attributeValue.label == label)) &&
            ((value == null) || (attributeValue.value == value)))
        {
          return attributeValue;
        }
      }
    }
    return null;
  }

  bool fulfillsSelection(Map<String, LinkedHashSet<String>>? selection, { ContentAttributeRequirementsMode? requirementsMode }) {
    if ((requirements == null) || requirements!.isEmpty) {
      return true;
    }
    else {
      for (String key in requirements!.keys) {
        if (!_matchRequirement(requirement: requirements![key], selection: selection?[key], requirementsMode: requirementsMode)) {
          return false;
        }
      }
      return true;
    }
  }

  bool _matchRequirement({ dynamic requirement, LinkedHashSet<String>? selection, ContentAttributeRequirementsMode? requirementsMode }) {
    if (requirement == null) {
      return true;
    }
    else if ((selection == null) || selection.isEmpty) {
      return (requirementsMode == ContentAttributeRequirementsMode.inclusive);
    }
    else if (requirement is String) {
      return selection.contains(requirement);
    }
    else if (requirement is List) {
      for (dynamic requirementEntry in requirement) {
        if (!_matchRequirement(requirement: requirementEntry, selection: selection)) {
          return false;
        }
      }
      return true;
    }
    else {
      return false;
    }
  }

  // List<ContentAttributeValue> JSON Serialization

  static List<ContentAttributeValue>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttributeValue>? values;
    if (jsonList != null) {
      values = <ContentAttributeValue>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttributeValue.fromJson(jsonEntry));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentAttributeValue>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentAttributeValue value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

/////////////////////////////////////
// ContentAttributeRequirements

class ContentAttributeRequirements {
  final int? minSelectedCount;
  final int? maxSelectedCount;
  final ContentAttributeRequirementsMode? mode;

  ContentAttributeRequirements({this.minSelectedCount, this.maxSelectedCount, this.mode});

  // JSON serialization

  static ContentAttributeRequirements? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributeRequirements(
      minSelectedCount: JsonUtils.intValue(json['min-selected-count']),
      maxSelectedCount: JsonUtils.intValue(json['max-selected-count']),
      mode: contentAttributeRequirementsModeFromString(JsonUtils.stringValue(json['mode'])),
    ) : null;
  }

  toJson() => {
    'min-selected-count' : minSelectedCount,
    'max-selected-count' : maxSelectedCount,
    'mode': contentAttributeRequirementsModeToString(mode),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributeRequirements) &&
    (minSelectedCount == other.minSelectedCount) &&
    (maxSelectedCount == other.maxSelectedCount) &&
    (mode == other.mode);

  @override
  int get hashCode =>
    (minSelectedCount?.hashCode ?? 0) ^
    (maxSelectedCount?.hashCode ?? 0) ^
    (mode?.hashCode ?? 0);


  // Accessories

  bool get hasRequired =>
    (0 < (minSelectedCount ?? 0));

  bool isAttributesSelectionValid(Map<String, dynamic>? selection) {
    if ((minSelectedCount != null) || (maxSelectedCount != null)) {
      int selectedCount = _selectedCategoriesCount(selection);
      return ((minSelectedCount == null) || (minSelectedCount! <= selectedCount)) &&
             ((maxSelectedCount == null) || (maxSelectedCount! >= selectedCount));
    }
    else {
      return true;
    }
  }

  bool canSelectMoreCategories(Map<String, dynamic>? selection) {
    return (maxSelectedCount == null) || (maxSelectedCount! > _selectedCategoriesCount(selection));
  }

  static int _selectedCategoriesCount(Map<String, dynamic>? selection) {
    int selectedCount = 0;
    if (selection != null) {
      for (dynamic entry in selection.values) {
        if (0 < _selectedAttributesCount(entry)) {
          selectedCount++;
        }
      }
    }
    return selectedCount;
  }

  bool isAttributeValuesSelectionValid(dynamic selection) {
    int selectedCount = _selectedAttributesCount(selection); 
    return ((minSelectedCount == null) || (minSelectedCount! <= selectedCount)) &&
           ((maxSelectedCount == null) || (maxSelectedCount! >= selectedCount));
  }

  void validateAttributeValuesSelection(LinkedHashSet<String>? selection) {
    if ((maxSelectedCount != null) && (0 <= maxSelectedCount!) && (selection != null)) {
      while (maxSelectedCount! < selection.length) {
        selection.remove(selection.first);
      }
    }
  }

  static int _selectedAttributesCount(dynamic selection) {
    if (selection is String) {
      return 1;
    }
    else if (selection is Iterable) {
      return selection.length;
    }
    else {
      return 0;
    }
  }

}

/////////////////////////////////////
// ContentAttributeRequirementsMode

enum ContentAttributeRequirementsMode { exclusive, inclusive }

ContentAttributeRequirementsMode? contentAttributeRequirementsModeFromString(String? value) {
  switch(value) {
    case 'exclusive': return ContentAttributeRequirementsMode.exclusive;
    case 'inclusive': return ContentAttributeRequirementsMode.inclusive;
    default: return null;
  }
}

String? contentAttributeRequirementsModeToString(ContentAttributeRequirementsMode? value) {
  switch(value) {
    case ContentAttributeRequirementsMode.exclusive: return 'exclusive';
    case ContentAttributeRequirementsMode.inclusive: return 'inclusive';
    default: return null;
  }
}
