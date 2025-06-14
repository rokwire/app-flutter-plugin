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
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';


class Analytics with Service, NotificationsListener {

  // Database Data

  static const String   _databaseName         = "analytics.db";
  static const int      _databaseVersion      = 2;
  static const String   _databaseTable        = "events";
  static const String   _databasePacket       = "packet";
  static const String   _databaseTimestamp    = "timestamp";
  static const String   _databaseRowID        = "rowid";
  static const int      _databaseMaxPackCount = 64;
  static const Duration _timerTick            = Duration(milliseconds: 100);
  
  // Data

  Database?             _database;
  Timer?                _timer;
  bool                  _inTimer = false;
  
  PackageInfo?          _packageInfo;
  AndroidDeviceInfo?    _androidDeviceInfo;
  IosDeviceInfo?        _iosDeviceInfo;
  String?               _appId;
  String?               _appVersion;
  String?               _osVersion;
  String?               _deviceModel;
  ConnectivityStatus?   _connectionStatus;

  // Accessories
  String   get databaseName         => _databaseName;
  int      get databaseVersion      => _databaseVersion;
  String   get databaseTable        => _databaseTable;
  String   get databasePacket       => _databasePacket;
  String   get databaseTimestamp    => _databaseTimestamp;
  String   get databaseRowID        => _databaseRowID;
  int      get databaseMaxPackCount => _databaseMaxPackCount;
  Duration get timerTick            => _timerTick;

  @protected
  Database? get database            => _database;

  PackageInfo?        get packageInfo       => _packageInfo;
  AndroidDeviceInfo?  get androidDeviceInfo => _androidDeviceInfo;
  IosDeviceInfo?      get iosDeviceInfo     => _iosDeviceInfo;
  String?             get appId             => _appId;
  String?             get appVersion        => _appVersion;
  String?             get osVersion         => _osVersion;
  String?             get deviceModel       => _deviceModel;
  ConnectivityStatus? get connectionStatus  => _connectionStatus;

  // Singletone Factory

  static Analytics? _instance;

  static Analytics? get instance => _instance;
  
  @protected
  static set instance(Analytics? value) => _instance = value;

  factory Analytics() => _instance ?? (_instance = Analytics.internal());

  @protected
  Analytics.internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
    ]);

  }

  @override
  Future<void> initService() async {

    await initDatabase();
    initTimer();

    updateConnectivity();
    
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      _packageInfo = packageInfo;
      _appId = _packageInfo?.packageName;
      _appVersion = "${_packageInfo?.version}+${_packageInfo?.buildNumber}";
    });

    if (defaultTargetPlatform == TargetPlatform.android) {
      DeviceInfoPlugin().androidInfo.then((AndroidDeviceInfo androidDeviceInfo) {
        _androidDeviceInfo = androidDeviceInfo;
        _deviceModel = _androidDeviceInfo?.model;
        _osVersion = _androidDeviceInfo?.version.release;
      });
    }
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
      DeviceInfoPlugin().iosInfo.then((IosDeviceInfo iosDeviceInfo) {
        _iosDeviceInfo = iosDeviceInfo;
        _deviceModel = _iosDeviceInfo?.model;
        _osVersion = _iosDeviceInfo?.systemVersion;
      });
    }
  
    if (_database != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Analytics Initialization Failed',
        description: 'Failed to create analytics database.',
      );
    }
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this, Connectivity.notifyStatusChanged);
    closeDatabase();
    closeTimer();
    super.destroyService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Connectivity(), Config() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      applyConnectivityStatus(param);
    }
  }

  // Database

  @protected
  Future<void> initDatabase() async {
    if (_database == null) {
      String databasePath = await getDatabasesPath();
      String databaseFile = join(databasePath, databaseName);
      _database = await openDatabase(databaseFile, version: databaseVersion,
        onCreate: (Database db, int version) async {
          await db.execute("CREATE TABLE IF NOT EXISTS `$databaseTable` (`$databaseTimestamp` INTEGER DEFAULT NULL, `$databasePacket` TEXT NOT NULL)",);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE `$databaseTable` ADD COLUMN `$databaseTimestamp` INTEGER DEFAULT NULL",);
          }
        }
      );
    }
  }

  @protected
  void closeDatabase() {
    if (_database != null) {
      _database!.close();
      _database = null;
    }
  }

  // Timer

  @protected
  void initTimer() {
      if (_timer == null) {
        //Log.d("Analytics: awake");
        _timer = Timer.periodic(timerTick, onTimer);
        _inTimer = false;
      }
  }

  @protected
  void closeTimer() {
    if (_timer != null) {
      //Log.d("Analytics: asleep");
      _timer!.cancel();
      _timer = null;
    }
    _inTimer = false;
  }

  // Packets Processing
  
  @protected
  Future<int> savePacket(String packet, int? timestamp) async {
    if (_database != null) {
      int result = await _database!.insert(databaseTable, {
        databasePacket : packet,
        databaseTimestamp : timestamp
      });
      //Log.d("Analytics: scheduled packet #$result $packet");
      initTimer();
      return result;
    }
    return -1;
  }

  @protected
  void onTimer(_) {
    
    if ((_database != null) && !_inTimer && (_connectionStatus != ConnectivityStatus.none)) {
      _inTimer = true;

      int? deliveryTimeout = Config().analyticsDeliveryTimeout;
      int? filterTimestamp = (deliveryTimeout != null) ? (DateTime.now().millisecondsSinceEpoch - (deliveryTimeout * 1000)) : null;
      
      _database!.rawQuery("SELECT `$databaseRowID`, `$databasePacket`, `$databaseTimestamp` FROM `$databaseTable` ORDER BY `$databaseRowID` LIMIT $databaseMaxPackCount").then((List<Map<String, dynamic>> records) {
        if (records.isNotEmpty) {

          String packets = '', rowIDs = '';
          for (Map<String, dynamic> record in records) {

            int? recordTimestamp = JsonUtils.intValue(record[databaseTimestamp]);
            if ((filterTimestamp == null) || (recordTimestamp == null) || (filterTimestamp < recordTimestamp)) {
              if (packets.isNotEmpty) {
                packets += ',';
              }
              packets += '${record[databasePacket]}';
            }

            if (rowIDs.isNotEmpty) {
              rowIDs += ',';
            }
            rowIDs += '${record[databaseRowID]}';
          }

          if (packets.isNotEmpty) {
            sendPacket('[$packets]').then((bool success) {
              if (success && rowIDs.isNotEmpty) {
                _database!.execute("DELETE FROM `$databaseTable` WHERE `$databaseRowID` in ($rowIDs)").then((_){
                  //Log.d("Analytics: sent packets $rowIDs");
                  _inTimer = false;
                });
              }
              else {
                //Log.d("Analytics: failed to send packets $rowIDs");
                _inTimer = false;
              }
            });
          }
          else if (rowIDs.isNotEmpty) {
            _database!.execute("DELETE FROM `$databaseTable` WHERE `$databaseRowID` in ($rowIDs)").then((_){
              //Log.d("Analytics: sent packets $rowIDs");
              _inTimer = false;
            });
          }
          else {
            _inTimer = false;
          }
        }
        else {
          closeTimer();
        }
      });
    }
  }

  @protected
  Future<bool> sendPacket(String? packet) async {
    if (packet != null) {
      try {
        //TMP: Temporarly use ConfugApiKeyNetworkAuth auth until logging service gets updated to acknowledge the new Core BB token.
        //TBD: Remove this when logging service gets updated.
        final response = await Network().post(Config().loggingUrl, body: packet, headers: { "Accept": "application/json", "Content-type": "application/json" }, auth: Config() /* Auth2() */, sendAnalytics: false);
        return (response != null) && ((response.statusCode == 200) || (response.statusCode == 201));
      }
      catch (e) {
        debugPrint(e.toString());
        return false;
      }
    }
    return false;
  }

  // Connectivity

  @protected
  void updateConnectivity() {
    applyConnectivityStatus(Connectivity().status);
  }

  @protected
  void applyConnectivityStatus(ConnectivityStatus? status) {
    _connectionStatus = status;
  }

  // Public Accessories

  void logEvent(Map<String, dynamic> event, { int? timestamp }) {
    String packet = json.encode(event);
    debugPrint('Analytics: $packet');
    savePacket(packet, timestamp);
  }
}
