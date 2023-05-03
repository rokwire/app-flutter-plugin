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

import 'package:rokwire_plugin/model/options.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/form_field.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey_creation.dart';

class SurveyDataDefaultResponsePanel extends StatefulWidget {
  final dynamic response;
  //TODO: pass allowed responses?
  final Widget? tabBar;

  const SurveyDataDefaultResponsePanel({Key? key, required this.response, this.tabBar}) : super(key: key);

  @override
  _SurveyDataDefaultResponsePanelState createState() => _SurveyDataDefaultResponsePanelState();
}

class _SurveyDataDefaultResponsePanelState extends State<SurveyDataDefaultResponsePanel> {
  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _textControllers = {};

  late dynamic _response;

  @override
  void initState() {
    _response = widget.response;

    //TODO

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
      appBar: const HeaderBar(title: 'Edit Default Response'),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: Styles().colors?.background,
      body: SurveyElementCreationWidget(body: _buildDefaultResponseOptions(), completionOptions: _buildDone(), scrollController: _scrollController,)
    );
  }

  Widget _buildDefaultResponseOptions() {
    //TODO
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      SurveyElementCreationWidget.buildCheckboxWidget("Correct Answer", (_data as OptionData).isCorrect, _onToggleCorrect),
      FormFieldText('Label', padding: const EdgeInsets.only(top: 16), controller: _textControllers["label"], inputType: TextInputType.text, textCapitalization: TextCapitalization.sentences)
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

  void _onTapDone() {
    //TODO

    Navigator.of(context).pop(_response);
  }
}