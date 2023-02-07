
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////////////
// ContentAttributes

class ContentAttributes {
  final List<ContentAttributesCategory>? categories;
  final ContentAttributesRequirements? requirements;
  final Map<String, dynamic>? strings;

  ContentAttributes({this.categories, this.requirements, this.strings});

  // JSON serialization

  static ContentAttributes? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributes(
      categories: ContentAttributesCategory.listFromJson(JsonUtils.listValue(json['content'])) ,
      requirements: ContentAttributesRequirements.fromJson(JsonUtils.mapValue(json['requirements'])),
      strings: JsonUtils.mapValue(json['strings']),
    ) : null;
  }

  toJson() => {
    'content': categories,
    'requirements': requirements,
    'strings': strings,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributes) &&
    (requirements == other.requirements) &&
    const DeepCollectionEquality().equals(categories, other.categories) &&
    const DeepCollectionEquality().equals(strings, other.strings);

  @override
  int get hashCode =>
    (requirements?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(categories)) ^
    (const DeepCollectionEquality().hash(strings));

  // Accessories

  bool get isEmpty => categories?.isEmpty ?? true;
  bool get isNotEmpty => !isEmpty;

  String? stringValue(String? key, { String? languageCode }) {
    if ((strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(strings![languageCode]) ??
        JsonUtils.mapValue(strings![Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(strings![Localization().defaultLocale?.languageCode]);
      String? value = (mapping != null) ? JsonUtils.stringValue(mapping[key]) : null;
      if (value != null) {
        return value;
      }
    }
    return key;
  }

  ContentAttributesCategory? findCategory({String? id, String? title}) {
    if ((categories != null) && ((id != null) || (title != null))) {
      for (ContentAttributesCategory category in categories!) {
        if (((id == null) || (category.id == id)) &&
            ((title == null) || (category.title == title))) {
          return category;
        }
      }
    }
    return null;
  }

  static Map<String, LinkedHashSet<String>>? selectionFromAttributesSelection(Map<String, dynamic>? attributesSelection) {
    Map<String, LinkedHashSet<String>>? selection;
    attributesSelection?.forEach((String categoryId, dynamic value) {
      if (value is String) {
        selection ??= <String, LinkedHashSet<String>>{};
        // ignore: prefer_collection_literals
        selection![categoryId] = LinkedHashSet<String>.from(<String>[value]);
      }
      else if (value is List) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![categoryId] = LinkedHashSet<String>.from(JsonUtils.listStringsValue(value)?.reversed ?? <String>[]);
      }
    });
    return selection;
  }

  static Map<String, dynamic>? selectionToAttributesSelection(Map<String, LinkedHashSet<String>>? selection) {
    Map<String, dynamic>? categorySelection;
    selection?.forEach((String categoryId, LinkedHashSet<String> values) {
      if (values.length == 1) {
        categorySelection ??= <String, dynamic>{};
        categorySelection![categoryId] = values.first;
      }
      else if (values.length > 1) {
        categorySelection ??= <String, dynamic>{};
        categorySelection![categoryId] = List.from(List.from(values).reversed);
      }
    });
    return categorySelection;
  }

  void validateSelection(Map<String, LinkedHashSet<String>> selection) {
    bool modified;
    do {
      modified = false;
      for (String categoryId in selection.keys) {
        ContentAttributesCategory? category = findCategory(id: categoryId);
        if (category == null) {
          selection.remove(categoryId);
          modified = true;
          break;
        }
        else if (!category.validateSelection(selection)) {
          modified = true;
          break;
        }
      }
    }
    while (modified);
  }

  bool isCategoriesSelectionValid(Map<String, dynamic>? selection) {
    if (categories != null) {
      for (ContentAttributesCategory category in categories!) {
        dynamic categorySelection = (selection != null) ? selection[category.id] : null;
        if (!category.isSatisfiedFromSelection(categorySelection)) {
          return false;
        }
      }
    }
    return true;
  }

  bool isSelectionValid(Map<String, LinkedHashSet<String>>? selection) =>
    isCategoriesSelectionValid(selection) && (requirements?.isSelectionValid(selection) ?? true);

  bool get hasRequiredCategories {
    if (categories != null) {
      for (ContentAttributesCategory category in categories!) {
        if (category.isRequired) {
          return true;
        }
      }
    }
    return false;
  }

  bool get hasRequired => hasRequiredCategories || (requirements?.hasRequired ?? false);

  List<String> displayAttributesListFromSelection(Map<String, dynamic>? selection, { ContentAttributesCategoryUsage? usage, bool complete = false }) {
    List<String> displayList = <String>[];
    if ((categories != null) && (selection != null)) {
      for (ContentAttributesCategory category in categories!) {
        if ((usage == null) || (category.usage == usage)) {
          displayList.addAll(category.displayAttributesListFromSelection(selection, contentAttributes: this, complete: complete) ?? <String>[]);
        }
      }
    }
    return displayList;
  }
}

/////////////////////////////////////
// ContentAttributesCategory

class ContentAttributesCategory {
  final String? id;
  final String? title;
  final String? description;
  final String? text;
  final String? emptyHint;
  final String? semanticsHint;
  final ContentAttributesCategoryWidget? widget;
  final ContentAttributesCategoryUsage? usage;
  final ContentAttributesCategoryRequirementsMode? requirementsMode;
  final int? minRequiredCount;
  final int? maxRequiredCount;
  final List<ContentAttribute>? attributes;

  ContentAttributesCategory({this.id, this.title, this.description, this.text,
    this.emptyHint, this.semanticsHint, this.widget, this.usage,
    this.requirementsMode, this.minRequiredCount, this.maxRequiredCount,
    this.attributes});

  // JSON serialization

  static ContentAttributesCategory? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributesCategory(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      text: JsonUtils.stringValue(json['text']),
      emptyHint: JsonUtils.stringValue(json['empty-hint']),
      semanticsHint: JsonUtils.stringValue(json['semantics-hint']),
      widget: contentAttributesCategoryWidgetFromString(JsonUtils.stringValue(json['widget'])),
      usage: contentAttributesCategoryUsageFromString(JsonUtils.stringValue(json['usage'])),
      requirementsMode: contentAttributesCategoryRequirementsModeFromString(JsonUtils.stringValue(json['requirements-mode'])),
      minRequiredCount: JsonUtils.intValue(json['min-required-count']),
      maxRequiredCount: JsonUtils.intValue(json['max-required-count']),
      attributes: ContentAttribute.listFromJson(JsonUtils.listValue(json['values'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'text': text,
    'empty-hint': emptyHint,
    'semantics-hint': semanticsHint,
    'widget': contentAttributesCategoryWidgetToString(widget),
    'usage': contentAttributesCategoryUsageToString(usage),
    'requirements-mode': contentAttributesCategoryRequirementsModeToString(requirementsMode),
    'min-required-count' : minRequiredCount,
    'max-required-count' : maxRequiredCount,
    'values': attributes,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributesCategory) &&
    (id == other.id) &&
    (title == other.title) &&
    (description == other.description) &&
    (text == other.text) &&
    (emptyHint == other.emptyHint) &&
    (semanticsHint == other.semanticsHint) &&
    (widget == other.widget) &&
    (usage == other.usage) &&
    (requirementsMode == other.requirementsMode) &&
    (minRequiredCount == other.minRequiredCount) &&
    (maxRequiredCount == other.maxRequiredCount) &&
    const DeepCollectionEquality().equals(attributes, other.attributes);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (text?.hashCode ?? 0) ^
    (emptyHint?.hashCode ?? 0) ^
    (semanticsHint?.hashCode ?? 0) ^
    (widget?.hashCode ?? 0) ^
    (usage?.hashCode ?? 0) ^
    (requirementsMode?.hashCode ?? 0) ^
    (minRequiredCount?.hashCode ?? 0) ^
    (maxRequiredCount?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(attributes));

  // Accessories

  bool get isRequired => (0 < (minRequiredCount ?? 0));
  bool get isMultipleSelection => (maxRequiredCount != 1);
  bool get isSingleSelection => (maxRequiredCount == 1);

  bool get isDropdownWidget => (widget == ContentAttributesCategoryWidget.dropdown);
  bool get isCheckboxWidget => (widget == ContentAttributesCategoryWidget.checkbox);

  bool get isTagUsage => (usage == ContentAttributesCategoryUsage.tag);
  bool get isLabelUsage => (usage == ContentAttributesCategoryUsage.label);
  bool get isCategoryUsage => (usage == ContentAttributesCategoryUsage.category);
  bool get isPropertyUsage => (usage == ContentAttributesCategoryUsage.property);

  ContentAttribute? findAttribute({String? label, dynamic value}) {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (((label == null) || (attribute.label == label)) &&
            ((value == null) || (attribute.value == value)))
        {
          return attribute;
        }
      }
    }
    return null;
  }

  bool validateSelection(Map<String, LinkedHashSet<String>> selection) {
    LinkedHashSet<String>? attributeLabels = selection[id];
    if (attributeLabels != null) {
      for (String attributeLabel in attributeLabels) {
        ContentAttribute? attribute = findAttribute(label: attributeLabel);
        if ((attribute == null) || !attribute.fulfillsSelection(selection, requirementsMode: requirementsMode)) {
          attributeLabels.remove(attributeLabel);
          return false;
        }
      }
    }
    return true;
  }

  bool isSatisfiedFromSelection(dynamic selection) {
    int selectedCount = selectedAttributesCount(selection); 
    return ((minRequiredCount == null) || (minRequiredCount! <= selectedCount)) &&
           ((maxRequiredCount == null) || (maxRequiredCount! >= selectedCount));
  }

  static int selectedAttributesCount(dynamic selection) {
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

  List<ContentAttribute>? attributesFromSelection(Map<String, LinkedHashSet<String>> selection) {
    List<ContentAttribute>? filteredAttributes;
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (attribute.fulfillsSelection(selection, requirementsMode: requirementsMode)) {
          filteredAttributes ??= <ContentAttribute>[];
          filteredAttributes.add(attribute);
        }
      }
    }
    return filteredAttributes;
  }

  List<String>? displayAttributesListFromSelection(Map<String, dynamic>? selection, { ContentAttributes? contentAttributes, bool complete = false } ) {
    dynamic value = (selection != null) ? selection[id] : null;
    if (value is String) {
      String? displayValue = this.displayValue(value, contentAttributes: contentAttributes, complete: complete);
      if (displayValue != null) {
        return <String>[displayValue];
      }
    }
    else if (value is List) {
      List<String> displayList = <String>[];
      for (dynamic entry in value) {
        if (entry is String) {
          String? displayValue = this.displayValue(entry, contentAttributes: contentAttributes, complete: complete);
          if (displayValue != null) {
            displayList.add(displayValue);
          }
        }
      }
      return displayList.isNotEmpty ? displayList : null;
    }
    return null;
  }

  String? displayValue(String attributeLabel, { ContentAttributes? contentAttributes, bool complete = false }) {
    String? displayValue = attributeLabel;
    if ((complete != true) && (widget == ContentAttributesCategoryWidget.checkbox) && (usage == ContentAttributesCategoryUsage.label)) {
      ContentAttribute? attribute = findAttribute(label: attributeLabel);
      displayValue = (attribute?.value == true) ? title : null;
    }
    return (displayValue != null) ? (contentAttributes?.stringValue(displayValue) ?? displayValue) : null;
  }

  // List<ContentAttributesCategory> JSON Serialization

  static List<ContentAttributesCategory>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttributesCategory>? values;
    if (jsonList != null) {
      values = <ContentAttributesCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttributesCategory.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentAttributesCategory>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentAttributesCategory value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

/////////////////////////////////////
// ContentAttributesCategoryWidget

enum ContentAttributesCategoryWidget { dropdown, checkbox }

ContentAttributesCategoryWidget? contentAttributesCategoryWidgetFromString(String? value) {
  switch(value) {
    case 'dropdown': return ContentAttributesCategoryWidget.dropdown;
    case 'checkbox': return ContentAttributesCategoryWidget.checkbox;
    default: return null;
  }
}

String? contentAttributesCategoryWidgetToString(ContentAttributesCategoryWidget? value) {
  switch(value) {
    case ContentAttributesCategoryWidget.dropdown: return 'dropdown';
    case ContentAttributesCategoryWidget.checkbox: return 'checkbox';
    default: return null;
  }
}

/////////////////////////////////////
// ContentAttributesCategoryUsage

enum ContentAttributesCategoryUsage { tag, label, category, property }

ContentAttributesCategoryUsage? contentAttributesCategoryUsageFromString(String? value) {
  switch(value) {
    case 'tag': return ContentAttributesCategoryUsage.tag;
    case 'label': return ContentAttributesCategoryUsage.label;
    case 'category': return ContentAttributesCategoryUsage.category;
    case 'property': return ContentAttributesCategoryUsage.property;
    default: return null;
  }
}

String? contentAttributesCategoryUsageToString(ContentAttributesCategoryUsage? value) {
  switch(value) {
    case ContentAttributesCategoryUsage.tag: return 'tag';
    case ContentAttributesCategoryUsage.label: return 'label';
    case ContentAttributesCategoryUsage.category: return 'category';
    case ContentAttributesCategoryUsage.property: return 'property';
    default: return null;
  }
}

/////////////////////////////////////
// ContentAttributesCategoryRequirementsMode

enum ContentAttributesCategoryRequirementsMode { exclusive, inclusive }

ContentAttributesCategoryRequirementsMode? contentAttributesCategoryRequirementsModeFromString(String? value) {
  switch(value) {
    case 'exclusive': return ContentAttributesCategoryRequirementsMode.exclusive;
    case 'inclusive': return ContentAttributesCategoryRequirementsMode.inclusive;
    default: return null;
  }
}

String? contentAttributesCategoryRequirementsModeToString(ContentAttributesCategoryRequirementsMode? value) {
  switch(value) {
    case ContentAttributesCategoryRequirementsMode.exclusive: return 'exclusive';
    case ContentAttributesCategoryRequirementsMode.inclusive: return 'inclusive';
    default: return null;
  }
}

/////////////////////////////////////
// ContentAttribute

class ContentAttribute {
  final String? label;
  final dynamic value;
  final Map<String, dynamic>? requirements;

  ContentAttribute({this.label, this.value, this.requirements});

  // JSON serialization

  static ContentAttribute? fromJson(dynamic json) {
    if (json is String) {
      return ContentAttribute(
        label: json,
      );
    }
    else if (json is Map) {
      return ContentAttribute(
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
    (other is ContentAttribute) &&
    (label == other.label) &&
    (value == other.value) &&
    const DeepCollectionEquality().equals(requirements, other.requirements);

  @override
  int get hashCode =>
    (label?.hashCode ?? 0) ^
    (value?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(requirements));

  // Accessories

  bool fulfillsSelection(Map<String, LinkedHashSet<String>>? selection, { ContentAttributesCategoryRequirementsMode? requirementsMode }) {
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

  bool _matchRequirement({ dynamic requirement, LinkedHashSet<String>? selection, ContentAttributesCategoryRequirementsMode? requirementsMode }) {
    if (requirement == null) {
      return true;
    }
    else if ((selection == null) || selection.isEmpty) {
      return (requirementsMode == ContentAttributesCategoryRequirementsMode.inclusive);
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

  // List<ContentAttribute> JSON Serialization

  static List<ContentAttribute>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttribute>? values;
    if (jsonList != null) {
      values = <ContentAttribute>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttribute.fromJson(jsonEntry));
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
// ContentAttributesRequirements

class ContentAttributesRequirements {
  final int? minRequiredCount;
  final int? maxRequiredCount;

  ContentAttributesRequirements({this.minRequiredCount, this.maxRequiredCount});

  // JSON serialization

  static ContentAttributesRequirements? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributesRequirements(
      minRequiredCount: JsonUtils.intValue(json['min-required-count']),
      maxRequiredCount: JsonUtils.intValue(json['max-required-count']),
    ) : null;
  }

  toJson() => {
    'min-required-count' : minRequiredCount,
    'max-required-count' : maxRequiredCount,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributesRequirements) &&
    (minRequiredCount == other.minRequiredCount) &&
    (maxRequiredCount == other.maxRequiredCount);

  @override
  int get hashCode =>
    (minRequiredCount?.hashCode ?? 0) ^
    (maxRequiredCount?.hashCode ?? 0);


  // Accessories

  bool isSelectionValid(Map<String, dynamic>? selection) {
    if ((minRequiredCount != null) || (maxRequiredCount != null)) {
      int selectedCount = _selectedCount(selection);
      return ((minRequiredCount == null) || (minRequiredCount! <= selectedCount)) &&
            ((maxRequiredCount == null) || (maxRequiredCount! >= selectedCount));
    }
    else {
      return true;
    }
  }

  bool canSelectMore(Map<String, LinkedHashSet<String>>? selection) {
    return (maxRequiredCount == null) || (maxRequiredCount! > _selectedCount(selection));
  }

  static int _selectedCount(Map<String, dynamic>? selection) {
    int selectedCount = 0;
    if (selection != null) {
      for (dynamic entry in selection.values) {
        if (0 < ContentAttributesCategory.selectedAttributesCount(entry)) {
          selectedCount++;
        }
      }
    }
    return selectedCount;
  }

  bool get hasRequired =>
    (minRequiredCount != null) && (minRequiredCount! > 0);
}
