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

import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyDataDefaultResponsePanel extends StatefulWidget {
  final String dataKey;
  final List<String> dataKeys;
  final dynamic response;
  //TODO: pass allowed responses?
  final Widget? tabBar;

  const SurveyDataDefaultResponsePanel({Key? key, required this.dataKey, required this.dataKeys, required this.response, this.tabBar}) : super(key: key);

  @override
  _SurveyDataDefaultResponsePanelState createState() => _SurveyDataDefaultResponsePanelState();
}

class _SurveyDataDefaultResponsePanelState extends State<SurveyDataDefaultResponsePanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _responseTextController = TextEditingController();

  late String _surveyDataKey;
  bool _usePreviousResponse = false;

  @override
  void initState() {
    _surveyDataKey = widget.dataKey;
    if (widget.response is String) {
      List<String> responseParts = (widget.response as String).split('.');
      _usePreviousResponse = responseParts.length == 3 && responseParts[0] == 'data' && responseParts[2] == 'response';
    }

    if (widget.response is DateTime) {
      _responseTextController.text = DateTimeUtils.utcDateTimeToString(widget.response, format: "MM-dd-yyyy") ?? '';
    } else {
      _responseTextController.text = widget.response?.toString() ?? '';
    }
    
    super.initState();
  }

  @override
  void dispose() {
    _responseTextController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderBar(title: 'Edit Default Response'),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: SurveyElementCreationWidget(body: _buildDefaultResponseOptions(), completionOptions: _buildDone(), scrollController: _scrollController,)
    );
  }

  Widget _buildDefaultResponseOptions() {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      SurveyElementCreationWidget.buildDropdownWidget<String>(Map.fromIterable(widget.dataKeys), "Survey data key", _surveyDataKey, _onChangeSurveyDataKey, margin: EdgeInsets.zero),
      SurveyElementCreationWidget.buildCheckboxWidget("Previous Answer", _usePreviousResponse, _onTogglePreviousResponse),
      Visibility(visible: !_usePreviousResponse, child: FormFieldText('Response', padding: const EdgeInsets.only(top: 16), controller: _responseTextController))
    ],));
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

  void _onChangeSurveyDataKey(String? value) {
    if (value != null) {
      setState(() {
        _surveyDataKey = value;
      });
    }
  }

  void _onTogglePreviousResponse(bool? value) {
    setState(() {
      _usePreviousResponse = value ?? false;
    });
  }

  void _onTapDone() {
    MapEntry<String, dynamic> updatedResponse = MapEntry(_surveyDataKey, SurveyElementCreationWidget.parseTextForType(_usePreviousResponse ? 'data.$_surveyDataKey.response' : _responseTextController.text));
    Navigator.of(context).pop(updatedResponse);
  }
}