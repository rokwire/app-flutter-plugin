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
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class FilterListItemWidget extends StatelessWidget {
  final String? title;
  final TextStyle? titleTextStyle;
  final TextStyle? selectedTitleTextStyle;

  final String? description;
  final TextStyle? descriptionTextStyle;
  final TextStyle? selectedDescriptionTextStyle;

  final bool selected;
  final EdgeInsetsGeometry padding;
  final GestureTapCallback? onTap;
  
  final Widget? icon;
  final String? iconAsset;
  final EdgeInsetsGeometry iconPadding;

  final Widget? selectedIcon;
  final String? selectedIconAsset;
  final EdgeInsetsGeometry selectedIconPadding;

  const FilterListItemWidget({ Key? key,
    this.title,
    this.titleTextStyle,
    this.selectedTitleTextStyle,
    
    this.description,
    this.descriptionTextStyle,
    this.selectedDescriptionTextStyle,
    
    this.selected = false,
    this.padding = const EdgeInsets.all(16),
    this.onTap,

    this.icon,
    this.iconAsset,
    this.iconPadding = const EdgeInsets.only(left: 10),

    this.selectedIcon,
    this.selectedIconAsset,
    this.selectedIconPadding = const EdgeInsets.only(left: 10),
  }) : super(key: key);

  @protected TextStyle? get defaultTitleTextStyle         => TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.fillColorPrimary);
  @protected TextStyle? get defaultSelectedTitleTextStyle => TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary);
  TextStyle? get _titleTextStyle => selected ? (selectedTitleTextStyle ?? defaultSelectedTitleTextStyle) : (titleTextStyle ?? selectedTitleTextStyle);
  
  @protected TextStyle? get defaultDescriptionTextStyle         => defaultTitleTextStyle;
  @protected TextStyle? get defaultSelectedDescriptionTextStyle => defaultSelectedTitleTextStyle;
  TextStyle? get _descriptionTextStyle => selected ? (selectedDescriptionTextStyle ?? defaultSelectedDescriptionTextStyle) : (descriptionTextStyle ?? defaultDescriptionTextStyle);

  Widget? get _iconImage => (iconAsset != null) ? Image.asset(iconAsset!, excludeFromSemantics: true) : null;
  Widget? get _iconWidget => icon ?? _iconImage;

  Widget? get _selectedIconImage => (selectedIconAsset != null) ? Image.asset(selectedIconAsset!, excludeFromSemantics: true) : null;
  Widget? get _selectedIconWidget => selectedIcon ?? _selectedIconImage;

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[
      Expanded(child:
        Text(title ?? '', style: _titleTextStyle, ),
      ),
    ];

    if (StringUtils.isNotEmpty(description)) {
      contentList.add(Text(description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: _descriptionTextStyle, ));
    }

    Widget? iconWidget = selected ? _selectedIconWidget : _iconWidget;
    EdgeInsetsGeometry iconWidgetPadding = selected ? selectedIconPadding : iconPadding;
    if (iconWidget != null) {
      contentList.add(Padding(padding: iconWidgetPadding, child: iconWidget));
    }

    return Semantics(label: title, button: true, selected: selected, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
        Container(color: (selected ? Styles().colors?.background : Colors.white), child:
          Padding(padding: padding, child:
            Row(mainAxisSize: MainAxisSize.max, children: contentList),
          ),
        ),
      ),
    );
  }
}

class FilterSelectorWidget extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? labelFontFamily;
  final double labelFontSize;
  final bool active;
  final EdgeInsets padding;
  final bool visible;
  final GestureTapCallback? onTap;

  const FilterSelectorWidget(
      {Key? key, required this.label,
        this.hint,
        this.labelFontFamily,
        this.labelFontSize = 16,
        this.active = false,
        this.padding = const EdgeInsets.only(left: 4, right: 4, top: 12),
        this.visible = false,
        this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: visible,
        child: Semantics(
            label: label,
            hint: hint,
            excludeSemantics: true,
            button: true,
            child: InkWell(
                onTap: onTap,
                  child: Padding(
                    padding: padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          label!,
                          style: TextStyle(
                              fontSize: labelFontSize, color: (active ? Styles().colors!.fillColorSecondary : Styles().colors!.fillColorPrimary), fontFamily: labelFontFamily ?? Styles().fontFamilies!.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Image.asset(active ? 'images/icon-up.png' : 'images/icon-down.png', excludeFromSemantics: true),
                        )
                      ],
                    ),
                  ),
                )));
  }
}