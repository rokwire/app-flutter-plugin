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

import 'package:flutter/widgets.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

typedef AppLifecycleCallback = void Function(AppLifecycleState state);

class AppLifecycleWidgetsBindingObserver extends WidgetsBindingObserver {
  final AppLifecycleCallback? onAppLifecycleChange;
  AppLifecycleWidgetsBindingObserver({this.onAppLifecycleChange});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (onAppLifecycleChange != null) {
      onAppLifecycleChange!(state);
    }
  }
}

class AppLifecycle with Service {

  static const String notifyStateChanged  = "edu.illinois.rokwire.applifecycle.state.changed";

  WidgetsBindingObserver? _bindingObserver;
  AppLifecycleState _state = AppLifecycleState.resumed; // initial value
  AppLifecycleState get state => _state;

  // Singletone Factory

  static AppLifecycle? _instance;

  static AppLifecycle? get instance => _instance;

  @protected
  static set instance(AppLifecycle? value) => _instance = value;

  factory AppLifecycle() => _instance ?? (_instance = AppLifecycle.internal());

  @protected
  AppLifecycle.internal();
  
  // Service

  @override
  void createService() {
    initBinding();
  }

  @override
  void destroyService() {
    _closeBinding();
  }

  @override
  void initServiceUI() {
    initBinding();
  }

  @protected
  void initBinding() {
    if (_bindingObserver == null) {
      _bindingObserver = AppLifecycleWidgetsBindingObserver(onAppLifecycleChange: _onAppLifecycleChangeState);
      WidgetsBinding.instance.addObserver(_bindingObserver!);
    }
  }

  void _closeBinding() {
    if (_bindingObserver != null) {
      WidgetsBinding.instance.removeObserver(_bindingObserver!);
      _bindingObserver = null;
    }
  }

  void _onAppLifecycleChangeState(AppLifecycleState state) {
    _state = state;
    NotificationService().notify(notifyStateChanged, state);
  }
}