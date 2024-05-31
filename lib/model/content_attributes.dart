
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////////////
// ContentAttributes

class ContentAttributes {
  final List<ContentAttribute>? attributes;
  final List<ContentAttributeRequirements>? _requirements;

  ContentAttributes({this.attributes, List<ContentAttributeRequirements>? requirements}) :
    _requirements = requirements;

  // JSON serialization

  static ContentAttributes? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributes(
      attributes: ContentAttribute.listFromJson(JsonUtils.listValue(json['attributes'])) ,
      requirements: ContentAttributeRequirements.listFromJson(JsonUtils.listValue(json['requirements'])),
    ) : null;
  }

  toJson() => {
    'attributes': ContentAttribute.listToJson(attributes),
    'requirements': ContentAttributeRequirements.listToJson(_requirements),
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is ContentAttributes) &&
    (const DeepCollectionEquality().equals(attributes, other.attributes)) &&
    (const DeepCollectionEquality().equals(_requirements, other._requirements));

  @override
  int get hashCode =>
    (const DeepCollectionEquality().hash(attributes)) ^
    (const DeepCollectionEquality().hash(_requirements));

  // Clone

  ContentAttributes clone() => ContentAttributes(
    attributes: ContentAttribute.listFromOther(attributes, clone: true),
    requirements: ContentAttributeRequirements.listFromOther(_requirements, clone: true),
  );

  static ContentAttributes? fromOther(ContentAttributes? other, { String? scope, bool clone = false }) {
    return (other != null) ? ContentAttributes(
      attributes: ContentAttribute.listFromOther(other.attributes, scope: scope, clone: clone),
      requirements: ContentAttributeRequirements.listFromOther(other._requirements, scope: scope, clone: clone) ,
    ) : null;
  }

  // Accessories

  ContentAttributeRequirements? get requirements => ListUtils.first(_requirements);

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

  static Map<String, LinkedHashSet<dynamic>>? selectionFromAttributesSelection(Map<String, dynamic>? attributesSelection) {
    Map<String, LinkedHashSet<dynamic>>? selection;
    attributesSelection?.forEach((String attributeId, dynamic attributeRawValue) {
      if (attributeRawValue is List) {
        selection ??= <String, LinkedHashSet<dynamic>>{};
        selection![attributeId] = LinkedHashSet<dynamic>.from(attributeRawValue);
      }
      else if (attributeRawValue != null) {
        selection ??= <String, LinkedHashSet<dynamic>>{};
        // ignore: prefer_collection_literals
        selection![attributeId] = LinkedHashSet<dynamic>.from(<dynamic>[attributeRawValue]);
      }
    });
    return selection;
  }

  static Map<String, dynamic>? selectionToAttributesSelection(Map<String, LinkedHashSet<dynamic>>? selection) {
    Map<String, dynamic>? attributesSelection;
    selection?.forEach((String attributeId, LinkedHashSet<dynamic> attributeRawValue) {
      if (attributeRawValue.length == 1) {
        attributesSelection ??= <String, dynamic>{};
        attributesSelection![attributeId] = attributeRawValue.first;
      }
      else if (attributeRawValue.length > 1) {
        attributesSelection ??= <String, dynamic>{};
        attributesSelection![attributeId] = List<dynamic>.from(attributeRawValue);
      }
    });
    return attributesSelection;
  }

  void validateSelection(Map<String, LinkedHashSet<dynamic>> selection) {
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

  void extendSelection(Map<String, LinkedHashSet<dynamic>> selection, String? attributeId ) {
    Queue<String> attributeIds = (attributeId != null) ? Queue<String>.from([attributeId]) : Queue<String>();
    while (attributeIds.isNotEmpty) {
      ContentAttribute? attribute = findAttribute(id: attributeIds.removeFirst());
      if (attribute?.requirements?.mode == ContentAttributeRequirementsMode.inclusive) {
        LinkedHashSet<dynamic>? attributeRawValues = selection[attribute?.id];
        if ((attributeRawValues != null) && attributeRawValues.isNotEmpty) {
          for (String attributeRawValue in attributeRawValues) {
            ContentAttributeValue? attributeValue = attribute?.findValue(value: attributeRawValue);
            attributeValue?.requirements?.forEach((String requirementAttributeId, dynamic requirementRawValue) {
              LinkedHashSet<dynamic>? selectedRequiremntAttributeRawValues = selection[requirementAttributeId];
              if (selectedRequiremntAttributeRawValues == null) {
                // ignore: prefer_collection_literals
                selection[requirementAttributeId] = selectedRequiremntAttributeRawValues = LinkedHashSet<dynamic>();
              }
              if (selectedRequiremntAttributeRawValues.isEmpty) {
                selectedRequiremntAttributeRawValues.add(requirementRawValue);
                if (!attributeIds.contains(requirementAttributeId)) { // ??? requirementRawValue
                  attributeIds.addLast(requirementAttributeId);       // ??? requirementRawValue
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

  bool isSelectionValid(Map<String, dynamic>? selection) =>
    isAttributesSelectionValid(selection) && (requirements?.isAttributesSelectionValid(selection) ?? true);

  bool hasRequiredAttributes(int functionalScope) {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (attribute.isRequired(functionalScope)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasRequired(int functionalScope) => hasRequiredAttributes(functionalScope) || (requirements?.hasRequired ?? false);

  List<String> displaySelectedLabelsFromSelection(Map<String, dynamic>? selection, { ContentAttributeUsage? usage, bool complete = false }) {
    List<String> displayList = <String>[];
    if ((attributes != null) && (selection != null)) {
      for (ContentAttribute attribute in attributes!) {
        if ((usage == null) || (attribute.usage == usage)) {
          displayList.addAll(attribute.displaySelectedLabelsFromSelection(selection, complete: complete) ?? <String>[]);
        }
      }
    }
    return displayList;
  }

  Set<String>? get scope {
    Set<String>? attributesScope;
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (attribute.scope?.isNotEmpty == true) {
          if (attributesScope == null) {
            attributesScope = attribute.scope;
            debugPrint("Start: ${attributesScope.toString()}");
          }
          else {
            attributesScope = attributesScope.intersection(attribute.scope!);
          }
        }
      }
    }
    return attributesScope;
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
  final int? sortOrder;
  final List<ContentAttributeValue>? values;
  final Map<String, dynamic>? translations;

  ContentAttribute({this.id, this.title, this.longTitle, this.description, this.text,
    this.emptyHint, this.emptyFilterHint, this.semanticsHint, this.semanticsFilterHint,
    this.nullValue, this.widget, this.usage, this.requirements,
    this.scope, this.sortOrder, this.values, this.translations});

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
      sortOrder: JsonUtils.intValue(json['sort-order']),
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
    'sort-order': sortOrder,
    'values': values,
    'translations': translations,
  };

  // Equality

  @override
  bool operator==(Object other) =>
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
    (sortOrder == other.sortOrder) &&
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
    (sortOrder?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(scope)) ^
    (const DeepCollectionEquality().hash(values)) ^
    (const DeepCollectionEquality().hash(translations));

  // Comparison

  int compareByTitle(ContentAttribute? other) =>
    (displayTitle ?? '').compareTo(other?.displayTitle ?? '');

  int compareBySortOrder(ContentAttribute? other) =>
    (sortOrder ?? 0).compareTo(other?.sortOrder ?? 0);

  // Clone

  ContentAttribute clone() => ContentAttribute(
    id: id,
    title: title,
    longTitle: longTitle,
    description: description,
    text: text,
    emptyHint: emptyHint,
    emptyFilterHint: emptyFilterHint,
    semanticsHint: semanticsHint,
    semanticsFilterHint: semanticsFilterHint,
    nullValue: nullValue,
    widget: widget,
    usage: usage,
    requirements: requirements?.clone(),
    scope: SetUtils.from(scope),
    sortOrder: sortOrder,
    values: ContentAttributeValue.listFromOther(values, clone: true),
    translations: MapUtils.from(translations),
  );

  static List<ContentAttribute>? listFromOther(List<ContentAttribute>? otherList, { String? scope, bool clone = false }) {
    if (otherList != null) {
      if (clone) {
        List<ContentAttribute> cloneList = <ContentAttribute>[];
        for (ContentAttribute attribute in otherList) {
          if ((scope == null) || attribute.inScope(scope)) {
            cloneList.add(attribute.clone());
          }
        }
        return cloneList;
      }
      else {
        return List<ContentAttribute>.from((scope != null) ? otherList.where((ContentAttribute attribute) => attribute.inScope(scope)) : otherList);
      }
    }
    else {
      return null;
    }
  }

  // Accessories

  String? get displayTitle => displayString(title);
  String? get displayLongTitle => displayString(longTitle);
  String? get displayDescription => displayString(description);
  String? get displayText => displayString(text);
  String? get displayEmptyHint => displayString(emptyHint);
  String? get displayEmptyFilterHint => displayString(emptyFilterHint);
  String? get displaySemanticsHint => displayString(semanticsHint);
  String? get displaySemanticsFilterHint => displayString(semanticsFilterHint);

  ContentAttributeRequirements? requirementsForFunctionalScope(int functionalScope) => (((requirements?.functionalScope ?? 0) & functionalScope) != 0) ? requirements : null;
  bool isRequired(int functionalScope) => requirementsForFunctionalScope(functionalScope)?.hasRequired ?? false;
  bool isMultipleSelection(int functionalScope) => (requirementsForFunctionalScope(functionalScope)?.maxSelectedCount != 1);
  bool isSingleSelection(int functionalScope) => (requirementsForFunctionalScope(functionalScope)?.maxSelectedCount == 1);
  bool get hasMultipleValueGroups => (_collectValueGroups().length > 1);

  bool get isDropdownWidget => (widget == ContentAttributeWidget.dropdown);
  bool get isCheckboxWidget => (widget == ContentAttributeWidget.checkbox);

  bool get isTagUsage => (usage == ContentAttributeUsage.tag);
  bool get isLabelUsage => (usage == ContentAttributeUsage.label);
  bool get isCategoryUsage => (usage == ContentAttributeUsage.category);
  bool get isPropertyUsage => (usage == ContentAttributeUsage.property);

  bool inScope(String scopeItem) => scope?.contains(scopeItem) ?? true; // apply to all scopes if no particular scope defined

  ContentAttributeValue? findValue({dynamic value}) =>
    ContentAttributeValue.findInList(values, value: value);

  bool validateSelection(Map<String, LinkedHashSet<dynamic>> selection) {
    LinkedHashSet<dynamic>? attributeRawValues = selection[id];
    if (attributeRawValues != null) {
      for (dynamic attributeRawValue in attributeRawValues) {
        ContentAttributeValue? attributeValue = findValue(value: attributeRawValue);
        if ((attributeValue == null) || !attributeValue.fulfillsSelection(selection, requirementsMode: requirements?.mode)) {
          attributeRawValues.remove(attributeRawValue);
          return false;
        }
      }
    }
    return true;
  }

  bool isSatisfiedFromSelection(dynamic selection) {
    if (requirements != null) {
      Map<String?, LinkedHashSet<dynamic>> groupsSelection = _splitSelectionByGroups(selection);
      if(groupsSelection.isNotEmpty) {
        for (LinkedHashSet<dynamic> groupSelection in groupsSelection.values) {
          if (!requirements!.isAttributeValuesSelectionValid(groupSelection)) {
            return false;
          }
        }
      } else { //Check does empty selection satisfies the requirements. Otherwise the min-selection requirement is not checked
        return requirements!.isAttributeValuesSelectionValid(null);
      }
    }
    return true;
  }

  void validateAttributeValuesSelection(LinkedHashSet<dynamic>? selection) {
    int? maxSelectedCount = requirements?.maxSelectedCount;
    if ((maxSelectedCount != null) && (0 <= maxSelectedCount) && (selection != null)) {
      Map<String?, LinkedHashSet<dynamic>> groupsSelection = _splitSelectionByGroups(selection);
      for (LinkedHashSet<dynamic> groupSelection in groupsSelection.values) {
        while (maxSelectedCount < groupSelection.length) {
          dynamic removeValue = groupSelection.first;
          selection.remove(removeValue);
          groupSelection.remove(removeValue);
        }
      }
    }
  }

  Map<String?, LinkedHashSet<dynamic>> _splitSelectionByGroups(dynamic selection) {
    Map<String?, LinkedHashSet<dynamic>> map = <String?, LinkedHashSet<dynamic>>{};
    if ((selection is List) || (selection is Set)) {
      for (dynamic entry in selection) {
        _extendSelectionByGroups(map, findValue(value: entry));
      }
    }
    else if (selection != null) {
      _extendSelectionByGroups(map, findValue(value: selection));
    }
    return map;
  }

  void _extendSelectionByGroups(Map<String?, LinkedHashSet<dynamic>> map, ContentAttributeValue? attributeValue) {
    if (attributeValue != null) {
      // ignore: prefer_collection_literals
      (map[attributeValue.group] ??= LinkedHashSet<dynamic>()).add(attributeValue.value);
    }
  }

  LinkedHashSet<String?> _collectValueGroups() {
    LinkedHashSet<String?> groups = LinkedHashSet<String?>();
    if (values != null) {
      for (ContentAttributeValue value in values!) {
        groups.add(value.group);
      }
    }
    return groups;
  }


  List<ContentAttributeValue>? attributeValuesFromSelection(Map<String, LinkedHashSet<dynamic>> selection) {
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

  List<String>? displaySelectedLabelsFromSelection(Map<String, dynamic>? selection, { bool complete = false } ) {
    dynamic rawValue = (selection != null) ? selection[id] : null;
    return displaySelectedLabelsFromRawValue(rawValue, complete: complete);
  }

  List<String>? displaySelectedLabelsFromRawValue(dynamic rawValue, { bool complete = false } ) {
    if ((rawValue is List) || (rawValue is Set)) {
      List<String> displayList = <String>[];
      for (dynamic rawEntry in rawValue) {
        String? displayValue = displaySelectedLabel(rawEntry, complete: complete);
        if (displayValue != null) {
          displayList.add(displayValue);
        }
      }
      return displayList.isNotEmpty ? displayList : null;
    }
    else if (rawValue != null) {
      String? displayValue = displaySelectedLabel(rawValue, complete: complete);
      if (displayValue != null) {
        return <String>[displayValue];
      }
    }
    return null;
  }

  String? displaySelectedLabel(dynamic attributeRawValue, { bool complete = false }) {
    ContentAttributeValue? attributeValue = findValue(value: attributeRawValue);
    String? displayValue = attributeValue?.selectedLabel;
    if ((complete != true) && (widget == ContentAttributeWidget.checkbox) && (usage == ContentAttributeUsage.label)) {
      displayValue = (attributeValue?.value == true) ? title : null;
    }
    return (displayValue != null) ? (displayString(displayValue) ?? displayValue) : attributeRawValue?.toString();
  }

  String? displaySelectLabel(dynamic attributeRawValue, { bool complete = false }) {
    ContentAttributeValue? attributeValue = findValue(value: attributeRawValue);
    String? displayValue = attributeValue?.selectLabel;
    if ((complete != true) && (widget == ContentAttributeWidget.checkbox) && (usage == ContentAttributeUsage.label)) {
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
  final String? _label;
  final dynamic _value;
  final String? group;
  final Map<String, dynamic>? requirements;
  
  // Mutable properties
  String? info;
  Map<String, dynamic>? customData;

  ContentAttributeValue({String? label, dynamic value, this.group, this.requirements, this.info, this.customData }) :
    _label = label,
    _value = value;

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
        group: JsonUtils.stringValue(json['group']),
        requirements: JsonUtils.mapValue(json['requirements']),
      );
    }
    else {
      return null;
    }
  }

  toJson() => ((value != null) || (group != null) || (requirements != null)) ? {
    'label': _label,
    'value': _value,
    'group': group,
    'requirements': requirements,
  } : _label;

  // Equality

  @override
  bool operator==(Object other) =>
    (other is ContentAttributeValue) &&
    (_label == other._label) &&
    (_value == other._value) &&
    (group == other.group) &&
    (info == other.info) &&
    (const DeepCollectionEquality().equals(requirements, other.requirements)) &&
    (const DeepCollectionEquality().equals(customData, other.customData));

  @override
  int get hashCode =>
    (_label?.hashCode ?? 0) ^
    (_value?.hashCode ?? 0) ^
    (group?.hashCode ?? 0) ^
    (info?.hashCode ?? 0) ^
    (customData?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(requirements));

  // Clone

  ContentAttributeValue clone() => ContentAttributeValue(
    label: _label,
    value: _value,
    group: group,
    requirements: MapUtils.from(requirements),
    info: info,
    customData: MapUtils.from(customData)
  );

  static List<ContentAttributeValue>? listFromOther(List<ContentAttributeValue>? otherList, { bool clone = false }) {
    if (otherList != null) {
      if (clone) {
        List<ContentAttributeValue> values = <ContentAttributeValue>[];
        for (ContentAttributeValue attributeValue in otherList) {
          values.add(attributeValue.clone());
        }
        return values;
      }
      else {
        return List<ContentAttributeValue>.from(otherList);
      }
    }
    else {
      return null;
    }
  }

  // Accessories

  String? get label => _label;
  String? get selectLabel => _label;
  String? get selectedLabel => _label;

  dynamic get value => _value ?? _label;

  static ContentAttributeValue? findInList(List<ContentAttributeValue>? attributeValues, { dynamic value }) {
    if (attributeValues != null) {
      for (ContentAttributeValue attributeValue in attributeValues) {
        if (attributeValue.value == value) {
          return attributeValue;
        }
      }
    }
    return null;
  }

  bool fulfillsSelection(Map<String, LinkedHashSet<dynamic>>? selection, { ContentAttributeRequirementsMode? requirementsMode }) {
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

  bool _matchRequirement({ dynamic requirement, LinkedHashSet<dynamic>? selection, ContentAttributeRequirementsMode? requirementsMode }) {
    if (requirement == null) {
      return true;
    }
    else if ((selection == null) || selection.isEmpty) {
      return (requirementsMode == ContentAttributeRequirementsMode.inclusive);
    }
    else if (requirement is List) {
      for (dynamic requirementEntry in requirement) {
        if (!_matchRequirement(requirement: requirementEntry, selection: selection)) {
          return false;
        }
      }
      return true;
    }
    else if (requirement != null) {
      return selection.contains(requirement);
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
  final int? _functionalScope;
  final Set<String>? scope;

  ContentAttributeRequirements({this.minSelectedCount, this.maxSelectedCount, this.mode, int? functionalScope, this.scope}) :
    _functionalScope = functionalScope;

  // JSON serialization

  static ContentAttributeRequirements? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributeRequirements(
      minSelectedCount: JsonUtils.intValue(json['min-selected-count']),
      maxSelectedCount: JsonUtils.intValue(json['max-selected-count']),
      mode: contentAttributeRequirementsModeFromString(JsonUtils.stringValue(json['mode'])),
      functionalScope: contentAttributeRequirementsFunctionalScopeFromString(JsonUtils.stringValue(json['functional-scope'])),
      scope: JsonUtils.setStringsValue(json['scope']),
    ) : null;
  }

  toJson() => {
    'min-selected-count' : minSelectedCount,
    'max-selected-count' : maxSelectedCount,
    'mode': contentAttributeRequirementsModeToString(mode),
    'functional-scope': contentAttributeRequirementsFunctionalScopeToString(_functionalScope),
    'scope': JsonUtils.listStringsValue(scope),
  };

  // Equality

  @override
  bool operator==(Object other) =>
    (other is ContentAttributeRequirements) &&
    (minSelectedCount == other.minSelectedCount) &&
    (maxSelectedCount == other.maxSelectedCount) &&
    (mode == other.mode) &&
    (_functionalScope == other._functionalScope) &&
    const DeepCollectionEquality().equals(scope, other.scope);

  @override
  int get hashCode =>
    (minSelectedCount?.hashCode ?? 0) ^
    (maxSelectedCount?.hashCode ?? 0) ^
    (mode?.hashCode ?? 0) ^
    (_functionalScope?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(scope));

  // Clone

  ContentAttributeRequirements clone() => ContentAttributeRequirements(
    minSelectedCount: minSelectedCount,
    maxSelectedCount: maxSelectedCount,
    mode: mode,
    functionalScope: _functionalScope,
    scope: SetUtils.from(scope),
  );

  static List<ContentAttributeRequirements>? listFromOther(List<ContentAttributeRequirements>? otherList, { String? scope, bool clone = false }) {
    if (otherList != null) {
      if (clone) {
        List<ContentAttributeRequirements> cloneList = <ContentAttributeRequirements>[];
        for (ContentAttributeRequirements requirements in otherList) {
          if ((scope == null) || requirements.inScope(scope)) {
            cloneList.add(requirements.clone());
          }
        }
        return cloneList;
      }
      else {
        return List<ContentAttributeRequirements>.from((scope != null) ? otherList.where((ContentAttributeRequirements requirements) => requirements.inScope(scope)) : otherList);
      }
    }
    else {
      return null;
    }
  }

  // Accessories

  int get functionalScope => _functionalScope ?? contentAttributeRequirementsFunctionalScopeCreate; // the scope by default

  bool get hasFilterScope => hasFunctionalScope(contentAttributeRequirementsFunctionalScopeFilter);
  bool get hasCreateScope => hasFunctionalScope(contentAttributeRequirementsFunctionalScopeCreate);
  bool hasFunctionalScope(int functionalScope) => (this.functionalScope & functionalScope) != 0;

  bool inScope(String scopeItem) => scope?.contains(scopeItem) ?? true; // apply to all scopes if no particular scope defined

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

  static int _selectedAttributesCount(dynamic selection) {
    if ((selection is List) || (selection is Set)) {
      return selection.length;
    }
    else if (selection != null) {
      return 1;
    }
    else {
      return 0;
    }
  }

  // List<ContentAttributeRequirements> JSON Serialization

  static List<ContentAttributeRequirements>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttributeRequirements>? values;
    if (jsonList != null) {
      values = <ContentAttributeRequirements>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttributeRequirements.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentAttributeRequirements>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentAttributeRequirements value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
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

////////////////////////////////////////////////
// ContentAttributeRequirementsFunctionalScope

const int contentAttributeRequirementsFunctionalScopeNone   = 0;
const int contentAttributeRequirementsFunctionalScopeCreate = 1;
const int contentAttributeRequirementsFunctionalScopeFilter = 2;
const int contentAttributeRequirementsFunctionalScopeAll    = 3;

int? contentAttributeRequirementsFunctionalScopeFromString(String? value) {
  switch(value) {
    case 'none': return contentAttributeRequirementsFunctionalScopeNone;
    case 'create': return contentAttributeRequirementsFunctionalScopeCreate;
    case 'filter': return contentAttributeRequirementsFunctionalScopeFilter;
    case 'all': return contentAttributeRequirementsFunctionalScopeAll;
    default: return null;
  }
}

String? contentAttributeRequirementsFunctionalScopeToString(int? value) {
  switch(value) {
    case contentAttributeRequirementsFunctionalScopeNone: return 'none';
    case contentAttributeRequirementsFunctionalScopeCreate: return 'create';
    case contentAttributeRequirementsFunctionalScopeFilter: return 'filter';
    case contentAttributeRequirementsFunctionalScopeAll: return 'all';
    default: return null;
  }
}
