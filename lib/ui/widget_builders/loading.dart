import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';

class LoadingBuilder {
  static Widget loading() {
    return Semantics(
        label: Localization().getStringEx('widget.loading.title', 'Loading'),
        hint: Localization().getStringEx('widget.loading.hint', 'Please wait'),
        excludeSemantics: true,
        child: const Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(),
          ),
        );
  }
}