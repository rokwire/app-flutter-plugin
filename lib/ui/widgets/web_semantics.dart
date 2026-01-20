/*
 * Copyright 2026 Board of Trustees of the University of Illinois.
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

/**
 * Used in web for accessible buttons because InkWell and GestureDetector break the accessibility focus and pronunciation in web.
 */
class WebBareSemanticsButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const WebBareSemanticsButton({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap ?? () => {},
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: WidgetStatePropertyAll(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide.none,
        )),
      ),
      child: child,
    );
  }
}

/**
 * Used to explicitly focus widgets for web accessibility
 */
class WebFocusableSemanticsWidget extends StatefulWidget {
  final Widget child;
  final Function? onSelect;
  final FocusNode? focusNode;

  WebFocusableSemanticsWidget({required this.child, this.onSelect, this.focusNode});

  @override
  State<WebFocusableSemanticsWidget> createState() => _WebFocusableSemanticsWidgetState();
}

class _WebFocusableSemanticsWidgetState extends State<WebFocusableSemanticsWidget> {

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(canRequestFocus: true);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
        focusNode: _focusNode,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
            if (widget.onSelect != null) {
              widget.onSelect?.call();
            }

            // Bring back the focus
            _focusNode.requestFocus();
            return null;
          }),
        },
        child: widget.child);
  }
}