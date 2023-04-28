/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/rules.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RuleElementCreationPanel extends StatefulWidget {
  final RuleElement data;
  final List<String> dataKeys;
  final List<String> dataTypes;
  final List<String> sections;
  final bool mayChangeType;
  final Widget? tabBar;

  const RuleElementCreationPanel({Key? key, required this.data, required this.dataKeys, required this.dataTypes, required this.sections, this.mayChangeType = true, this.tabBar}) : super(key: key);

  @override
  _RuleElementCreationPanelState createState() => _RuleElementCreationPanelState();
}

class _RuleElementCreationPanelState extends State<RuleElementCreationPanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  late final Map<String, TextEditingController> _textControllers;

  late RuleElement _ruleElem;

  final Map<String, String?> _dataKeySettings = {
    "survey_option": null, // survey, stats, or data
    "survey": null,
    "stats": null,
    "data": null,
    "key": null,
  };

  final Map<String, String?> _compareToSettings = {
    "survey_option": null, // survey, stats, or data
    "survey": null,
    "stats": null,
    "data": null,
    "key": null,
  };
  bool _customCompare = false;

  final Map<String, String?> _actionSettings = {
    "return": null,
    "set_result": null,
    "alert": null,
    "alert_result": null,

    "survey_option": null, // survey, stats, or data
    "survey": null,
    "stats": null,
    "data": null,
    "key": null,
  };

  final Map<String, String> _surveyPropertyOptions = {
    'survey': 'Survey',
    'stats': 'Stats',
    'data': 'Survey Data',
  };

  @override
  void initState() {
    _ruleElem = widget.data;

    RuleComparison? comparison;
    if (_ruleElem is RuleComparison) {
      comparison = _ruleElem as RuleComparison;
    } else if (_ruleElem is Rule) {
      RuleCondition? condition = (_ruleElem as Rule).condition;
      comparison = (condition is RuleComparison) ? condition : null;
    }

    String? customData;
    if (comparison != null) {
      _dataKeySettings.addEntries(_initSettings(comparison.dataKey));

      _customCompare = comparison.compareTo is! String;
      if (!_customCompare) {
        customData = comparison.compareTo as String;
        if (customData.contains('stats') || customData.contains('data') || ListUtils.contains(Surveys.properties.keys, customData)!) {
          _compareToSettings.addEntries(_initSettings(customData));
        } else {
          _customCompare = true;
        }
      } else if (comparison.compareTo is DateTime) {
        customData = DateTimeUtils.utcDateTimeToString((_ruleElem as RuleComparison).compareTo, format: "MM-dd-yyyy") ?? '';
      } else {
        customData = comparison.compareTo?.toString() ?? '';
      }
    } else if (_ruleElem is RuleAction) {
      dynamic actionData = (_ruleElem as RuleAction).data;
      _customCompare = actionData is! String;
      if (!_customCompare) {
        customData = actionData as String;
        if (customData.contains('stats') || customData.contains('data') || ListUtils.contains(Surveys.properties.keys, customData)!) {
          _actionSettings.addEntries(_initSettings(customData));
        } else {
          _customCompare = true;
        }
      } else if (actionData is DateTime) {
        customData = DateTimeUtils.utcDateTimeToString((_ruleElem as RuleAction).data, format: "MM-dd-yyyy") ?? '';
      } else {
        customData = actionData?.toString() ?? '';
      }
    }

    _textControllers = {
      "custom_compare": TextEditingController(text: customData),
      "result_data_key": TextEditingController(text: (_ruleElem is RuleAction) ? (_ruleElem as RuleAction).dataKey : null),
    };
    super.initState();
  }

  List<MapEntry<String, String>> _initSettings(String data) {
    List<MapEntry<String, String>> settingsEntries = [];
    
    List<String> dataFields = data.split(".");
    if (dataFields.length == 1) {
      settingsEntries.add(const MapEntry('survey_option', 'survey'));
      settingsEntries.add(MapEntry('survey', dataFields[0]));
    } else if (dataFields.length > 1) {
      settingsEntries.add(MapEntry('survey_option', dataFields[0]));
      if (dataFields[0] == 'stats') {
        settingsEntries.add(MapEntry('stats', dataFields[1]));
        if (dataFields.length > 2 && widget.sections.contains(dataFields[2])) {
          settingsEntries.add(MapEntry('key', dataFields[2]));
        }
      } else if (dataFields[0] == 'data') {
        settingsEntries.add(MapEntry('key', dataFields[1]));
        if (dataFields.length > 2) {
          settingsEntries.add(MapEntry('data', dataFields[2]));
        }
      }
    }

    return settingsEntries;
  }

  @override
  void dispose() {
    _textControllers.forEach((_, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: "Edit Rule Element"),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: Column(
        children: [
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: _buildRuleElement(),
            ),
          )),
          Container(
            color: Styles().colors?.backgroundVariant,
            child: _buildDone(),
          ),
        ],
    ));
  }

  //TODO:
    // better error messaging (required dropdowns missing selection)
    // handle missing data keys for survey data comparisons
  Widget _buildRuleElement() {
    List<Widget> content = [Visibility(
      visible: widget.mayChangeType,
      child: _buildDropdownWidget<String>(_ruleElem.supportedAlternatives, "Type", _getElementTypeString(), _onChangeElementType, margin: EdgeInsets.zero)
    )];

    String? operator;
    if (_ruleElem is RuleComparison) {
      operator = (_ruleElem as RuleComparison).operator;
    } else if (_ruleElem is Rule) {
      RuleCondition? condition = (_ruleElem as Rule).condition;
      operator = (condition is RuleComparison) ? condition.operator : null;
    }

    if (operator != null) {
      // dataKey
      content.add(_buildSurveyPropertyOptions('data_key'));

      // operator
      content.add(_buildDropdownWidget<String>(RuleComparison.supportedOperators, "Operator", operator, _onChangeComparisonType));

      // compareTo
      Map<bool, String> valueOptions = {false: 'Survey Value', true: 'Custom Value'};
      content.add(_buildDropdownWidget<bool>(valueOptions, "Compare To", _customCompare, _onChangeCompareToType));
      content.add(_buildSurveyPropertyOptions('compare_to'));
    } else if (_ruleElem is RuleReference) {
      //TODO: add later - dropdown showing existing rules by summary? (pass existing rules into panel?)
    } else if (_ruleElem is RuleAction) {
      // action
      content.add(_buildDropdownWidget<String>(RuleAction.supportedActions, "Action", (_ruleElem as RuleAction).action, _onChangeActionType));

      content.add(_buildActionSurveyOptions());
    }

    return Padding(padding: const EdgeInsets.all(16), child: Column(children: content));
  }

  Widget _buildSurveyPropertyOptions(String settings) {
    if (!_customCompare || settings == 'data_key') {
      List<Widget> content = [];

      String? surveyOption;
      Map<String, String?> settingsMap = {};
      switch (settings) {
        case 'data_key':
          surveyOption = _dataKeySettings['survey_option'];
          settingsMap = _dataKeySettings;
          break;
        case 'compare_to':
          surveyOption = _compareToSettings['survey_option'];
          settingsMap = _compareToSettings;
          break;
        case 'action':
          surveyOption = _actionSettings['survey_option'];
          settingsMap = _actionSettings;
          break;
      }

      content.add(_buildDropdownWidget<String>(_surveyPropertyOptions, "Data Field", surveyOption, (value) => _onChangeSurveyPropertySetting(value, settings, 'survey_option')));

      switch (surveyOption) {
        case 'survey':
          content.add(_buildDropdownWidget<String>(Surveys.properties, "Select survey option:", settingsMap['survey'], (value) => _onChangeSurveyPropertySetting(value, settings, 'survey')));
          break;
        case 'stats':
          content.add(_buildDropdownWidget<String>(Surveys.statsProperties, "Select stats option:", settingsMap['stats'], (value) => _onChangeSurveyPropertySetting(value, settings, 'stats')));
          if (settingsMap['stats'] == 'percentage') {
            content.add(_buildDropdownWidget<String>(Map.fromIterable(widget.sections), "Select section:", settingsMap['key'], (value) => _onChangeSurveyPropertySetting(value, settings, 'key')));
          } else if (settingsMap['stats'] == 'response_data') {
            content.add(Visibility(
              visible: widget.sections.isNotEmpty,
              child: _buildDropdownWidget<String>(Map.fromIterable(widget.sections), "Select section:", settingsMap['key'], (value) => _onChangeSurveyPropertySetting(value, settings, 'key'))
            ));
          }
          break;
        case 'data':
          content.add(_buildDropdownWidget<String>(Map.fromIterable(widget.dataKeys), "Select survey data key:", settingsMap['key'],
            (value) => _onChangeSurveyPropertySetting(value, settings, 'key'), padding: const EdgeInsets.all(16)));

          Map<String, String> dataProperties = Surveys.dataProperties;
          int dataKeyIndex = widget.dataKeys.indexOf(settingsMap['data'] ?? '');
          String dataType = dataKeyIndex >= 0 ? widget.dataTypes[dataKeyIndex] : '';
          if (dataType != 'survey_data.true_false') {
            dataProperties.remove('correct_answer');
          }
          if (dataType != 'survey_data.multiple_choice') {
            dataProperties.remove('correct_answers');
          }
          
          content.add(_buildDropdownWidget<String>(dataProperties, "Select survey data option:", settingsMap['data'], (value) => _onChangeSurveyPropertySetting(value, settings, 'data')));
          break;
      }

      return Column(children: content,);
    }

    // dropdown for type selection
    return FormFieldText('Value', padding: const EdgeInsets.only(top: 16.0), controller: _textControllers["custom_compare"], inputType: TextInputType.text, required: true);
  }

  Widget _buildActionSurveyOptions() {
    RuleAction ruleAction = _ruleElem as RuleAction;
    
    switch (ruleAction.action) {
      case 'return':
        return _buildDropdownWidget<String>(Map.fromIterable(widget.dataKeys), "Select survey data key:", _actionSettings['return'],
          (value) => _onChangeActionSetting(value, 'return'), padding: const EdgeInsets.all(16));
      case 'set_result':
        Map<bool, String> valueOptions = {false: 'Survey Value', true: 'Custom Value'};
        return Column(children: [
          _buildDropdownWidget<bool>(valueOptions, "Data Field", _customCompare, _onChangeCompareToType),
          _buildSurveyPropertyOptions('action'),
          FormFieldText('Result Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["result_data_key"], inputType: TextInputType.text),
        ]);
      case 'alert':
        return _buildDropdownWidget<String>(Map.fromIterable(widget.dataKeys), "Select survey data key:", _actionSettings['alert'],
          (value) => _onChangeActionSetting(value, 'alert'), padding: const EdgeInsets.all(16));
      case 'alert_result':
        return Column(children: [
          _buildDropdownWidget<String>(Map.fromIterable(widget.dataKeys), "Select survey data key:", _actionSettings['alert_result'],
            (value) => _onChangeActionSetting(value, 'alert_result'), padding: const EdgeInsets.all(16)),
          FormFieldText('Result Key', padding: const EdgeInsets.only(top: 16), controller: _textControllers["result_data_key"], inputType: TextInputType.text)
        ]);
    }

    return Container();
  }

  Widget _buildDropdownWidget<T>(Map<T, String> supportedItems, String label, T? value, Function(T?)? onChanged,
    {EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16), EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16)}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: Styles().colors?.getColor('surface')),
      padding: padding,
      margin: margin,
      child: Row(children: [
        Text(label, style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<T>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropdownItems<T>(supportedItems),
            value: value,
            onChanged: onChanged,
            dropdownColor: Styles().colors?.getColor('surface'),
          ),
        ),))],
      )
    );
  }

  List<DropdownMenuItem<T>> _buildDropdownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Container(
          color: Styles().colors?.getColor('surface'),
          child: Text(item.value, style: Styles().textStyles?.getTextStyle('widget.detail.regular'), textAlign: TextAlign.center,)
        )),
      ));
    }
    return items;
  }

  Widget _buildDone() {
    return Padding(padding: const EdgeInsets.all(8.0), child: RoundedButton(
      label: 'Done',
      borderColor: Styles().colors?.fillColorPrimaryVariant,
      backgroundColor: Styles().colors?.surface,
      textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
      onTap: _onTapDone,
    ));
  }

  String _toSurveyPropertyString(String settings) {
    Map<String, String?> settingsMap = settings == 'data_key' ? _dataKeySettings : _actionSettings;
    switch (settingsMap['survey_option']) {
      case 'survey':
        return settingsMap['survey'] ?? '';
      case 'stats':
        String statsProperty = settingsMap['stats'] ?? '';
        String dataKey = settingsMap['key'] ?? '';
        return statsProperty.isNotEmpty ? (dataKey.isNotEmpty ? 'stats.$statsProperty.$dataKey' : 'stats.$statsProperty') : 'stats';
      case 'data':
        String dataKey = settingsMap['key'] ?? '';
        String dataProperty = settingsMap['data'] ?? '';
        return dataKey.isNotEmpty ? (dataProperty.isNotEmpty ? 'data.$dataKey.$dataProperty' : 'data.$dataKey') : 'data';
      default:
        return '';
    }
  }

  dynamic get compareToValue {
    if (_customCompare) {
      String valueText = _textControllers['custom_compare']!.text;
      bool? valueBool = valueText.toLowerCase() == 'true' ? true : (valueText.toLowerCase() == 'false' ? false : null);
      return num.tryParse(valueText) ?? DateTimeUtils.dateTimeFromString(valueText) ?? valueBool ?? (valueText.isNotEmpty ? valueText : null);
    }

    switch (_compareToSettings['survey_option']) {
      case 'survey':
        return _compareToSettings['survey'];
      case 'stats':
        String statsProperty = _compareToSettings['stats'] ?? '';
        return statsProperty.isNotEmpty ? 'stats.$statsProperty' : null;
      case 'data':
        String dataKey = _compareToSettings['key'] ?? '';
        String dataProperty = _compareToSettings['data'] ?? '';
        return dataKey.isNotEmpty && dataProperty.isNotEmpty ? 'data.$dataKey.$dataProperty' : null;
      default:
        return '';
    }
  }

  RuleComparison get defaultRuleComparison => RuleComparison(dataKey: _toSurveyPropertyString('data_key'), operator: "==", compareTo: compareToValue);

  RuleAction get defaultRuleAction => RuleAction(action: "return", data: widget.dataKeys.isNotEmpty ? 'data.${widget.dataKeys[0]}' : null);

  void _onChangeElementType(String? elemType) {
    setState(() {
      String id = _ruleElem.id;
      switch (elemType) {
        case "if":
          if (_ruleElem is RuleCondition) {
            _ruleElem = defaultRuleComparison;
          } else if (_ruleElem is Rule) {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: (_ruleElem as Rule).trueResult, falseResult: (_ruleElem as Rule).falseResult);
          } else {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction, falseResult: defaultRuleAction);
          }
          _customCompare = false;
          break;
        case "and":
          RuleLogic defaultAnd = RuleLogic("and", [defaultRuleComparison, defaultRuleComparison]);
          if (_ruleElem is RuleCondition) {
            _ruleElem = defaultAnd;
          } else if (_ruleElem is Rule) {
            _ruleElem = Rule(condition: defaultAnd, trueResult: (_ruleElem as Rule).trueResult, falseResult: (_ruleElem as Rule).falseResult);
          } else {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction, falseResult: defaultRuleAction);
          }
          break;
        case "or":
          RuleLogic defaultOr = RuleLogic("or", [defaultRuleComparison, defaultRuleComparison]);
          if (_ruleElem is RuleCondition) {
            _ruleElem = defaultOr;
          } else if (_ruleElem is Rule) {
            _ruleElem = Rule(condition: defaultOr, trueResult: (_ruleElem as Rule).trueResult, falseResult: (_ruleElem as Rule).falseResult);
          } else {
            _ruleElem = Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction, falseResult: defaultRuleAction);
          }
          break;
        case "cases":
          _ruleElem = RuleCases(cases: [
            Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction),
            Rule(condition: defaultRuleComparison, trueResult: defaultRuleAction)
          ]);
          break;
        case "action":
          _ruleElem = defaultRuleAction;
          break;
        case "action_list":
          _ruleElem = RuleActionList(actions: [defaultRuleAction, defaultRuleAction]);
          break;
        // case "reference":
        //   _ruleElem = RuleReference("");
        //   break;
      }
      _ruleElem.id = id;
    });
  }

  void _onChangeCompareToType(bool? value) {
    setState(() {
      _customCompare = value ?? false;
    });
  }

  void _onChangeSurveyPropertySetting(String? value, String settings, String key) {
    setState(() {
      switch (settings) {
        case 'data_key':
          _dataKeySettings[key] = value;
          break;
        case 'compare_to':
          _compareToSettings[key] = value;
          break;
        case 'action':
          _actionSettings[key] = value;
          break;
      }
    });
  }

  void _onChangeActionSetting(String? value, String key) {
    setState(() {
      _actionSettings[key] = value;
    });
  }

  void _onChangeComparisonType(String? compType) {
    if (compType != null) {
      setState(() {
        if ((_ruleElem as Rule).condition is RuleComparison) {
          ((_ruleElem as Rule).condition as RuleComparison).operator = compType;
        } else if (_ruleElem is RuleComparison) {
          (_ruleElem as RuleComparison).operator = compType;
        }
      });
    }
  }

  void _onChangeActionType(String? actionType) {
    if (actionType != null) {
      setState(() {
        (_ruleElem as RuleAction).action = actionType;
      });
    }
  }

  String? _getElementTypeString() {
    if (_ruleElem is RuleComparison) {
      return "if";
    } else if (_ruleElem is RuleLogic) {
      return (_ruleElem as RuleLogic).operator;
    } else if (_ruleElem is Rule && (_ruleElem as Rule).condition != null) {
      RuleCondition condition = (_ruleElem as Rule).condition!;
      return condition is RuleComparison ? "if" : (condition as RuleLogic).operator;
    } else if (_ruleElem is RuleAction) {
      return "action";
    } else if (_ruleElem is RuleActionList) {
      return "action_list";
    } else if (_ruleElem is RuleCases) {
      return "cases";
    }
    // else if (_ruleElem is RuleReference) {
    //   return "reference";
    // }
    return null;
  }

  void _onTapDone() {
    bool error = false;
    if (_ruleElem is RuleComparison) {
      String dataKeyString = _toSurveyPropertyString('data_key');
      error = dataKeyString.isEmpty;
      (_ruleElem as RuleComparison).dataKey = dataKeyString;
      (_ruleElem as RuleComparison).compareTo = compareToValue;
      (_ruleElem as RuleComparison).defaultResult = false;
    } else if (_ruleElem is Rule && (_ruleElem as Rule).condition is RuleComparison) {
      String dataKeyString = _toSurveyPropertyString('data_key');
      error = dataKeyString.isEmpty;
      ((_ruleElem as Rule).condition as RuleComparison).dataKey = dataKeyString;
      ((_ruleElem as Rule).condition as RuleComparison).compareTo = compareToValue;
      ((_ruleElem as Rule).condition as RuleComparison).defaultResult = false;
    } else if (_ruleElem is RuleAction) {
      switch ((_ruleElem as RuleAction).action) {
        case 'return':
          error = _actionSettings['return'] == null;
          (_ruleElem as RuleAction).data = 'data.${_actionSettings['return']}';
          break;
        case 'set_result':
          error = _customCompare ? (_textControllers['custom_compare']?.text.isEmpty ?? true) : _actionSettings['set_result'] == null;
          (_ruleElem as RuleAction).data = _customCompare ? compareToValue : _toSurveyPropertyString('action');
          String? dataKey = _textControllers['result_data_key']?.text;
          (_ruleElem as RuleAction).dataKey = (dataKey?.isNotEmpty ?? false) ? dataKey : null;
          break;
        case 'alert':
          error = _actionSettings['alert'] == null;
          (_ruleElem as RuleAction).data = 'data.${_actionSettings['alert']}';
          break;
        case 'alert_result':
          error = _actionSettings['alert_result'] == null;
          (_ruleElem as RuleAction).data = 'data.${_actionSettings['alert_result']}';
          String? dataKey = _textControllers['result_data_key']?.text;
          (_ruleElem as RuleAction).dataKey = (dataKey?.isNotEmpty ?? false) ? dataKey : null;
          break;
        case 'save':
          (_ruleElem as RuleAction).data = (_ruleElem as RuleAction).dataKey = null;
      }
    }

    if (error) {
      PopupMessage.show(context: context,
        title: "Invalid Data Key",
        message: "Please fill in all required fields.",
        buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
        onTapButton: (context) {
          Navigator.pop(context);
        },
      );
    } else {
      Navigator.of(context).pop(_ruleElem);
    }    
  }
}