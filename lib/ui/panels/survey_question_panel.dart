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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'package:rokwire_plugin/ui/widgets/survey.dart';

import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SurveyQuestionPanel extends StatefulWidget {
  final Survey survey;
  final int currentSurveyIndex;
  final Function? onComplete;
  final bool showSummaryOnFinish;
  final bool allowBack;
  final int initPanelDepth;

  const SurveyQuestionPanel({required this.survey, this.currentSurveyIndex = 0, this.showSummaryOnFinish = false, this.allowBack = true, this.onComplete, this.initPanelDepth = 0});

  @override
  _SurveyQuestionPanelState createState() => _SurveyQuestionPanelState();
}

class _SurveyQuestionPanelState extends State<SurveyQuestionPanel> {
  late Survey _survey;
  late Map<String, SurveyData> _surveyQuestions;
  late int _surveyQuestionIndex;
  SurveyData? _mainSurveyQuestion;

  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  bool _scrollEnd = false;

  late final SurveyWidgets widgets;

  @override
  void initState() {
    super.initState();

    widgets = SurveyWidgets(context, _onChangeSurveyResponse);

    _survey = widget.survey;
    if (_survey.data.isEmpty || widget.currentSurveyIndex >= _survey.data.length) {
      _popSurveyPanels();
      return;
    }
    _surveyQuestions = _survey.data;

    _surveyQuestionIndex = widget.currentSurveyIndex;
    while (_surveyQuestionIndex < _surveyQuestions.length) {
      _surveyQuestionIndex = _surveyQuestionIndex + 1;
    }
    if (_surveyQuestionIndex >= _surveyQuestions.length) {
      _finishSurvey();
      return;
    }

    _mainSurveyQuestion = _surveyQuestions[_surveyQuestionIndex];
    _mainSurveyQuestion?.evaluateDefaultResponse(_survey);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_checkScroll);
    return WillPopScope(
      onWillPop: () async => widget.allowBack,
      child: Scaffold(
          backgroundColor: Styles().colors?.background,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _buildScrollView()),
                  _buildContinueButton(),
              ]),
            ],
          )),
    );
  }

  Widget _buildScrollView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scrollbar(
        radius: const Radius.circular(2),
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_mainSurveyQuestion == null) return Text(Localization().getStringEx("panel.survey.error.invalid_data.title", "Invalid survey data"));

    Widget? questionWidget;
    SurveyData? survey = _mainSurveyQuestion;

    if (survey is SurveyQuestionMultipleChoice) {
      questionWidget = widgets.buildMultipleChoiceSurveySection(survey);
    } else if (survey is SurveyQuestionTrueFalse) {
      questionWidget = widgets.buildTrueFalseSurveySection(survey);
    } else if (survey is SurveyQuestionDateTime) {
      questionWidget = widgets.buildDateEntrySurveySection(survey);
    } else if (survey is SurveyQuestionNumeric) {
      questionWidget = widgets.buildNumericSurveySection(survey);
    } else if (survey is SurveyDataResponse) {
      questionWidget = widgets.buildResponseSurveySection(survey);
    } else if (survey is SurveyQuestionText) {
      questionWidget = widgets.buildTextSurveySection(survey);
    } else if (survey == null) {
      return Text(Localization().getStringEx("panel.survey.error.invalid_data.title", "Invalid survey data"));
    }

    List<Widget> followUps = [];
    for (SurveyData? data = _mainSurveyQuestion?.followUp(_survey); data != null; data = data.followUp(_survey)) {
      Widget? followUp;
      if (data is SurveyDataSurvey) {
        followUp = widgets.buildInlineSurveyWidget(data, onComplete: (val) {
          setState(() {
            _mainSurveyQuestion?.response = val;
          });
        });
      } else {
        followUp = widgets.buildInlineSurveyWidget(data);
      }
      if (followUp != null) {
        GlobalKey? key;
        if (data.response == null) {
          key = GlobalKey();
          dataKey = key;
        }
        followUps.add(Padding(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Card(
              color: Styles().colors?.background,
              margin: EdgeInsets.zero,
              elevation: 0.0,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: followUp)),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(children: [
        questionWidget ?? Container(),
        Wrap(children: followUps),
      ]),
    );
  }

  Widget _buildContinueButton() {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
      RoundedButton(label: Localization().getStringEx("panel.survey.button.action.continue.title", "Continue"), onTap: _onTapContinue, progress: null),
    ]);
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

  void _onTapContinue() async {
    final targetContext = dataKey?.currentContext;
    if (targetContext != null) {
      double startScroll = _scrollController.position.pixels;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      dataKey = null;
      double scrollDiff = _scrollController.position.pixels - startScroll;
      if (scrollDiff.abs() > 20.0) {
        return;
      }
    }

    if (_mainSurveyQuestion?.canContinue(_survey) == false) {
      AppToast.show("Please answer all required questions to continue");
      return;
    }

    // show survey summary or return to home page on finishing events
    if (_surveyQuestionIndex == _surveyQuestions.length - 1) {
      _survey.lastUpdated = DateTime.now();

      // if (widget.showSummaryOnFinish) {
      // } else {
      _finishSurvey();
      // }

      return;
    }

    Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyQuestionPanel(survey: _survey, currentSurveyIndex: _surveyQuestionIndex + 1, showSummaryOnFinish: widget.showSummaryOnFinish, onComplete: widget.onComplete, initPanelDepth: widget.initPanelDepth + 1,)));
  }

  void _finishSurvey() {
    _popSurveyPanels();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _popSurveyPanels() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int count = 0;
      Navigator.of(context).popUntil((route) => count++ > widget.initPanelDepth);
    });
  }
}