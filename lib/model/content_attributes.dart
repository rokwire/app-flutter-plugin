
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

  bool isSelectionValid(Map<String, LinkedHashSet<dynamic>>? selection) =>
    isAttributesSelectionValid(selection) && (requirements?.isAttributesSelectionValid(selection) ?? true);

  bool hasRequiredAttributes(int scope) {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (attribute.isRequired(scope)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasRequired(int scope) => hasRequiredAttributes(scope) || (requirements?.hasRequired ?? false);

  List<String> displayLabelsFromSelection(Map<String, dynamic>? selection, { ContentAttributeUsage? usage, bool complete = false }) {
    List<String> displayList = <String>[];
    if ((attributes != null) && (selection != null)) {
      for (ContentAttribute attribute in attributes!) {
        if ((usage == null) || (attribute.usage == usage)) {
          displayList.addAll(attribute.displayLabelsFromSelection(selection, complete: complete) ?? <String>[]);
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

  // Accessories

  String? get displayTitle => displayString(title);
  String? get displayLongTitle => displayString(longTitle);
  String? get displayDescription => displayString(description);
  String? get displayText => displayString(text);
  String? get displayEmptyHint => displayString(emptyHint);
  String? get displayEmptyFilterHint => displayString(emptyFilterHint);
  String? get displaySemanticsHint => displayString(semanticsHint);
  String? get displaySemanticsFilterHint => displayString(semanticsFilterHint);

  ContentAttributeRequirements? requirementsForScope(int scope) => (((requirements?.scope ?? 0) & scope) != 0) ? requirements : null;
  bool isRequired(int scope) => requirementsForScope(scope)?.hasRequired ?? false;
  bool isMultipleSelection(int scope) => (requirementsForScope(scope)?.maxSelectedCount != 1);
  bool isSingleSelection(int scope) => (requirementsForScope(scope)?.maxSelectedCount == 1);
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
      for (LinkedHashSet<dynamic> groupSelection in groupsSelection.values) {
        if (!requirements!.isAttributeValuesSelectionValid(groupSelection)) {
          return false;
        }
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

  List<String>? displayLabelsFromSelection(Map<String, dynamic>? selection, { bool complete = false } ) {
    dynamic rawValue = (selection != null) ? selection[id] : null;
    return displayLabelsFromRawValue(rawValue, complete: complete);
  }

  List<String>? displayLabelsFromRawValue(dynamic rawValue, { bool complete = false } ) {
    if ((rawValue is List) || (rawValue is Set)) {
      List<String> displayList = <String>[];
      for (dynamic rawEntry in rawValue) {
        String? displayValue = displayLabel(rawEntry, complete: complete);
        if (displayValue != null) {
          displayList.add(displayValue);
        }
      }
      return displayList.isNotEmpty ? displayList : null;
    }
    else if (rawValue != null) {
      String? displayValue = displayLabel(rawValue, complete: complete);
      if (displayValue != null) {
        return <String>[displayValue];
      }
    }
    return null;
  }

  String? displayLabel(dynamic attributeRawValue, { bool complete = false }) {
    ContentAttributeValue? attributeValue = findValue(value: attributeRawValue);
    String? displayValue = attributeValue?.label;
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
  final dynamic _value;
  final String? group;
  final Map<String, dynamic>? requirements;
  
  String? info;
  Map<String, dynamic>? customData;

  ContentAttributeValue({this.label, this.info, dynamic value, this.group, this.requirements, this.customData }) :
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
    'label': label,
    'value': _value,
    'group': group,
    'requirements': requirements,
  } : label;

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributeValue) &&
    (label == other.label) &&
    (info == other.info) &&
    (_value == other._value) &&
    (group == other.group) &&
    (const DeepCollectionEquality().equals(requirements, other.requirements)) &&
    (const DeepCollectionEquality().equals(customData, other.customData));

  @override
  int get hashCode =>
    (label?.hashCode ?? 0) ^
    (info?.hashCode ?? 0) ^
    (_value?.hashCode ?? 0) ^
    (group?.hashCode ?? 0) ^
    (customData?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(requirements));

  // Accessories

  dynamic get value => _value ?? label;

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
  final int? _scope;

  ContentAttributeRequirements({this.minSelectedCount, this.maxSelectedCount, this.mode, int? scope}) :
    _scope = scope;

  // JSON serialization

  static ContentAttributeRequirements? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributeRequirements(
      minSelectedCount: JsonUtils.intValue(json['min-selected-count']),
      maxSelectedCount: JsonUtils.intValue(json['max-selected-count']),
      mode: contentAttributeRequirementsModeFromString(JsonUtils.stringValue(json['mode'])),
      scope: contentAttributeRequirementsScopeFromString(JsonUtils.stringValue(json['scope'])),
    ) : null;
  }

  toJson() => {
    'min-selected-count' : minSelectedCount,
    'max-selected-count' : maxSelectedCount,
    'mode': contentAttributeRequirementsModeToString(mode),
    'scope': contentAttributeRequirementsScopeToString(_scope),
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributeRequirements) &&
    (minSelectedCount == other.minSelectedCount) &&
    (maxSelectedCount == other.maxSelectedCount) &&
    (mode == other.mode) &&
    (_scope == other._scope);

  @override
  int get hashCode =>
    (minSelectedCount?.hashCode ?? 0) ^
    (maxSelectedCount?.hashCode ?? 0) ^
    (mode?.hashCode ?? 0) ^
    (_scope?.hashCode ?? 0);


  // Accessories

  int get scope => _scope ?? contentAttributeRequirementsScopeCreate; // the scope by default

  bool get hasFilterScope => hasScope(contentAttributeRequirementsScopeFilter);
  bool get hasCreateScope => hasScope(contentAttributeRequirementsScopeCreate);
  bool hasScope(int scope) => (this.scope & scope) != 0;

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

/////////////////////////////////////
// ContentAttributeRequirementsScope

const int contentAttributeRequirementsScopeNone   = 0;
const int contentAttributeRequirementsScopeCreate = 1;
const int contentAttributeRequirementsScopeFilter = 2;
const int contentAttributeRequirementsScopeAll    = 3;

int? contentAttributeRequirementsScopeFromString(String? value) {
  switch(value) {
    case 'none': return contentAttributeRequirementsScopeNone;
    case 'create': return contentAttributeRequirementsScopeCreate;
    case 'filter': return contentAttributeRequirementsScopeFilter;
    case 'all': return contentAttributeRequirementsScopeAll;
    default: return null;
  }
}

String? contentAttributeRequirementsScopeToString(int? value) {
  switch(value) {
    case contentAttributeRequirementsScopeNone: return 'none';
    case contentAttributeRequirementsScopeCreate: return 'create';
    case contentAttributeRequirementsScopeFilter: return 'filter';
    case contentAttributeRequirementsScopeAll: return 'all';
    default: return null;
  }
}
