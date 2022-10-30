import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widget_builders/loading.dart';
import 'package:rokwire_plugin/ui/widget_builders/scroll_pager.dart';

class ScrollPager extends StatelessWidget {
  Key? key;
  Widget? child;
  Axis scrollDirection;
  bool? reverse;
  EdgeInsets? padding;
  bool? primary;
  ScrollPhysics? physics;
  ScrollController? controller;
  ScrollPagerController pagerController;
  DragStartBehavior dragStartBehavior;
  Clip clipBehavior;
  String? restorationId;
  ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  ScrollPager({
    this.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    required this.pagerController,
    this.child,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) {
    if (controller == null) {
      controller = ScrollController();
    }
    pagerController.registerScrollController(controller!);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(key: key, scrollDirection: scrollDirection, reverse: true, padding: padding,
        primary: primary, physics: physics, controller: controller, child: child, dragStartBehavior: dragStartBehavior,
        clipBehavior: clipBehavior, restorationId: restorationId, keyboardDismissBehavior: keyboardDismissBehavior);
  }

  Widget buildChild() {
    return Column(children: [
      child ?? Container(),
      ScrollPagerBuilder.buildScrollPagerFooter(pagerController) ?? Container(),
    ]);
  }
}

class ScrollPagerController {
  int limit;
  int _offset = 0;

  Future<int> Function({required int offset, required int limit}) onPage;

  bool _isLoading = false;
  bool _end = false;
  bool _error = false;

  bool get loading => _isLoading;
  bool get end => _end;
  bool get error => _error;

  ScrollController? _scrollController;

  ScrollPagerController({required this.limit, required this.onPage});

  void reset() {
    _offset = 0;
    _end = false;
    _error = false;
    loadPage();
  }

  void registerScrollController(ScrollController controller) {
    if (_scrollController != null && _scrollController != controller) {
      deregisterScrollController();
    }
    controller.addListener(_scrollListener);
    _scrollController = controller;
    reset();
  }

  void _scrollListener() {
    if (_scrollController != null && _scrollController!.position.maxScrollExtent == _scrollController!.position.pixels) {
      loadPage();
    }
  }

  void loadPage({bool retry = false}) {
    if (!_isLoading && !_end && (!_error || retry)) {
      _isLoading = true;
      onPage(offset: _offset, limit: limit).then((value) {
        if (value > 0) {
          _error = false;
          _offset += value;
          if (value < limit) {
            _end = true;
          }
        } else {
          _error = true;
        }
        _isLoading = false;
      });
    }
  }

  void deregisterScrollController() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController = null;
  }
}