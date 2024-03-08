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

abstract mixin class Service {

  bool? _isInitialized;

  void createService() {
  }

  void destroyService() {
  }

  Future<void> initService() async {
    _isInitialized = true;
  }

  Future<void> initServiceFallback() async {
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

  bool _initialized = false;
  bool get initialized => _initialized;

  ServiceError? _initializeError;
  ServiceError? get initializeError => _initializeError;

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
    }
  }

  Future<ServiceError?> init() async {
    if (_services != null) {
      ServiceError? se = await _ServicesInitializer(initService, initServiceFallback).process(_services!);
      return se;
    }
    return null;
  }

  @protected
  Future<ServiceError?> initFallback() async {
    ServiceError? error;
    for (Service service in _services!) {
      if (service.isInitialized != true) {
        error ??= await initServiceFallback(service);
        if (error != null) {
          return error;
        }
      }
    }
    return null;
  }

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


  @protected
  Future<ServiceError?> initServiceFallback(Service service) async {
    try {
      await service.initServiceFallback();
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
  Future<ServiceError?> Function(Service service) initServiceFallback;
  Completer<ServiceError?>? _completer;

  _ServicesInitializer(this.initService, this.initServiceFallback);

  Future<ServiceError?> process(List<Service> services) async {

    for (Service service in services) {
      (service.isInitialized ? _done : _toDo).add(service);
    }

    if (_toDo.isNotEmpty) {
      _completer = Completer<ServiceError?>();
      _run();
      return _completer!.future;
    }
    else {
      return null;
    }
  }

  void _run() {
    if (_toDo.isNotEmpty) {
      for (Service service in _toDo) {
        try {
          if (_canStartService(service) && !_inProgress.contains(service)) {
            _inProgress.add(service);
            initService(service).then((ServiceError? error) async {
              _inProgress.remove(service);
              await _finishInitService(service, error);
            });
          }
        }
        on ServiceError catch (error) {
          _completer?.complete(error);
          return;
        }
      }

      if (_inProgress.isEmpty) {
        _completer?.complete(ServiceError(
          source: null,
          severity: ServiceErrorSeverity.fatal,
          title: 'Services Initialization Error',
          description: 'Service dependency cycle detected: ${_findServiceCycle().join(', ')}.',
        ));
        _completer = null;
      }
    }
    else {
      _completer?.complete(null);
      _completer = null;
    }
  }

  Future<void> _finishInitService(Service service, ServiceError? error, {bool tryFallback = true}) async {
    if (_completer != null && !_completer!.isCompleted) {
      if (error?.severity == ServiceErrorSeverity.fatal) {
        if (tryFallback) {
          _inProgress.add(service);
          error = await initServiceFallback(service);
          _inProgress.remove(service);

          _finishInitService(service, error, tryFallback: false);
        }

        _completer?.complete(error);
        _completer = null;
      }
      else {
        _done.add(service);
        _toDo.remove(service);
        _run();
      }
    }
  }

  bool _canStartService(Service service) {
    Set<Service>? serviceDependsOn = service.serviceDependsOn;
    if ((serviceDependsOn == null) || serviceDependsOn.isEmpty) {
      return true;
    }

    for (Service dependency in serviceDependsOn) {
      if (!_done.contains(dependency)) {
        if (!_toDo.contains(dependency) && !_inProgress.contains(dependency)) {
          // return with an error if a service depends on another service that is missing from the main initialization list (missing from _toDo, _inProgress, and _done)
          throw ServiceError(
            source: service,
            severity: ServiceErrorSeverity.fatal,
            title: 'Services Initialization Error',
            description: 'Service dependency missing from initialization list: ${dependency.debugDisplayName}.',
          );
        }
        return false;
      }
    }
    return true;
  }

  List<Service> _findServiceCycle() {
    Map<Service, Service> _firstUninitializedDependencies = {};
    // find first uninitialized dependency for each uninitialized service
    for (Service toDo in _toDo) {
      try {
        Service? dependency = toDo.serviceDependsOn?.firstWhere((dependency) => _toDo.contains(dependency) && !_done.contains(dependency));
        if (dependency != null) {
          _firstUninitializedDependencies[toDo] = dependency;
        }
      }
      catch (error) {
        if (error is! StateError) {
          debugPrint(error.toString());
        }
      }
    }

    // traverse the uninitialized service graph to determine the cycle
    int cycleLength = 0;
    Map<Service, int> serviceVisits = Map.fromIterable(_toDo, value: (service) => 0);
    Service next = _toDo.first;
    while (cycleLength < 2 * _toDo.length) { // maximum possible cycle length is the number of uninitialized services (allow to visit at most twice)
      if (_firstUninitializedDependencies[next] != null) {
        next = _firstUninitializedDependencies[next]!;
        if (serviceVisits[next] == 2) {
          break; // if trying to visit a service that has been visited twice already, then the cycle must be the list of services visited twice
        }
        serviceVisits[next] = serviceVisits[next]! + 1;
      }
      cycleLength++;
    }
    return serviceVisits.keys.where((service) => serviceVisits[service] == 2).toList(); // all services visited twice are part of the cycle
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