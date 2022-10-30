import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class LoadingBuilder {
  static Widget loading() {
    return Semantics(
        label: Localization().getStringEx('widget.loading.title', 'Loading'),
        hint: Localization().getStringEx('widget.loading.hint', 'Please wait'),
        excludeSemantics: true,
        child:Container(
          child: Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),
        ));
  }
}