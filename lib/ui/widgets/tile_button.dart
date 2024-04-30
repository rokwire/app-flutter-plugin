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
import 'package:rokwire_plugin/service/styles.dart';

class TileButton extends StatelessWidget {
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;

  final String? iconAsset;

  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;

  final String? hint;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double contentSpacing;
  final GestureTapCallback? onTap;

  const TileButton({
    Key? key,

    this.title, 
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,

    this.iconAsset, 

    this.border,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderShadow,

    this.hint,
    this.margin = const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.contentSpacing = 26,
    this.onTap, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    if (iconAsset != null) {
      Widget? icon = Styles().images.getImage(iconAsset!);
      if (icon != null) {
        contentList.add(icon);
      }
    }
    if ((title != null) && (iconAsset != null)) {
      contentList.add(Container(height: contentSpacing));
    } 
    if (title != null) {
      contentList.add(Text(title!, textAlign: TextAlign.center, style: displayTitleTextStyle));
    } 

    return GestureDetector(onTap: onTap, child:
      Semantics(label: title, hint: hint, button: true, excludeSemantics: true, child:
        Padding(padding: margin, child:
          Container(decoration: displayDecoration, child:
            Padding(padding: padding, child:
              Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: contentList,),
            ),
          ),
        ),
      ),
    );
  }

  @protected Color? get defaultTitleTextColor => Styles().colors.fillColorPrimary;
  @protected Color? get displayTitleTextColor => titleTextColor ?? defaultTitleTextColor;

  @protected String? get defaultTitleFontFamilly => Styles().fontFamilies.bold;
  @protected String? get displayTitleFontFamilly => titleFontFamilly ?? defaultTitleFontFamilly;

  @protected TextStyle get defaultTitleTextStyle => TextStyle(color: displayTitleTextColor, fontFamily: displayTitleFontFamilly, fontSize: titleFontSize);
  @protected TextStyle get displayTitleTextStyle => titleTextStyle ?? defaultTitleTextStyle;

  @protected Color get defaultBorderColor => Styles().colors.surface;
  @protected Color get displayBorderColor => borderColor ?? defaultBorderColor;
  
  @protected BorderRadiusGeometry get defaultBorderRadius => BorderRadius.circular(4);
  @protected BorderRadiusGeometry get displayBorderRadius => borderRadius ?? defaultBorderRadius;
  
  @protected Border get defaultBorder => Border.all(color: displayBorderColor, width: borderWidth);
  @protected Border get displayBorder => border ?? defaultBorder;
  
  @protected List<BoxShadow> get defaultBorderShadow => [const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))];
  @protected List<BoxShadow> get displayBorderShadow => borderShadow ?? defaultBorderShadow;
  
  @protected Decoration get defaultDecoration => BoxDecoration(color: displayBorderColor, borderRadius: displayBorderRadius, border: displayBorder, boxShadow: displayBorderShadow);
  @protected Decoration get displayDecoration => defaultDecoration;
}

class TileWideButton extends StatelessWidget {
  final String? title;
  final Color? titleTextColor;
  final String? titleFontFamilly;
  final double titleFontSize;
  final TextStyle? titleTextStyle;
  
  final String? iconAsset;

  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;

  final String? hint;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback? onTap;

  const TileWideButton({
    Key? key,

    this.title, 
    this.titleTextColor,
    this.titleFontFamilly,
    this.titleFontSize = 20,
    this.titleTextStyle,

    this.iconAsset,
    
    this.border,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderShadow,

    this.hint,
    this.margin = const EdgeInsets.all(4),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.onTap
  }) : super(key: key);

  @protected Color? get defaultTitleTextColor => Styles().colors.fillColorPrimary;
  @protected Color? get displayTitleTextColor => titleTextColor ?? defaultTitleTextColor;

  @protected String? get defaultTitleFontFamilly => Styles().fontFamilies.bold;
  @protected String? get displayTitleFontFamilly => titleFontFamilly ?? defaultTitleFontFamilly;

  @protected TextStyle get defaultTitleTextStyle => TextStyle(color: displayTitleTextColor, fontFamily: displayTitleFontFamilly, fontSize: titleFontSize);
  @protected TextStyle get displayTitleTextStyle => titleTextStyle ?? defaultTitleTextStyle;

  @protected Color get defaultBorderColor => Styles().colors.surface;
  @protected Color get displayBorderColor => borderColor ?? defaultBorderColor;

  @protected BorderRadiusGeometry get defaultBorderRadius => BorderRadius.circular(4);
  @protected BorderRadiusGeometry get displayBorderRadius => borderRadius ?? defaultBorderRadius;

  @protected Border get defaultBorder => Border.all(color: displayBorderColor, width: borderWidth);
  @protected Border get displayBorder => border ?? defaultBorder;

  @protected List<BoxShadow> get defaultBorderShadow => [const BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))];
  @protected List<BoxShadow> get displayBorderShadow => borderShadow ?? defaultBorderShadow;

  @protected Decoration get defaultDecoration => BoxDecoration(color: displayBorderColor, borderRadius: displayBorderRadius, border: displayBorder, boxShadow: displayBorderShadow);
  @protected Decoration get displayDecoration => defaultDecoration;

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    if (title != null) {
      contentList.add(Expanded(child: Text(title!, textAlign: TextAlign.center, style: displayTitleTextStyle)));
    } 
    if (iconAsset != null) {
      Widget? icon = Styles().images.getImage(iconAsset!);
      if (icon != null) {
        contentList.add(Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [icon])));
      }
    }

    return GestureDetector(onTap: onTap, child:
      Semantics(label: title, hint:hint, button: true, child:
        Padding(padding: margin, child:
          Container(decoration: displayDecoration, child:
            Padding(padding: padding, child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, mainAxisSize: MainAxisSize.max, children: contentList,),
            ),
          ),
        ),
      ),
    );
  }
}

class TileToggleButton extends StatelessWidget {
  final String? title;
  final String? titleFontFamily;
  final double titleFontSize;
  final Color? titleColor;
  final Color? selectedTitleColor;
  final TextStyle? titleStyle;
  final TextStyle? selectedTitleStyle;

  final Widget? icon;
  final Widget? selectedIcon;
  final String? iconKey;
  final String? selectedIconKey;
  final double? iconWidth;
  final BoxFit? iconFit;
  
  final Color backgroundColor;
  final Color? selectedBackgroundColor;
  final Color borderColor;
  final Color? selectedBorderColor;
  final BorderRadiusGeometry? borderRadius;
  final double borderWidth;
  final List<BoxShadow>? borderShadow;

  final String? selectionMarkerKey;
  final Widget? selectionMarker;

  final String? hint;
  final String? semanticsValue;
  final String? selectedSemanticsValue;
  final bool selected;
  final dynamic data;
  final double? sortOrder;
  final double contentSpacing;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final void Function(BuildContext, TileToggleButton)? onTap;

  const TileToggleButton({Key? key,
    this.title,
    this.titleFontFamily,
    this.titleFontSize = 17,
    this.titleColor,
    this.selectedTitleColor,
    this.titleStyle,
    this.selectedTitleStyle,
    
    this.icon,
    this.selectedIcon,
    this.iconKey,
    this.selectedIconKey,
    this.iconWidth,
    this.iconFit,
    
    this.backgroundColor = Colors.white,
    this.selectedBackgroundColor = Colors.white,
    this.borderColor = Colors.white,
    this.selectedBorderColor,
    this.borderRadius,
    this.borderWidth = 2.0,
    this.borderShadow,

    this.selectionMarkerKey,
    this.selectionMarker,

    this.hint,
    this.semanticsValue,
    this.selectedSemanticsValue,
    this.selected = false,
    this.sortOrder,
    this.data,
    this.contentSpacing = 18,
    this.margin = const EdgeInsets.only(top: 8, right: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.onTap,
  }) : super(key: key);

  @protected SemanticsSortKey? get sortKey => (sortOrder != null) ? OrdinalSortKey(sortOrder!) : null;
  @protected String? get displaySemanticsValue => selected ? selectedSemanticsValue : semanticsValue;
  
  @protected Color? get displayBackgroundColor => selected ? selectedBackgroundColor : backgroundColor;
  
  @protected Color get defaultSelectedBorderColor => Styles().colors.fillColorPrimary;
  @protected Color get displaySelectedBorderColor => selectedBorderColor ?? defaultSelectedBorderColor;
  @protected Color get displayBorderColor => selected ? displaySelectedBorderColor : borderColor;

  @protected BorderRadiusGeometry get defaultBorderRadius => BorderRadius.circular(6);
  @protected BorderRadiusGeometry get displayBorderRadius => borderRadius ?? defaultBorderRadius;
  
  @protected BoxBorder get defaultBorder => Border.all(color: displayBorderColor, width: borderWidth);
  @protected BoxBorder get dislayBorder => defaultBorder;

  @protected List<BoxShadow> get defaultBorderShadow => [BoxShadow(color: Styles().colors.blackTransparent018, offset: const Offset(2, 2), blurRadius: 6)];
  @protected List<BoxShadow> get displayBorderShadow => borderShadow ?? defaultBorderShadow;

  @protected Decoration get defaultDecoration => BoxDecoration(color: displayBackgroundColor, borderRadius: displayBorderRadius, border: dislayBorder, boxShadow: displayBorderShadow);
  @protected Decoration get displayDecoration => defaultDecoration;

  @protected Color? get defaultTitleColor => Styles().colors.fillColorPrimary;
  @protected Color? get displayTitleColor => (selected ? selectedTitleColor : titleColor) ?? defaultTitleColor;

  @protected String? get defaultTitleFontFamily => Styles().fontFamilies.bold;
  @protected String? get displayTitleFontFamily => titleFontFamily ?? defaultTitleFontFamily;
  
  @protected TextStyle get defaultTitleStyle => TextStyle(fontFamily: displayTitleFontFamily, fontSize: titleFontSize, color: displayTitleColor);
  @protected TextStyle get displayTitleStyle => (selected ? selectedTitleStyle : titleStyle) ?? defaultTitleStyle;
  
  @protected Widget get defaultTitleWidget => Text(title ?? '', textAlign: TextAlign.center, style: displayTitleStyle);
  @protected Widget get displayTitleWidget => defaultTitleWidget;

  @protected String? get displayIconAsset => selected ? selectedIconKey : iconKey;
  @protected Widget get defaultIconWidget => (displayIconAsset != null) ?  Styles().images.getImage(displayIconAsset!, width: iconWidth, fit: iconFit, excludeFromSemantics: true) ?? Container() : Container();
  @protected Widget get displayIconWidget => (selected ? selectedIcon : icon) ?? defaultIconWidget;

  @protected Widget get defaultSelectionMarkerWidget => Styles().images.getImage(selectionMarkerKey, excludeFromSemantics: true) ?? Container();
  @protected Widget get displaySelectionMarkerWidget => selectionMarker ?? defaultSelectionMarkerWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => _onTap(context), child:
      Semantics(label: title, excludeSemantics: true, sortKey: sortKey, value: displaySemanticsValue, child:
        Stack(children: <Widget>[
          Padding(padding: margin, child:
            Container(decoration: displayDecoration, child:
              Padding(padding: padding, child:
                Column(children: <Widget>[
                  displayIconWidget,
                  Container(height: contentSpacing,),
                  displayTitleWidget,
                ],),
              ),
            ),
          ),
          Visibility(visible: selected, child:
            Align(alignment: Alignment.topRight, child:
              displaySelectionMarkerWidget,
            ),
          ),
      ],
    )));
  }

  void _onTap(BuildContext context) {
    if (onTap != null) {
      onTap!(context, this);
    }
  }
}
