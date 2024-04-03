import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:file_trans_rework/common/permission.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/control/protocol.dart';
import 'package:file_trans_rework/core/wlan_p2p.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'base.dart';

final _log = Logger("BLE");

// Note:
// 1. (Ensure)Stop broadcasting after a device is connected

class BLEConnectivityAdapter
    implements
        AdapterAbstractionBase,
        CanBroadcast<ScanResult>,
        CanTransfer<ScanResult> {
  static final BLEConnectivityAdapter _singleton =
      BLEConnectivityAdapter._internal();

  BLEConnectivityAdapter._internal();

  factory BLEConnectivityAdapter() => _singleton;

  @override
  final ConnectivityAdapterTypes type = ConnectivityAdapterTypes.BLE;
  @override
  final ConnectionType connectionType = ConnectionType.le;
  @override
  final List<Permission> permissions = [
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.location,
  ];
  @override
  bool isInitialized = false;

  @override
  RxBool isAvailable = false.obs;
  @override
  RxBool isBroadcasting = false.obs;
  @override
  RxBool isScanning = false.obs;
  @override
  RxBool connected = false.obs;
  @override
  RxList<ScanResult> scanResults = <ScanResult>[].obs;

  @override
  Rx<ConnectionState> connectionState = ConnectionState.Unknown.obs;

  @override
  Rx<TransferState> transferState = TransferState.Unknown.obs;

  // Central side
  BluetoothCharacteristic? _send;
  BluetoothCharacteristic? _recv;
  BluetoothCharacteristic? _subs;
  BluetoothCharacteristic? _hshk;

  List<int>? _resp;
  StreamSubscription? _respValueStream;

  // Peripheral side
  StreamSubscription? _dataReceivedStream;

  final _connectionManager = FlutterBluePlus();
  final _broadcastManager = FlutterBlePeripheral();

  bool? _isCentral;
  StreamSubscription? _peripheralStateSubscription;
  StreamSubscription? _centralStateSubscription;
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _isScanningSubscription;
  StreamSubscription? _receiveDataSubscription;

  // Peripheral Configs
  static const String serviceUuid = 'bf27730d-860a-4e09-889c-2d8b6a9e0fe7';
  static const String readUuid = "00000001-A123-48CE-896B-4C76973373E6";
  static const String writeUuid = "00000002-A123-48CE-896B-4C76973373E7";
  static const String subsUuid = "00000003-A123-48CE-896B-4C76973373E8";
  static const String handshakeUuid = "00000004-A123-48CE-896B-4C76973373E9";
  static final CharacteristicDescription read = CharacteristicDescription(
      uuid: readUuid, value: Uint8List.fromList("hello".codeUnits), read: true);
  static final CharacteristicDescription write = CharacteristicDescription(
      uuid: writeUuid,
      value: Uint8List.fromList("world".codeUnits),
      write: true);
  static final CharacteristicDescription subscribe =
      CharacteristicDescription(uuid: subsUuid, notify: true, indicate: true);
  static final CharacteristicDescription handshake = CharacteristicDescription(
      uuid: handshakeUuid,
      value: Uint8List.fromList("${fingerPrint},${nickName},${deviceName}".codeUnits),
      read: true);

  final ServiceDescription service = ServiceDescription(
    uuid: serviceUuid,
    characteristics: [read, write, subscribe, handshake],
  );

  final AdvertiseData advertiseData = AdvertiseData(
    includeDeviceName: true,
    serviceUuid: serviceUuid,
    manufacturerId: fingerPrint
  );

  final AdvertiseSettings advertiseSettings = AdvertiseSettings(
    connectable: true,
    advertiseMode: AdvertiseMode.advertiseModeBalanced,
    txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
    timeout: 100000,
  );

  @override
  Future<void> initialize() async {
    if (!isInitialized) {
      checkPermissions(this);

      FlutterBluePlus.setLogLevel(LogLevel.none);

      // _broadcastManager.removeService(serviceUuid);
      _broadcastManager.addService(service);

      isInitialized = true;
    }
  }

  @override
  Future<bool> turnOff() async {
    if (connected.isTrue) {
      connected.value = false;
      await stopBroadcast();
      await stopScan();
    }

    await _peripheralStateSubscription?.cancel();
    await _centralStateSubscription?.cancel();
    await _isScanningSubscription?.cancel();
    await _scanResultsSubscription?.cancel();
    await _receiveDataSubscription?.cancel();

    _peripheralStateSubscription = null;
    _centralStateSubscription = null;
    _isScanningSubscription = null;
    _scanResultsSubscription = null;
    _receiveDataSubscription = null;

    _isCentral = null;

    return true;
  }

  @override
  Future<bool> turnOn() async {
    bool isBroadcastOk = false;
    bool isScanOk = false;
    List<ScanResult> deviceBuf = [];

    // sync state
    connected.value = _broadcastManager.isConnected;
    isBroadcasting.value = _broadcastManager.isAdvertising;

    await _broadcastManager.disconnect();

    _peripheralStateSubscription =
        _broadcastManager.onPeripheralStateChanged!.listen((event) {
      switch (event) {
        case PeripheralState.idle:
          isBroadcastOk = true;
        case PeripheralState.advertising:
          isBroadcastOk = true;
        case PeripheralState.connected:
          _isCentral = false;
          connected.value = (true);
          isBroadcastOk = true;
        default:
          debugPrint("PeripheralState: $event");
          connected.value = (false);
          isBroadcastOk = false;
      }

      isAvailable.value = (isBroadcastOk & isScanOk);
    });

    _centralStateSubscription = FlutterBluePlus.adapterState.listen((event) {
      switch (event) {
        case BluetoothAdapterState.on:
          isScanOk = true;
        default:
          debugPrint("BluetoothAdapterState: $event");
          isScanOk = false;
      }

      isAvailable.value = (isBroadcastOk & isScanOk);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((event) {
      isScanning.value = (event);
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((event) {

      // _log.info("found ble devices: ${event.length}");
      final tmp = event
          .where((e) =>
              e.advertisementData.serviceUuids.isNotEmpty &&
              e.advertisementData.serviceUuids[0].toString() ==
                  'bf27730d-860a-4e09-889c-2d8b6a9e0fe7')
          .toList();
      if(tmp.isEmpty) {
        return;
      }

      _log.info("filtered devices: ${tmp.length}");
      scanResults.assignAll(tmp.nonNulls);
    });

    connected.stream.listen((val) async {
      if (!val || _isCentral == null) {
        return;
      }

      final isCentral = _isCentral!;
      if (isCentral) {
        await listen();
      }
    });

    return true;
  }

  @override
  Future<bool> startBroadcast(int duration) async {
    _log.info("starting BLE broadcast....");
    if (_broadcastManager.isAdvertising) {
      await stopBroadcast();
    }

    if (connected.isTrue || _broadcastManager.isConnected) {
      return true;
    }

    if(isBroadcasting.isTrue) {
      return true;
    }

    await _broadcastManager.start(
      advertiseData: advertiseData,
      advertiseSettings: advertiseSettings,
    );

    // showToastInfo("Start ble broadcast");
    isBroadcasting.value = true;
    return true;
  }

  @override
  Future<bool> startScan(int duration) async {
    if(duration < 0 || isScanning.isTrue) {
      return true;
    }

    try {
      await FlutterBluePlus.startScan(
          timeout: duration > 0 ? duration.seconds : 15.seconds,
          continuousUpdates: true,
          continuousDivisor: 1);
      isScanning.value = true;
    } catch (e) {
      debugPrint('startScan failed: ${e.toString()}');
      return false;
    }
    return true;
  }

  @override
  Future<bool> stopBroadcast() async {
    await _broadcastManager.stop();
    isBroadcasting.value = false;
    return true;
  }

  @override
  Future<bool> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning.value = false;
    } catch (e) {
      debugPrint('stopScan failed: ${e.toString()}');
      return false;
    }
    return true;
  }

  @override
  Future<bool> hardConnect(ScanResult result) async {
    if (!(_isCentral ?? true)) {
      return false;
    }

    final device = result.device;
    if (device.isConnected) {
      return true;
    }

    try {
      await device.connect();
    } catch (e) {
      debugPrint('Connecting to ble device error: ${e.toString()}');
      return false;
    }

    try {
      // the real connecting function in BLEConnectivityAdapter should be called first
      assert(device.isConnected);

      await device.discoverServices(timeout: 15);
      final List<BluetoothService> services = device.servicesList;
      assert(services.isNotEmpty);

      // some checks
      bool found = false;
      for (final service in services) {
        if (service.serviceUuid != Guid(BLEConnectivityAdapter.serviceUuid)) {
          continue;
        }

        final chs = service.characteristics;
        assert(chs.isNotEmpty);

        for (final ch in chs) {
          if (ch.characteristicUuid == Guid(BLEConnectivityAdapter.readUuid)) {
            _recv = ch;
          } else if (ch.characteristicUuid ==
              Guid(BLEConnectivityAdapter.writeUuid)) {
            _send = ch;
          } else if (ch.characteristicUuid ==
              Guid(BLEConnectivityAdapter.subsUuid)) {
            _subs = ch;
          } else if (ch.characteristicUuid ==
              Guid(BLEConnectivityAdapter.handshakeUuid)) {
            _hshk = ch;
          }
        }
        assert(
            _send != null && _recv != null && _recv != null && _hshk != null);
        found = true;
        break;
      }
      assert(found);

      // subscribe to ch
      await _subs!.setNotifyValue(true);
      _respValueStream = _subs!.lastValueStream.listen((event) {
        _resp = event;
      });
    } catch (e) {
      debugPrint("Discovering services error: ${e.toString()}");
      return false;
    }
    return true;
  }

  @override
  Future<bool> hardDisconnect(ScanResult result) async {
    if (!(_isCentral ?? true)) {
      return false;
    }

    final device = result.device;
    if (!device.isConnected) {
      return true;
    }

    try {
      await device.disconnect();
      await _subs?.setNotifyValue(false);
      await _respValueStream?.cancel();

      _respValueStream = null;
      _recv = _send = _subs = null;
      _resp = null;
    } catch (e) {
      debugPrint('Disconnecting to device error: ${e.toString()}');
      return false;
    }
    return true;
  }

  bool _isValidTarget(PeerData target) {
    return target.supportBle &&
        target.btDevice != null &&
        target.btAddress != null;
  }

  @override
  Future<bool> softConnect(PeerData result) async {
    if (!_isValidTarget(result)) {
      return false;
    }

    _isCentral = true;
    return true;
  }

  @override
  Future<bool> softDisconnect(PeerData result) async {
    _isCentral = false;
    return true;
  }

  @override
  Future<bool> listen() async {
    // no support for multiple devices CURRENTLY
    if (_subs == null) {
      return false;
    }

    _dataReceivedStream = _subs!.lastValueStream.listen((event) {
      _resp = event;
    });
    return true;
  }

  @override
  Future<bool> stopListen() async {
    await _dataReceivedStream?.cancel();
    return true;
  }

  @override
  Future<PeerData> sayHello(ScanResult target) async {
    final device = target.device;
    await device.requestMtu(512);

    final p2p = WlanP2pConnectivityAdapter();
    final send = _send!;
    final newStr = "${fingerPrint},${nickName},${deviceName},${p2p.info?.groupNetworkName}";
    _log.info('sent by ble: $newStr');
    send.write(Uint8List.fromList(newStr.codeUnits));

    final data = String.fromCharCodes(await _hshk!.read()).split(",");
    if(data.length == 4) {
      return PeerData(
        unifiedId: int.parse(data[0]),
        nickName: data[1],
        deviceName: data[2],
        supportBle: true,
        btAddress: device.remoteId.toString(),
        btDevice: target,

        supportWlanP2p: true,
        networkName: data[3],
      );
    } else {
      return PeerData(
        unifiedId: int.parse(data[0]),
        nickName: data[1],
        deviceName: data[2],
        supportBle: true,
        btAddress: device.remoteId.toString(),
        btDevice: target,
      );
    }
  }

  @override
  Future<bool> transferBlockData(PeerData target, String data, bool isPath) async {
    // consider diffs between central and peripheral
    // also mtu
    if (!_isValidTarget(target)) {
      return false;
    }
    final device = target.btDevice!.device;
    await device.requestMtu(512);
    final _data = Uint8List.fromList(data.codeUnits);
    final mtu = device.mtuNow;

    // no sliding window, simple and naive impl, fku
    final origLen = data.length;
    final sentLen = (origLen / (mtu - 2) + 1) * (mtu);

    const maxRetry = 3;
    for (var idx = 0; idx < sentLen / mtu; idx++) {
      for (var retry = 0; retry < maxRetry; retry++) {
        try {
          await _send!.write(([0, idx] + _data.sublist(idx * mtu)).toList());
          break;
        } catch (e) {
          if (retry == maxRetry - 1) {
            debugPrint("Failed sending Characteristic: ${e.toString()}");
            throw ("Send Failed");
          }
        }
      }
    }
    return false;
  }

// @override
// Future<bool> transferStreamData(ResultData target, String data) async {
//   return false;
// }
}

// static final BLEConnectivityAdapter _singleton = BLEConnectivityAdapter._internal();
// BLEConnectivityAdapter._internal();
// bool _initialized = false;
// factory BLEConnectivityAdapter() => _singleton;
// @override
// Future<void> initialize() async {
//   if (!_initialized) {
//     await _init();
//     _initialized = true;
//   }
// }
//
//
// @override
// final ConnectivityAdapterTypes type = ConnectivityAdapterTypes.BLE;
// @override
// final String broadcastingType = "broadcast";
//
// final FlutterBluePlus inner = FlutterBluePlus();
// late final StreamProvider<List<ScanResult>> scanResults;
// late final StreamProvider<bool> isScanning;
// late final StreamProvider<bool> isTransferring;
//
//
// Future<void> _init() async {
//   isScanning = StreamProvider((ref) async* {
//     await for (final state in FlutterBluePlus.isScanning) {
//       yield state;
//     }
//   });
//
//   scanResults = StreamProvider<List<ScanResult>>((ref) async* {
//     await for (final results in FlutterBluePlus.scanResults) {
//       yield results;
//     }
//   });
//
//   isTransferring = StreamProvider<bool>((ref) async* {
//     await for(final state in FlutterBluePlus.adapterState) {
//       if (state == BluetoothAdapterState.unavailable) {
//         yield true;
//       } else {
//         yield false;
//       }
//     }
//   });
//   // includeDeviceName = false;
//   // _data.uuid = 'bf27730d-860a-4e09-889c-2d8b6a9e0fe7';
//   // _data.manufacturerId = 1234;
//   // _data.manufacturerData = [1, 2, 3, 4, 5, 6];
//   // _data.txPowerLevel = AdvertisePower.ADVERTISE_TX_POWER_ULTRA_LOW;
//   // _data.advertiseMode = AdvertiseMode.ADVERTISE_MODE_LOW_LATENCY;
//
// }

// @override
// Future<bool> connect(ScanResult result) async {
//   final device = result.device;
//   if (device.isConnected) {
//     return false;
//   }
//
//   try {
//     await device.connect();
//   } catch (e) {
//     print(e);
//     return false;
//   }
//   return true;
// }
//
// @override
// Future<bool> transferData(ScanResult target, String data) async {
//   // TODO: should consider mtu
//   final device = target.device;
//   if (!device.isConnected) {
//     return false;
//   }
//
//   try {
//     await device.discoverServices(timeout: 15);
//     List<BluetoothService> services = device.servicesList;
//     if (services.isEmpty) {
//       print("No services found for device: ${device.remoteId.toString()}");
//       return false;
//     }
//
//     for (var target in services) {
//       if (target.serviceUuid == Guid("1010")) {
//         List<BluetoothCharacteristic> characteristics =
//             target.characteristics;
//         if (characteristics.isEmpty) {
//           print(
//               "No characteristics found for service: ${target.serviceUuid.toString()}");
//           return false;
//         }
//
//         for (final characteristic in characteristics) {
//           if (characteristic.uuid == Guid("1111")) {
//             await characteristic.write(data.codeUnits);
//             return true;
//           }
//         }
//       }
//     }
//   } catch (e) {
//     print(e);
//     return false;
//   }
//
//   return true;
// }
//
// @override
// Future<bool> disconnect(ScanResult result) async {
//   final device = result.device;
//   if (device.isConnected) {
//     return true;
//   }
//
//   try {
//     await device.disconnect();
//   } catch (e) {
//     print(e);
//     return false;
//   }
//
//   return true;
// }
//
