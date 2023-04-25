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
import 'package:rokwire_plugin/ui/widgets/radio_button.dart';
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

    String compareTo = '';
    if (comparison != null) {
      List<String> dataKeyFields = comparison.dataKey.split(".");
      if (dataKeyFields.length == 1) {
        _dataKeySettings['survey_option'] = 'survey';
        _dataKeySettings['survey'] = dataKeyFields[0];
      } else if (dataKeyFields.length > 1) {
        _dataKeySettings['survey_option'] = dataKeyFields[0];
        if (dataKeyFields[0] == 'stats') {
          _dataKeySettings['stats'] = dataKeyFields[1];
          if (dataKeyFields.length > 2 && widget.sections.contains(dataKeyFields[2])) {
            _dataKeySettings['key'] = dataKeyFields[2];
          }
        } else if (dataKeyFields[0] == 'data') {
          _dataKeySettings['key'] = dataKeyFields[1];
          _dataKeySettings['data'] = dataKeyFields[2];
        }
      }

      _customCompare = comparison.compareTo is! String;
      if (!_customCompare) {
        compareTo = comparison.compareTo as String;
        if (compareTo.contains('stats') || compareTo.contains('data') || ListUtils.contains(Surveys.properties.keys, compareTo)!) {
          List<String> compareToFields = compareTo.split(".");
          if (compareToFields.length == 1) {
            _compareToSettings['survey_option'] = 'survey';
            _compareToSettings['survey'] = compareToFields[0];
          } else if (compareToFields.length > 1) {
            _compareToSettings['survey_option'] = compareToFields[0];
            if (compareToFields[0] == 'stats') {
              _compareToSettings['stats'] = compareToFields[1];
              if (compareToFields.length > 2 && widget.sections.contains(compareToFields[2])) {
                _compareToSettings['key'] = compareToFields[2];
              }
            } else if (compareToFields[0] == 'data') {
              _compareToSettings['key'] = compareToFields[1];
              _compareToSettings['data'] = compareToFields[2];
            }
          }
        } else {
          _customCompare = true;
        }
      } else if (comparison.compareTo is DateTime) {
        compareTo = DateTimeUtils.utcDateTimeToString((_ruleElem as RuleComparison).compareTo, format: "MM-dd-yyyy") ?? '';
      } else {
        compareTo = comparison.compareTo.toString();
      }
    }

    _textControllers = {
      "custom_compare": TextEditingController(text: compareTo),
      "result_data_key": TextEditingController(text: (_ruleElem is RuleAction) ? (_ruleElem as RuleAction).dataKey : null),
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

  //TODO:
    // better error messaging (required dropdowns missing selection)
    // handle missing data keys for survey data comparisons
  Widget _buildRuleElement() {
    List<Widget> content = [Visibility(visible: widget.mayChangeType, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: 
      Row(children: [
        Text("Type", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropDownItems<String>(_ruleElem.supportedAlternatives),
            value: _getElementTypeString(),
            onChanged: _onChangeElementType,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ))),
      ],)
    ))];

    String? operator;
    if (_ruleElem is RuleComparison) {
      operator = (_ruleElem as RuleComparison).operator;
    } else if (_ruleElem is Rule) {
      RuleCondition? condition = (_ruleElem as Rule).condition;
      operator = (condition is RuleComparison) ? condition.operator : null;
    }

    if (operator != null) {
      // dataKey
      content.add(Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Data Field', style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'))));
      content.add(_buildSurveyPropertyOptions('data_key'));

      // operator
      content.add(Padding(padding: const EdgeInsets.only(left: 16, right: 16, top: 16), child: Row(children: [
        Text("Operator", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropDownItems<String>(RuleComparison.supportedOperators),
            value: operator,
            onChanged: _onChangeComparisonType,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ))),
      ],)));

      // compareTo
      content.add(Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Compare To', style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'))));
      content.add(Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: RadioButton<bool>(
          semanticsLabel: 'Survey Value',
          value: false,
          groupValue: _customCompare,
          onChanged: _onChangeCompareToType,
          textWidget: Text('Survey Value', style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
          insidePadding: const EdgeInsets.all(4),
          backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
          borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
          selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
          disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
          size: 36
        ),),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: RadioButton<bool>(
          semanticsLabel: 'Custom Value',
          value: true,
          groupValue: _customCompare,
          onChanged: _onChangeCompareToType,
          textWidget: Text('Custom Value', style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
          insidePadding: const EdgeInsets.all(4),
          backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
          borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
          selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
          disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
          size: 36
        ),)
      ],));

      content.add(_buildSurveyPropertyOptions('compare_to'));
    } else if (_ruleElem is RuleReference) {
      //TODO: add later - dropdown showing existing rules by summary? (pass existing rules into panel?)
    } else if (_ruleElem is RuleAction) {
      // action
      content.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        Text("Action", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
        Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
          DropdownButton<String>(
            icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
            isExpanded: true,
            style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
            items: _buildDropDownItems<String>(RuleAction.supportedActions),
            value: (_ruleElem as RuleAction).action,
            onChanged: _onChangeActionType,
            dropdownColor: Styles().colors?.getColor('background'),
          ),
        ))),
      ],)));

      content.add(_buildActionSurveyOptions());
    }

    return Padding(padding: const EdgeInsets.only(left: 8, right: 8, top: 20), child: Column(children: content));
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

      List<Widget> surveyComparisonOptions = [];
      for (MapEntry<String, String> option in _surveyPropertyOptions.entries) {
        surveyComparisonOptions.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child:
          RadioButton<String>(
            semanticsLabel: option.value,
            value: option.key,
            groupValue: surveyOption,
            onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'survey_option'),
            textWidget: Text(option.value, style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
            insidePadding: const EdgeInsets.all(4),
            backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
            borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
            selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
            disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
            size: 36
          ),
        ));
      }
      content.add(Padding(padding: const EdgeInsets.only(top: 16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: surveyComparisonOptions,)));

      switch (surveyOption) {
        case 'survey':
          content.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Text("Select survey option:", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Surveys.properties),
                value: settingsMap['survey'],
                onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'survey'),
                dropdownColor: Styles().colors?.getColor('background'),
              ),
            ))),
          ],)));
          break;
        case 'stats':
          content.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Text("Select stats option:", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Surveys.statsProperties),
                value: settingsMap['stats'],
                onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'stats'),
                dropdownColor: Styles().colors?.getColor('background'),
              ),
            ))),
          ],)));
          if (settingsMap['stats'] == 'percentage') {
            content.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              Text("Select section:", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
              Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
                DropdownButton<String>(
                  icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                  isExpanded: true,
                  style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                  items: _buildDropDownItems<String>(Map.fromIterable(widget.sections)),
                  value: settingsMap['key'],
                  onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'key'),
                  dropdownColor: Styles().colors?.getColor('background'),
                ),
              ))),
            ],)));
          } else if (settingsMap['stats'] == 'response_data') {
            content.add(Visibility(visible: widget.sections.isNotEmpty, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              Text("Select survey data key:", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
              Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
                DropdownButton<String>(
                  icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                  isExpanded: true,
                  style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                  items: _buildDropDownItems<String>(Map.fromIterable(widget.sections)),
                  value: settingsMap['key'],
                  onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'key'),
                  dropdownColor: Styles().colors?.getColor('background'),
                ),
              ),))],)
            )));
          }
          break;
        case 'data':
          content.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Text("Select survey data key:", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Map.fromIterable(widget.dataKeys)),
                value: settingsMap['key'],
                onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'key'),
                dropdownColor: Styles().colors?.getColor('background'),
              ),
            ))),
          ],)));

          Map<String, String> dataProperties = Surveys.dataProperties;
          int dataKeyIndex = widget.dataKeys.indexOf(settingsMap['data'] ?? '');
          String dataType = dataKeyIndex >= 0 ? widget.dataTypes[dataKeyIndex] : '';
          if (dataType != 'survey_data.true_false') {
            dataProperties.remove('correct_answer');
          }
          if (dataType != 'survey_data.multiple_choice') {
            dataProperties.remove('correct_answers');
          }
          content.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Text("Select survey data option:", style: Styles().textStyles?.getTextStyle('widget.message.regular')),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(dataProperties),
                value: settingsMap['data'],
                onChanged: (value) => _onChangeSurveyPropertySetting(value, settings, 'data'),
                dropdownColor: Styles().colors?.getColor('background'),
              ),
            ))),
          ],)));
          break;
      }

      return Column(children: content,);
    }

    return Padding(padding: const EdgeInsets.only(top: 16.0), child: FormFieldText('Value', controller: _textControllers["custom_compare"], inputType: TextInputType.text, required: true));
  }

  Widget _buildActionSurveyOptions() {
    RuleAction ruleAction = _ruleElem as RuleAction;
    
    switch (ruleAction.action) {
      case 'return':
        return Row(children: [
          Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select survey data key:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
          Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
            DropdownButton<String>(
              icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
              isExpanded: true,
              style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
              items: _buildDropDownItems<String>(Map.fromIterable(widget.dataKeys)),
              value: _actionSettings['return'],
              onChanged: (value) => _onChangeActionSetting(value, 'return'),
              dropdownColor: Styles().colors?.getColor('background'),
            ),
          ))),
        ],);
      case 'set_result':
        return Column(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Data Field', style: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: RadioButton<bool>(
              semanticsLabel: 'Survey Value',
              value: false,
              groupValue: _customCompare,
              onChanged: _onChangeCompareToType,
              textWidget: Text('Survey Value', style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
              insidePadding: const EdgeInsets.all(4),
              backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
              borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
              selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
              disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
              size: 36
            ),),
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: RadioButton<bool>(
              semanticsLabel: 'Custom Value',
              value: true,
              groupValue: _customCompare,
              onChanged: _onChangeCompareToType,
              textWidget: Text('Custom Value', style: Styles().textStyles?.getTextStyle('widget.detail.medium'), textAlign: TextAlign.center),
              insidePadding: const EdgeInsets.all(4),
              backgroundDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.surface),
              borderDecoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorPrimaryVariant),
              selectedWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.fillColorSecondary)),
              disabledWidget: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: Styles().colors?.mediumGray)),
              size: 36
            ),)
          ],),
          _buildSurveyPropertyOptions('action'),
          Padding(padding: const EdgeInsets.only(top: 16.0), child: FormFieldText('Result Key', controller: _textControllers["result_data_key"], inputType: TextInputType.text, padding: const EdgeInsets.only(bottom: 8))),
        ]);
      case 'alert':
        return Row(children: [
          Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select survey data key:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
          Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
            DropdownButton<String>(
              icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
              isExpanded: true,
              style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
              items: _buildDropDownItems<String>(Map.fromIterable(widget.dataKeys)),
              value: _actionSettings['alert'],
              onChanged: (value) => _onChangeActionSetting(value, 'alert'),
              dropdownColor: Styles().colors?.getColor('background'),
            ),
          ))),
        ],);
      case 'alert_result':
        return Column(children: [
          Row(children: [
            Padding(padding: const EdgeInsets.only(left: 16), child: Text("Select survey data key:", style: Styles().textStyles?.getTextStyle('widget.message.regular'))),
            Expanded(child: Align(alignment: Alignment.centerRight, child: DropdownButtonHideUnderline(child:
              DropdownButton<String>(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                items: _buildDropDownItems<String>(Map.fromIterable(widget.dataKeys)),
                value: _actionSettings['alert_result'],
                onChanged: (value) => _onChangeActionSetting(value, 'alert_result'),
                dropdownColor: Styles().colors?.getColor('background'),
              ),
            ))),
          ],),
          FormFieldText('Result Key', controller: _textControllers["result_data_key"], inputType: TextInputType.text, padding: const EdgeInsets.only(bottom: 8))
        ]);
    }

    return Container();
  }

  List<DropdownMenuItem<T>> _buildDropDownItems<T>(Map<T, String> supportedItems) {
    List<DropdownMenuItem<T>> items = [];

    for (MapEntry<T, String> item in supportedItems.entries) {
      items.add(DropdownMenuItem<T>(
        value: item.key,
        child: Align(alignment: Alignment.center, child: Container(
          color: Styles().colors?.getColor('background'),
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

  String toSurveyPropertyString(String settings) {
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

  RuleComparison get defaultRuleComparison => RuleComparison(dataKey: toSurveyPropertyString('data_key'), operator: "==", compareTo: compareToValue);

  RuleAction get defaultRuleAction => RuleAction(action: "return", data: widget.dataKeys.isNotEmpty ? 'data.${widget.dataKeys[0]}' : null);

  void _onChangeElementType(String? elemType) {
    _updateState(() {
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

  void _onChangeCompareToType(bool value) {
    _updateState(() {
      _customCompare = value;
    });
  }

  void _onChangeSurveyPropertySetting(String? value, String settings, String key) {
    _updateState(() {
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
    _updateState(() {
      _actionSettings[key] = value;
    });
  }

  void _onChangeComparisonType(String? compType) {
    if (compType != null) {
      _updateState(() {
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
      _updateState(() {
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
      String dataKeyString = toSurveyPropertyString('data_key');
      error = dataKeyString.isEmpty;
      (_ruleElem as RuleComparison).dataKey = dataKeyString;
      (_ruleElem as RuleComparison).compareTo = compareToValue;
      (_ruleElem as RuleComparison).defaultResult = false;
    } else if (_ruleElem is Rule && (_ruleElem as Rule).condition is RuleComparison) {
      String dataKeyString = toSurveyPropertyString('data_key');
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
          error = _actionSettings['set_result'] == null;
          (_ruleElem as RuleAction).data = _customCompare ? compareToValue : toSurveyPropertyString('action');
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