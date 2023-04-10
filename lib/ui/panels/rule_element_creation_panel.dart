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
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/radio_button.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RuleElementCreationPanel extends StatefulWidget {
  final RuleElement data;
  final List<String> dataKeys;
  final bool mayChangeType;
  final Widget? tabBar;

  const RuleElementCreationPanel({Key? key, required this.data, required this.dataKeys, this.mayChangeType = true, this.tabBar}) : super(key: key);

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
  bool? _customCompare;

  final Map<String, String> _surveyComparisonOptions = {
    'survey': 'Survey',
    'stats': 'Stats',
    'data': 'Survey Data',
  };

  @override
  void initState() {
    _ruleElem = widget.data;
    String compareTo = '';
    if (_ruleElem is RuleComparison) {
      List<String> dataKeyFields = compareTo.split(".");
      if (dataKeyFields.length == 1) {
        _dataKeySettings['survey_option'] = 'survey';
        _dataKeySettings['survey'] = dataKeyFields[0];
      } else if (dataKeyFields.length == 2) {
        _dataKeySettings['survey_option'] = 'stats';
        _dataKeySettings['stats'] = dataKeyFields[1];
      } else if (dataKeyFields.length == 3) {
        _dataKeySettings['survey_option'] = 'data';
        _dataKeySettings['data'] = dataKeyFields[2];
        _dataKeySettings['key'] = dataKeyFields[1];
      }

      _customCompare = (_ruleElem as RuleComparison).compareTo is! String;
      if (!_customCompare!) {
        compareTo = (_ruleElem as RuleComparison).compareTo as String;
        if (compareTo.contains('stats') || compareTo.contains('data') || ListUtils.contains(Surveys.properties.keys, compareTo)!) {
          List<String> compareToFields = compareTo.split(".");
          if (compareToFields.length == 1) {
            _compareToSettings['survey_option'] = 'survey';
            _compareToSettings['survey'] = compareToFields[0];
          } else if (compareToFields.length == 2) {
            _compareToSettings['survey_option'] = 'stats';
            _compareToSettings['stats'] = compareToFields[1];
          } else if (compareToFields.length == 3) {
            _compareToSettings['survey_option'] = 'data';
            _compareToSettings['data'] = compareToFields[2];
            _compareToSettings['key'] = compareToFields[1];
          }
        } else {
          _customCompare = true;
        }
      } else if ((_ruleElem as RuleComparison).compareTo is! DateTime) {
        compareTo = DateTimeUtils.utcDateTimeToString((_ruleElem as RuleComparison).compareTo, format: "MM-dd-yyyy") ?? '';
      } else {
        compareTo = (_ruleElem as RuleComparison).compareTo.toString();
      }
    }

    _textControllers = {
      "custom_compare": TextEditingController(text: compareTo),
    };
    super.initState();
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

  Widget _buildRuleElement() {
    List<Widget> content = [Visibility(visible: widget.mayChangeType, child: DropdownButtonHideUnderline(child:
      DropdownButton<String>(
        icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
        isExpanded: true,
        style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
        items: _buildDropDownItems<String>(_ruleElem.supportedAlternatives),
        value: _getElementTypeString(),
        onChanged: _onChangeElementType,
        dropdownColor: Styles().colors?.getColor('surface'),
      ),
    ))];
    if (_ruleElem is RuleComparison) {
      // operator
      content.add(Row(children: [
        Padding(padding: const EdgeInsets.only(left: 16), child: Text("Operator", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropDownItems<String>(RuleComparison.supportedOperators),
            value: (_ruleElem as RuleComparison).operator,
            onChanged: _onChangeComparisonType,
            dropdownColor: Styles().colors?.getColor('surface'),
          ),
        ))),
      ],));

      content.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: RadioButton<bool>(
          semanticsLabel: 'Survey Value',
          value: false,
          groupValue: _customCompare,
          onChanged: _onChangeCompareToType,
          textWidget: Text('Survey Value', style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
          backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
          borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
          selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
          disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
          size: 24
        ),),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: RadioButton<bool>(
          semanticsLabel: 'Custom Value',
          value: true,
          groupValue: _customCompare,
          onChanged: _onChangeCompareToType,
          textWidget: Text('Custom Value', style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
          backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
          borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
          selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
          disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
          size: 24
        ),)
      ],));

      // dataKey
      content.add(_buildComparisonSurveyOptions(dataKey: true));
      // compareTo
      content.add(_buildComparisonSurveyOptions(dataKey: false));
      
      // dropdown for data keys, compare_to options (stats, responses, etc., text entry as alternative)
    } else if (_ruleElem is RuleLogic) {
      // operator
      content.add(Row(children: [
        Padding(padding: const EdgeInsets.only(left: 16), child: Text("Operator", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropDownItems<String>(RuleLogic.supportedOperators),
            value: (_ruleElem as RuleLogic).operator,
            onChanged: _onChangeLogicType,
            dropdownColor: Styles().colors?.getColor('surface'),
          ),
        ))),
      ],));
    } else if (_ruleElem is RuleReference) {
      //TODO: add later - dropdown showing existing rules by summary? (pass existing rules into panel?)
    } else if (_ruleElem is RuleAction) {
      // action
      content.add(Row(children: [
        Padding(padding: const EdgeInsets.only(left: 16), child: Text("Action", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropDownItems<String>(RuleAction.supportedActions),
            value: (_ruleElem as RuleAction).action,
            onChanged: _onChangeActionType,
            dropdownColor: Styles().colors?.getColor('surface'),
          ),
        ))),
      ],));
      // data entry
      // data key entry/dropdown

      // "return": "Return",
      // "set_result": "Set Result", // data keys or text entry or data key and result data map key
      // "alert": "Alert",
      // "alert_result": "Alert Result", // data keys or data key and result data map key
      // "save": "Save",
    }

    return Padding(padding: const EdgeInsets.only(left: 8, right: 8, top: 20), child: Column(children: content));
  }

  Widget _buildComparisonSurveyOptions({bool dataKey = true}) {
    if (!_customCompare!) {
      List<Widget> content = [];

      String? surveyOption = dataKey ? _dataKeySettings['survey_option'] : _compareToSettings['survey_option'];
      List<Widget> surveyComparisonOptions = [];
      for (MapEntry<String, String> option in _surveyComparisonOptions.entries) {
        surveyComparisonOptions.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child:
          RadioButton<String>(
            semanticsLabel: option.value,
            value: option.key,
            groupValue: surveyOption,
            onChanged: (value) => _onChangeComparisonSetting(value, dataKey, 'survey_option'),
            textWidget: Text(option.value, style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
            backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
            borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
            selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
            disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
            size: 24
          ),
        ));
      }
      content.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: surveyComparisonOptions,));

      switch (surveyOption) {
        case 'survey':
          content.add(Row(children: [
            Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select survey option:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Surveys.properties),
                value: _dataKeySettings['survey'],
                onChanged: (value) => _onChangeComparisonSetting(value, dataKey, 'survey'),
                dropdownColor: Styles().colors?.getColor('surface'),
              ),
            ))),
          ],));
          break;
        case 'stats':
          content.add(Row(children: [
            Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select stats option:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Surveys.statsProperties),
                value: _dataKeySettings['stats'],
                onChanged: (value) => _onChangeComparisonSetting(value, dataKey, 'stats'),
                dropdownColor: Styles().colors?.getColor('surface'),
              ),
            ))),
          ],));
          break;
        case 'data':
          content.add(Row(children: [
            Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select survey data key:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Map.fromIterable(widget.dataKeys)),
                value: _dataKeySettings['key'],
                onChanged: (value) => _onChangeComparisonSetting(value, dataKey, 'key'),
                dropdownColor: Styles().colors?.getColor('surface'),
              ),
            ))),
          ],));
          content.add(Row(children: [
            Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select survey data option:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Surveys.dataProperties),
                value: _dataKeySettings['data'],
                onChanged: (value) => _onChangeComparisonSetting(value, dataKey, 'data'),
                dropdownColor: Styles().colors?.getColor('surface'),
              ),
            ))),
          ],));
          break;
      }
    }

    return FormFieldText('Value', controller: _textControllers["custom_compare"], inputType: TextInputType.text, required: true);
  }

  List<DropdownMenuItem<T>> _buildDropDownItems<T>(Map<T, String> supportedItems) {
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
    return Padding(padding: const EdgeInsets.all(4.0), child: RoundedButton(
      label: 'Done',
      borderColor: Styles().colors?.fillColorPrimaryVariant,
      backgroundColor: Styles().colors?.surface,
      textStyle: Styles().textStyles?.getTextStyle('widget.detail.large.fat'),
      onTap: _onTapDone,
    ));
  }

  String get dataKeyValue {
    switch (_dataKeySettings['survey_option']) {
      case 'survey':
        return _dataKeySettings['survey'] ?? '';
      case 'stats':
        String statsProperty = _dataKeySettings['stats'] ?? '';
        return statsProperty.isNotEmpty ? 'stats.$statsProperty' : 'stats';
      case 'data':
        String dataKey = _dataKeySettings['key'] ?? '';
        String dataProperty = _dataKeySettings['data'] ?? '';
        return dataKey.isNotEmpty ? (dataProperty.isNotEmpty ? 'data.$dataKey.$dataProperty' : 'data.$dataKey') : 'data';
      default:
        return '';
    }
  }

  dynamic get compareToValue {
    if (_customCompare!) {
      String valueText = _textControllers['custom_compare']!.text;
      bool? valueBool = valueText.toLowerCase() == 'true' ? true : (valueText.toLowerCase() == 'false' ? false : null);
      return num.tryParse(valueText) ?? DateTimeUtils.dateTimeFromString(valueText) ?? valueBool ?? valueText;
    }

    switch (_compareToSettings['survey_option']) {
      case 'survey':
        return _compareToSettings['survey'] ?? '';
      case 'stats':
        String statsProperty = _compareToSettings['stats'] ?? '';
        return statsProperty.isNotEmpty ? 'stats.$statsProperty' : 'stats';
      case 'data':
        String dataKey = _compareToSettings['key'] ?? '';
        String dataProperty = _compareToSettings['data'] ?? '';
        return dataKey.isNotEmpty ? (dataProperty.isNotEmpty ? 'data.$dataKey.$dataProperty' : 'data.$dataKey') : 'data';
      default:
        return '';
    }
  }

  void _onChangeElementType(String? elemType) {
    //TODO: what should defaults be for these?
    _updateState(() {
      String id = _ruleElem.id;
      switch (elemType) {
        case "comparison":
          _ruleElem = RuleComparison(dataKey: dataKeyValue, operator: "==", compareTo: compareToValue);
          _customCompare ??= false;
          break;
        case "logic":
          _ruleElem = RuleLogic("and", [
            RuleComparison(dataKey: "", operator: "==", compareTo: ""),
            RuleComparison(dataKey: "", operator: "==", compareTo: ""),
          ]);
          break;
        case "reference":
          _ruleElem = RuleReference("");
          break;
        case "rule":
          _ruleElem = Rule(
            condition: RuleComparison(dataKey: "", operator: "==", compareTo: ""),
            trueResult: RuleAction(action: "return", data: null),
            falseResult: RuleAction(action: "return", data: null),
          );
          break;
        case "action":
          _ruleElem = RuleAction(action: "return", data: null);
          break;
        case "action_list":
          _ruleElem = RuleActionList(actions: [
            RuleAction(action: "return", data: null)
          ]);
          break;
        case "cases":
          _ruleElem = RuleCases(cases: [
            Rule(
              condition: RuleComparison(dataKey: "", operator: "==", compareTo: ""),
              trueResult: RuleAction(action: "return", data: null),
            )
          ]);
          break;
      }
      _ruleElem.id = id;
    });
  }

  void _onChangeCompareToType(bool value) {
    _updateState(() {
      _customCompare = value;
    });
  }

  void _onChangeComparisonSetting(String? value, bool dataKey, String key) {
    _updateState(() {
      if (dataKey) {
        _dataKeySettings[key] = value;
      } else {
        _compareToSettings[key] = value;
      }
    });
  }

  void _onChangeComparisonType(String? compType) {
    //TODO: what should defaults be?
    if (compType != null) {
      _updateState(() {
        (_ruleElem as RuleComparison).operator = compType;
      });
    }
  }

  void _onChangeLogicType(String? logicType) {
    if (logicType != null) {
      _updateState(() {
        (_ruleElem as RuleLogic).operator = logicType;
      });
    }
  }

  void _onChangeActionType(String? actionType) {
    if (actionType != null) {
      _updateState(() {
        (_ruleElem as RuleAction).action = actionType;
      });
    }
  }

  String? _getElementTypeString() {
    if (_ruleElem is RuleComparison) {
      return "comparison";
    } else if (_ruleElem is RuleLogic) {
      return "logic";
    } else if (_ruleElem is RuleReference) {
      return "reference";
    } else if (_ruleElem is Rule) {
      return "rule";
    }  else if (_ruleElem is RuleAction) {
      return "action";
    } else if (_ruleElem is RuleActionList) {
      return "action_list";
    } else if (_ruleElem is RuleCases) {
      return "cases";
    }
    return null;
  }

  void _onTapDone() {
    if (_ruleElem is RuleComparison) {
      (_ruleElem as RuleComparison).dataKey = dataKeyValue;
      (_ruleElem as RuleComparison).compareTo = compareToValue;
      (_ruleElem as RuleComparison).defaultResult = false;
    }
    
    Navigator.of(context).pop(_ruleElem);
  }

  void _updateState(Function() fn) {
    if (mounted) {
      setState(() {
        fn();
      });
    }
  }
}