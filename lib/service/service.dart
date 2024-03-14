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


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/notification_service.dart';

abstract mixin class Service {

  static const String notifyInitialized = "edu.illinois.rokwire.service.initialized";

  bool? _isInitialized;

  void createService() {
  }

  void destroyService() {
  }

  Future<void> initService() async {
    _isInitialized = true;
    NotificationService().notify(notifyInitialized, this);
  }

  void initServiceUI() async {
  }

  bool get isInitialized => _isInitialized ?? false;

  Set<Service>? get serviceDependsOn {
    return null;
  }

  String get debugDisplayName => runtimeType.toString();
}

class Services {
  static Services? _instance;
  
  @protected
  Services.internal();
  
  factory Services() {
    return _instance ?? (_instance = Services.internal());
  }

  static Services? get instance => _instance;
  
  @protected
  static set instance(Services? value) => _instance = value;

  List<Service>? _services;

  Future<ServiceError?>? _initialzeFuture;
  bool? _isInitialized;

  void create(List<Service> services) {
    if (_services == null) {
      _services = services;
      for (Service service in _services!) {
        service.createService();
      }
    }
  }

  void destroy() {
    if (_services != null) {
      for (Service service in _services!) {
        service.destroyService();
      }
      _services = null;
      ;
    }
  }

  Future<ServiceError?> init() async {
    if (_initialzeFuture != null) {
      return await _initialzeFuture;
    }
    else {
      _initialzeFuture = _ServicesInitializer(initService).process(_services);
      ServiceError? error = await _initialzeFuture;
      _isInitialized = (error == null);
      _initialzeFuture = null;
      return error;
    }
  }

  bool get isInitialized => (_isInitialized == true);
  bool get isInitializeFailed => (_isInitialized == false);

  @protected
  Future<ServiceError?> initService(Service service) async {
    try {
      await service.initService();
    }
    on ServiceError catch (error) {
      return error;
    }
    return null;
  }

  void initUI() {
    if (_services != null) {
      for (Service service in _services!) {
        service.initServiceUI();
      }
    }
  }

  void enumServices(void Function(Service service) handler) {
    if (_services != null) {
      for (Service service in _services!) {
        handler(service);
      }
    }
  }
}

class _ServicesInitializer {
  final Set<Service> _toDo = <Service>{};
  final Set<Service> _done = <Service>{};
  final Set<Service> _inProgress = <Service>{};

  Future<ServiceError?> Function(Service service) initService;
  Completer<ServiceError?>? _completer;

  _ServicesInitializer(this.initService);

  Future<ServiceError?> process(List<Service>? services) async {

    _prepareServices(services);

    if (_toDo.isNotEmpty) {
      _completer = Completer<ServiceError?>();
      _run();
      return _completer!.future;
    }
    else {
      return null;
    }
  }

  void _prepareServices(Iterable<Service>? services) {
    if (services != null) {
      for (Service service in services) {
        _prepareService(service);
      }
    }
  }

  void _prepareService(Service service) {
    if (!_done.contains(service) && !_toDo.contains(service)) {
      (service.isInitialized ? _done : _toDo).add(service);
      _prepareServices(service.serviceDependsOn);
    }
  }

  void _run() {
    if (_toDo.isNotEmpty) {
      for (Service service in _toDo) {
        if (_canStartService(service) && !_inProgress.contains(service)) {
          _inProgress.add(service);
          initService(service).then((ServiceError? error) async {
            _inProgress.remove(service);
            if ((_completer != null) && (_completer?.isCompleted != true)) {
              if (error?.severity == ServiceErrorSeverity.fatal) {
                _completer?.complete(error);
                _completer = null;
              }
              else {
                _done.add(service);
                _toDo.remove(service);
                _run();
              }
            }
          });
        }
      }

      if (_inProgress.isEmpty) {
        _completer?.complete(ServiceError(
          source: null,
          severity: ServiceErrorSeverity.fatal,
          title: 'Services Initialization Error',
          description: 'Service dependency cycle detected.',
        ));
        _completer = null;
      }
    }
    else {
      _completer?.complete(null);
      _completer = null;
    }
  }

  bool _canStartService(Service service) {
    Set<Service>? serviceDependsOn = service.serviceDependsOn;
    return (serviceDependsOn == null) || serviceDependsOn.isEmpty || _done.containsAll(serviceDependsOn);
  }
}

class ServiceError implements Exception {
  final String? title;
  final String? description;
  final Service? source;
  final ServiceErrorSeverity? severity;

  ServiceError({this.title, this.description, this.source, this.severity});

  @override
  String toString() {
    return "ServiceError: ${source?.runtimeType.toString()}: $title\n$description";
  }

  @override
  bool operator ==(other) =>
    (other is ServiceError) &&
      (other.title == title) &&
      (other.description == description) &&
      (other.source == source) &&
      (other.severity == severity);

  @override
  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (source?.hashCode ?? 0) ^
    (severity?.hashCode ?? 0);
}

enum ServiceErrorSeverity {
  fatal,
  nonFatal
}