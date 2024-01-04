import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/widget_builders/scroll_pager.dart';

class ScrollPager extends StatelessWidget {
  final Widget? child;
  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsets? padding;
  final bool? primary;
  final ScrollPhysics? physics;
  final ScrollPagerController controller;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const ScrollPager({Key? key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    required this.controller,
    this.child,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: controller.reset,
      child: SingleChildScrollView(key: key, scrollDirection: scrollDirection, reverse: reverse, padding: padding,
          primary: primary, physics: physics, controller: controller.scrollController, child: buildChild(), dragStartBehavior: dragStartBehavior,
          clipBehavior: clipBehavior, restorationId: restorationId, keyboardDismissBehavior: keyboardDismissBehavior),
    );
  }

  Widget buildChild() {
    return Column(children: [
      child ?? Container(),
      ScrollPagerBuilder.buildScrollPagerFooter(controller) ?? Container(),
    ]);
  }
}

class ScrollPagerController {
  int limit;
  int _offset = 0;

  Future<int> Function({required int offset, required int limit}) onPage;
  void Function()? onStateChanged;
  void Function()? onReset;

  bool _isLoading = false;
  bool _end = false;
  bool _error = false;

  bool get loading => _isLoading;
  bool get end => _end;
  bool get error => _error;

  ScrollController? _scrollController;

  ScrollController? get scrollController => _scrollController;

  ScrollPagerController({required this.limit, required this.onPage, this.onStateChanged, this.onReset, ScrollController? controller}) {
    controller ??= ScrollController();
    registerScrollController(controller);
  }

  Future<void> reset() async {
    _offset = 0;
    _end = false;
    _error = false;
    onReset?.call();
    await loadPage();
  }

  void registerScrollController(ScrollController controller) {
    if (_scrollController != null && _scrollController != controller) {
      unregisterScrollController();
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

  Future<void> loadPage({bool retry = false}) async {
    if (!_isLoading && !_end && (!_error || retry)) {
      _isLoading = true;
      onStateChanged?.call();
      int value = await onPage(offset: _offset, limit: limit);
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
    }
  }

  void unregisterScrollController() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController = null;
  }
}