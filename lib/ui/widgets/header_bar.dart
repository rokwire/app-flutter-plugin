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
import 'package:flutter/semantics.dart';

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final SemanticsSortKey? sortKey;
  
  final Widget? leadingWidget;
  final String? leadingLabel;
  final String? leadingHint;
  final String? leadingAsset;
  final void Function(BuildContext context)? onLeading;
    
  final Widget? titleWidget;
  final String? title;
  final TextStyle? textStyle;
  final Color? textColor;
  final String? fontFamily;
  final double? fontSize;
  final double? letterSpacing;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool? centerTitle;

  final List<Widget>? actions;

  const HeaderBar({Key? key,
    this.sortKey,

    this.leadingWidget,
    this.leadingLabel,
    this.leadingHint,
    this.leadingAsset,
    this.onLeading,
    
    this.titleWidget,
    this.title,
    this.textStyle,
    this.textColor,
    this.fontFamily,
    this.fontSize,
    this.letterSpacing,
    this.maxLines,
    this.textAlign,
    this.centerTitle,

    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (sortKey != null)
      ? Semantics(sortKey:sortKey, child: buildAppBar(context))
      : buildAppBar(context);
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading : leadingWidget ?? buildLeadingWidget(context),
      title: titleWidget ?? buildTitleWidget(context),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  // Leading
  @protected
  Widget? buildLeadingWidget(BuildContext context) {
    Image? image = leadingImage;
    return (image != null) ? Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: image, onPressed: () => (onLeading ?? leadingHandler)(context))
    ) : null;
  }

  
  @protected
  Image? get leadingImage => (leadingAsset != null) ? Image.asset(leadingAsset!, excludeFromSemantics: true) : null;

  @protected
  void leadingHandler(BuildContext context) {}

  // Title
  @protected
  Widget? buildTitleWidget(BuildContext context) => Text(title ?? '', style: textStyle ?? titleTextStyle, textAlign: textAlign, maxLines: maxLines);

  @protected
  TextStyle? get titleTextStyle => TextStyle(color: textColor, fontFamily: fontFamily, fontSize: fontSize, letterSpacing: letterSpacing,);

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

