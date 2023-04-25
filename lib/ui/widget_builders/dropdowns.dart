import 'package:flutter/material.dart';
import 'package:rokwire_plugin/gen/styles.dart';

class DropdownBuilder {
  static List<DropdownMenuItem<T>> getItems<T>(List<T> options, {String? nullOption, TextStyle? style}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? AppTextStyles.widgetDetailRegular)));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: style ?? AppTextStyles.widgetDetailRegular)));
    }
    return dropDownItems;
  }
}