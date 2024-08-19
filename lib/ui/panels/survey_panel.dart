/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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

import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';

import 'package:rokwire_plugin/ui/widgets/survey.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart';

class SurveyPanel extends StatefulWidget {
  final dynamic survey;
  final String? surveyDataKey;
  final bool inputEnabled;
  final DateTime? dateTaken;
  final bool showResult;
  final Function(dynamic)? onComplete;
  final int initPanelDepth;
  final Map<String, dynamic>? defaultResponses;
  final bool summarizeResultRules;
  final Widget? summarizeResultRulesWidget;
  final PreferredSizeWidget? headerBar;
  final Widget? tabBar;
  final Widget? offlineWidget;
  final Color? backgroundColor;
  final SurveyWidgetTextStyles? textStyles;

  const SurveyPanel({Key? key, required this.survey, this.surveyDataKey, this.inputEnabled = true,
    this.dateTaken, this.showResult = false, this.onComplete, this.initPanelDepth = 0, this.defaultResponses,
    this.summarizeResultRules = false, this.summarizeResultRulesWidget, this.headerBar, this.tabBar,
    this.backgroundColor, this.offlineWidget, this.textStyles}) : super(key: key);

  @override
  _SurveyPanelState createState() => _SurveyPanelState();

  @protected PreferredSizeWidget? buildHeaderBar(String? title) => HeaderBar(title: title);
}

class _SurveyPanelState extends State<SurveyPanel> {
  final bool _loading = false;
  Survey? _survey;
  SurveyData? _mainSurveyData;
  late final Color _backgroundColor;

  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  bool _scrollEnd = false;

  late final SurveyWidgetController _surveyController;

  @override
  void initState() {
    _surveyController = SurveyWidgetController(beforeComplete: widget.summarizeResultRules ? null : _beforeComplete, onComplete: widget.onComplete,
        onChangeSurveyResponse: _onChangeSurveyResponse, onLoad: _onSurveyLoaded);
    if (widget.survey is Survey) {
      _setSurvey(widget.survey!);
    }
    _backgroundColor = widget.backgroundColor ?? defaultBackgroundColor ?? Styles().colors.background;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_checkScroll);
    return Scaffold(
      appBar: widget.headerBar ?? widget.buildHeaderBar(_survey?.title),
      bottomNavigationBar: widget.tabBar,
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          Visibility(visible: _loading, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorPrimary))),
          Expanded(child: Scrollbar(
            radius: const Radius.circular(2),
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SurveyWidget(
                survey: widget.survey,
                inputEnabled: widget.inputEnabled,
                dateTaken: widget.dateTaken,
                showResult: widget.showResult,
                surveyDataKey: widget.surveyDataKey,
                mainSurveyData: _mainSurveyData,
                internalContinueButton: false,
                controller: _surveyController,
                defaultResponses: widget.defaultResponses,
                summarizeResultRules: widget.summarizeResultRules,
                summarizeResultRulesWidget: widget.summarizeResultRulesWidget,
                offlineWidget: widget.offlineWidget,
                textStyles: widget.textStyles ?? defaultTextStyles,
              ),
            ),
          )),
          Visibility(
            visible: widget.inputEnabled,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: SurveyWidget.buildContinueButton(_surveyController),
            ),
          ),
        ],
    ));
  }

  void _beforeComplete() {
    Navigator.of(context).pop();
  }

  void _onSurveyLoaded(Survey? survey) {
    if (survey != null && mounted) {
      setState(() {
        _survey = survey;
      });
    }
  }

  void _setSurvey(Survey survey) {
    _survey = widget.survey;
    _surveyController.getSurvey = () => _survey;
    _mainSurveyData = widget.surveyDataKey != null ? _survey!.data[widget.surveyDataKey] : Surveys().getFirstQuestion(_survey!);

    Surveys().evaluateDefaultDataResponse(_survey!, _mainSurveyData, defaultResponses: widget.defaultResponses);
    Surveys().evaluate(_survey!);
  }

  void _checkScroll(Duration duration) {
    if (_scrollEnd) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _scrollEnd = false;
    }
  }

  void _onChangeSurveyResponse(bool scrollEnd) {
    setState(() { });
  }

  bool isScrolledToEnd() {
    double maxScroll = _scrollController.position.maxScrollExtent;
    double currentScroll = _scrollController.position.pixels;
    double delta = 20.0;
    if (maxScroll - currentScroll <= delta) {
      return true;
    }
    return false;
  }

  Color? get defaultBackgroundColor => Styles().colors.surface;
  SurveyWidgetTextStyles get defaultTextStyles => SurveyWidgetTextStyles.withDefaults(
    horizontalMultipleChoiceOption: Styles().textStyles.getTextStyle('widget.item.small.thin'),
    radioButtonNumLabel: Styles().textStyles.getTextStyle('widget.item.small.thin'),
  );
}