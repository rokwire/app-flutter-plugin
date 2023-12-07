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
import 'package:rokwire_plugin/utils/utils.dart';

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
    try {
      return (_services != null) ? await _executeInitList(_buildInitList(_services!)) : null;
    }
    on ServiceError catch (error) {
      return error;
    }

    /*TMP:
    return ServiceError(
      source: null,
      severity: ServiceErrorSeverity.fatal,
      title: 'Text Initialization Error',
      description: 'This is a test initialization error.',
    );*/
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

  @protected
  List<Iterable<Service>> _buildInitList(List<Service> servicesList) {
    List<Iterable<Service>> initList = <Iterable<Service>>[]; // Ordered list of service pools as they should be initialized.
    Set<Service> registered = Set.from(servicesList); // Pool of all registered services. Some services refer other services that are not registered so we need to ignore them.
    Set<Service> processing = Set.from(registered); // Pool of services that are not scheduled for initialization yet.
    Set<Service> processed = <Service>{}; // Pool of services that are scheduled for initialization.

    while (processing.isNotEmpty) {
      Set<Service> currentListEntry = <Service>{};
      for (Service service in processing) {
        if (_canProcessService(service, processed: processed, registered: registered)) /* (processed.containsAll(service.serviceDependsOn ?? {})) */ {
          currentListEntry.add(service); // All service ancessors are already scheduled for initialization => we can initialize this service on the current step.
        }
      }

      if (currentListEntry.isNotEmpty) {
        initList.add(currentListEntry); // Register current initialization step.
        processed.addAll(currentListEntry); // Mark current initialization step services as scheduled for initialization.
        processing.removeAll(currentListEntry); // Remove current initialization step services from the not scheduled yet pool.
      }
      else {
        // There are services not scheduled for initialozation but we cannot retrieve any that depends only on the scheduled pool.
        // This is an indication that processing contains a services that have dependancy cycle.
        throw ServiceError(
          source: null,
          severity: ServiceErrorSeverity.fatal,
          title: 'Services Initialization Error',
          description: 'Service dependency cycle: ${_servicePoolToString(processing)}',
        );
      }
    }

    return initList;
  }

  @protected
  bool _canProcessService(Service service, { required Set<Service> processed, required Set<Service> registered}) {
    Set<Service>? serviceAncessors = service.serviceDependsOn;
    if ((serviceAncessors != null) && serviceAncessors.isNotEmpty) {
      for (Service serviceAncessor in serviceAncessors) {
        if (registered.contains(serviceAncessor) && !processed.contains(serviceAncessor)) {
          return false;
        }
      }
    }
    return true;
  }

  @protected
  Future<ServiceError?> _executeInitList(List<Iterable<Service>> initList) async {
    int initStep = 0;
    ServiceError? result = null;
    Set<Service> skipped = <Service>{};
    for (Iterable<Service> currentListEntry in initList) {
      ServiceError? currentListError = await initServices(currentListEntry, skipped: skipped);
      debugPrint("Services.init[${initStep++}] => ${_servicePoolToString(currentListEntry, marked: skipped)};");
      result ??= currentListError;
    }
    return result;
  }

  @protected
  Future<ServiceError?> initServices(Iterable<Service> services, { Set<Service>? skipped }) async {
    if (services.isNotEmpty) {

      Set<Service> skippedServices = <Service>{};
      List<Future<dynamic>> initFutures = <Future<dynamic>>[];
      for (Service service in services) {
        if (skipped?.containsAny(service.serviceDependsOn ?? {}) == true) {
          // Service ancessor is skipped, invoke initServiceFallback and do not try to initialize it.
          initFutures.add(initServiceFallback(service));
          skippedServices.add(service);
        }
        else {
          // Service should be initialized.
          initFutures.add(initService(service));
        }
      }

      try {
        ServiceError? initError;
        List<dynamic> initResults = await Future.wait(initFutures);
        for (int index = 0; index < initResults.length; index++) {
          dynamic initResult = initResults[index];
          if ((initResult is ServiceError) && (initResult.severity == ServiceErrorSeverity.fatal)) {
            skipped?.add(services.elementAt(index)); // service initialization failed => do not attempt to initialize its ancessors
            initError ??= initResult;
          }
        }
        if (skippedServices.isNotEmpty) {
          skipped?.addAll(skippedServices); // service initialization is skipped => do not attempt to initialize its ancessors
        }
        return initError;
      }
      on ServiceError catch (error) {
        return error;
      }
    }
    return null;
  }

  @protected
  String _servicePoolToString(Iterable<Service> pool, { Set<Service>? marked, String mark = '!' }) =>
    '[${pool.map((service) => "${service.runtimeType}${(marked?.contains(service) == true) ? mark : ''}").join(', ')}]';
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