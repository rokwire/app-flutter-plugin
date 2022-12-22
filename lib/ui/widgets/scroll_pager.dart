import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/widget_builders/scroll_pager.dart';

class ScrollPager extends StatelessWidget {
  final Widget? child;
  final Axis scrollDirection;
  final bool? reverse;
  final EdgeInsets? padding;
  final bool? primary;
  final ScrollPhysics? physics;
  late final ScrollController controller;
  late final ScrollPagerController pagerController;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  ScrollPager({Key? key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    ScrollController? controller,
    required this.pagerController,
    this.child,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : super(key: key) {
    this.controller = controller ?? ScrollController();
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
  void Function()? onStateChanged;

  bool _isLoading = false;
  bool _end = false;
  bool _error = false;

  bool get loading => _isLoading;
  bool get end => _end;
  bool get error => _error;

  ScrollController? _scrollController;

  ScrollPagerController({required this.limit, required this.onPage, this.onStateChanged});

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
      onStateChanged?.call();
      onPage(offset: _offset, limit: limit).then((value) {
        if (value >= 0) {
          _error = false;
          _offset += value;
          if (value < limit) {
            _end = true;
          }
        } else {
          _error = true;
        }
        _isLoading = false;
        onStateChanged?.call();
      });
    }
  }

  void deregisterScrollController() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController = null;
  }
}