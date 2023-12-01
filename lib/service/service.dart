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


import 'package:flutter/foundation.dart';

abstract class Service {

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
  Map<String?, Set<Service>?>? _serviceDependents;
  Set<String>? _initializedServices;

  void create(List<Service> services) {
    if (_services == null) {
      _services = services;
      for (Service service in services) {
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
      _serviceDependents = null;
      _initializedServices = null;
    }
  }

  Future<ServiceError?> init() async {
    if (_services != null) {
      _initializedServices = {};
      _serviceDependents = _getServiceDependents();
      if (_serviceDependents?[null]?.isEmpty ?? true) {
        return ServiceError(
          source: null,
          severity: ServiceErrorSeverity.fatal,
          title: 'Services Initialization Error',
          description: 'All services have dependencies. No services may be initialized safely.',
        );
      }

      return _init(null);
    }

    return null;

    /*TMP:
    return ServiceError(
      source: null,
      severity: ServiceErrorSeverity.fatal,
      title: 'Text Initialization Error',
      description: 'This is a test initialization error.',
    );*/
  }

  Future<ServiceError?> _init(String? serviceName) async {
    List<Future<ServiceError?>> initErrorFutures = [];
    for (Service service in _serviceDependents![serviceName] ?? {}) {
      bool initialize = true;
      for (Service dependency in service.serviceDependsOn ?? {}) {
        if (_services!.contains(dependency) && !dependency.isInitialized) {
          initialize = false;
          break;
        }
      }

      if (initialize && !service.isInitialized && !_initializedServices!.contains(service.debugDisplayName)) {
        _initializedServices!.add(service.debugDisplayName);
        initErrorFutures.add(initService(service).then((ServiceError? error) async {
          if (error?.severity == ServiceErrorSeverity.fatal) {
            initFallback();
            return error;
          }

          return await _init(service.debugDisplayName);
        }));
      }
    }

    List<ServiceError?> initErrors = await Future.wait(initErrorFutures);
    return initErrors.firstWhere((element) => element != null, orElse: () => null);
  }

  @protected
  Future<void> initFallback() async {
    for (Service service in _services!) {
      if (service.isInitialized != true) {
        await initServiceFallback(service);
      }
    }
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
  Future<void> initServiceFallback(Service service) async {
    try {
      await service.initServiceFallback();
    }
    on ServiceError catch (error) {
      debugPrint(error.toString());
    }
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

  ServiceError? verifyInitialization() {
    Set<String>? serviceNames = _services != null ? Set.of(List.generate(_services!.length, (index) => _services![index].debugDisplayName)) : null;
    Set<String> remaining = serviceNames?.difference(_initializedServices ?? {}) ?? {};
    return remaining.isEmpty ? null : ServiceError(
      source: null,
      severity: ServiceErrorSeverity.fatal,
      title: 'Services Initialization Error',
      description: 'The following services were not initialized: $remaining',
    );
  }

  Map<String?, Set<Service>?> _getServiceDependents() {

    Map<String?, Set<Service>?> serviceDependents = {};
    for (Service service in _services!) {
      if (service.serviceDependsOn?.isEmpty ?? true) {
        serviceDependents[null] ??= {};
        serviceDependents[null]!.add(service);
      } else {
        for (Service dependency in service.serviceDependsOn!) {
          if (_services!.contains(dependency)) {
            serviceDependents[dependency.debugDisplayName] ??= {};
            serviceDependents[dependency.debugDisplayName]!.add(service);
          } 
        }
      }
    }

    return serviceDependents;
    
    // List<Service> queue = [];
    // List<Service> services = List.from(inputServices);
    // while (services.isNotEmpty) {
    //   // start with lowest priority service
    //   Service svc = services.last;
    //   services.removeLast();
      
    //   // Move to TBD anyone from Queue that depends on svc
    //   Set<Service>? svcDependents = svc.serviceDependsOn;
    //   if (svcDependents != null) {
    //     for (int index = queue.length - 1; index >= 0; index--) {
    //       Service queuedSvc = queue[index];
    //       if (svcDependents.contains(queuedSvc)) {
    //         queue.removeAt(index);
    //         services.add(queuedSvc);
    //       }
    //     }
    //   }

    //   // Move svc from TBD to Queue, mark it as processed
    //   queue.add(svc);
    // }
    
    // return queue.reversed.toList();
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