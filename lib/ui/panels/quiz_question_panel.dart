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

class QuizQuestionPanel extends StatefulWidget {
  final Quiz quiz;
  final Event? event;
  final TreatmentPlan? plan;
  final int currentQuizIndex;
  final Function? onComplete;
  final bool showSummaryOnFinish;
  final bool allowBack;
  final int initPanelDepth;

  const QuizQuestionPanel({required this.quiz, this.plan, this.event, this.currentQuizIndex = 0, this.showSummaryOnFinish = false, this.allowBack = true, this.onComplete, this.initPanelDepth = 0});

  @override
  _QuizQuestionPanelState createState() => _QuizQuestionPanelState();
}

class _QuizQuestionPanelState extends State<QuizQuestionPanel> {
  Quiz? _quiz;
  late List<QuizData> _quizQuestions;
  late int _quizQuestionIndex;
  QuizData? _mainQuizQuestion;

  GlobalKey? dataKey;

  final ScrollController _scrollController = ScrollController();
  bool _scrollEnd = false;

  late final QuizWidgets widgets;

  @override
  void initState() {
    super.initState();

    widgets = QuizWidgets(context, _onChangeQuizResponse);

    _quiz = widget.quiz;
    if (_quiz == null || _quiz!.questions.isEmpty || widget.currentQuizIndex >= _quiz!.questions.length) {
      _popQuizPanels();
      return;
    }
    _quizQuestions = _quiz!.questions;

    _quizQuestionIndex = widget.currentQuizIndex;
    while (_quizQuestionIndex < _quizQuestions.length && !_quizQuestions[_quizQuestionIndex].shouldDisplay(widget.plan, widget.event)) {
      _quizQuestionIndex = _quizQuestionIndex + 1;
    }
    if (_quizQuestionIndex >= _quizQuestions.length) {
      _finishQuiz();
      return;
    }

    _mainQuizQuestion = _quizQuestions[_quizQuestionIndex];
    _mainQuizQuestion?.evaluateDefaultResponse(widget.plan, widget.event);
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
    if (_mainQuizQuestion == null) return Text(Localization().getStringEx("panel.quiz.error.invalid_data.title", "Invalid quiz data"));

    Widget? questionWidget;
    QuizData? quiz = _mainQuizQuestion;

    if (quiz is QuizQuestionMultipleChoice) {
      questionWidget = widgets.buildMultipleChoiceQuizSection(quiz);
    } else if (quiz is QuizQuestionTrueFalse) {
      questionWidget = widgets.buildTrueFalseQuizSection(quiz);
    } else if (quiz is QuizQuestionDateTime) {
      questionWidget = widgets.buildDateEntryQuizSection(quiz);
    } else if (quiz is QuizQuestionNumeric) {
      questionWidget = widgets.buildNumericQuizSection(quiz);
    } else if (quiz is QuizDataResponse) {
      questionWidget = widgets.buildResponseQuizSection(quiz);
    } else if (quiz is QuizQuestionText) {
      questionWidget = widgets.buildTextQuizSection(quiz);
    } else if (quiz == null) {
      return Text(Localization().getStringEx("panel.quiz.error.invalid_data.title", "Invalid quiz data"));
    }

    List<Widget> followUps = [];
    for (QuizData? data = _mainQuizQuestion?.followUp; data != null; data = data.followUp) {
      if (data.shouldDisplay(widget.plan, widget.event)) {
        Widget? followUp;
        if (data is QuizDataQuiz) {
          followUp = widgets.buildInlineQuizWidget(data, plan: widget.plan, onComplete: (val) {
            setState(() {
              _mainQuizQuestion?.response = val;
            });
          });
        } else {
          followUp = widgets.buildInlineQuizWidget(data);
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
      RoundedButton(label: Localization().getStringEx("panel.quiz.button.action.continue.title", "Continue"), onTap: _onTapContinue, progress: null),
    ]);
  }

  void _checkScroll(Duration duration) {
    if (_scrollEnd) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _scrollEnd = false;
    }
  }

  void _onChangeQuizResponse(bool scrollEnd) {
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

    if (_mainQuizQuestion?.canContinue(widget.plan, widget.event) == false) {
      AppToast.show("Please answer all required questions to continue");
      return;
    }

    // show quiz summary or return to home page on finishing events
    if (_quizQuestionIndex == _quizQuestions.length - 1) {
      _quiz?.lastUpdated = DateTime.now();

      // if (widget.showSummaryOnFinish) {
      // } else {
      _finishQuiz();
      // }

      return;
    }

    Navigator.push(context, CupertinoPageRoute(builder: (context) => QuizQuestionPanel(quiz: widget.quiz, plan: widget.plan, currentQuizIndex: _quizQuestionIndex + 1, showSummaryOnFinish: widget.showSummaryOnFinish, onComplete: widget.onComplete, initPanelDepth: widget.initPanelDepth + 1,)));
  }

  void _finishQuiz() {
    _popQuizPanels();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _popQuizPanels() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int count = 0;
      Navigator.of(context).popUntil((route) => count++ > widget.initPanelDepth);
    });
  }
}