// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rokwire_plugin/service/styles.dart';

class FormFieldText extends StatefulWidget {
  final String label;
  final EdgeInsets padding;
  final bool readOnly;
  final bool multipleLines;
  
  final String? initialValue;
  final String? hint;
  final TextInputType? inputType;
  final TextEditingController? controller;
  final Function(String)? onFieldSubmitted;
  final Function(String?)? onSaved;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;


  const FormFieldText(this.label, {Key? key, this.padding = const EdgeInsets.only(bottom: 20), this.readOnly = false, this.multipleLines = false, 
    this.initialValue, this.hint, this.inputType, this.controller, this.onFieldSubmitted, this.onSaved, this.onChanged, this.validator, 
    this.textCapitalization = TextCapitalization.none, this.inputFormatters}) : super(key: key);

  @override
  _FormFieldTextState createState() => _FormFieldTextState();
}

class _FormFieldTextState extends State<FormFieldText> {
  @override
  Widget build(BuildContext context) {  
    return Padding(
      padding: widget.padding,
      child: Semantics(
        label: widget.label,
        child: TextFormField(
          readOnly: widget.readOnly,
          style: Styles().textStyles?.getTextStyle('body'),
          maxLines: widget.multipleLines ? null : 1,
          minLines: widget.multipleLines ? 2 : null,
          keyboardType: widget.inputType,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          initialValue: widget.controller == null ? widget.initialValue : null,
          autofocus: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(24.0),
              labelText: widget.label,
              hintText: widget.hint,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.white)
              ),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(width: 2, color: Styles().colors?.fillColorPrimary ?? Colors.white)
              )
          ),
          controller: widget.controller,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          onSaved: widget.onSaved,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
