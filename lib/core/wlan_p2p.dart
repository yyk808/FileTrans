import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_trans_rework/common/global.dart';
import 'package:file_trans_rework/common/permission.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/common/websocket.dart';
import 'package:file_trans_rework/control/protocol.dart';
import 'package:file_trans_rework/core/ble.dart';
import 'package:file_trans_rework/wigets/toast_body.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:permission_handler/permission_handler.dart';

import 'base.dart';

class WlanP2pConnectivityAdapter
    implements AdapterAbstractionBase, CanBroadcast<DiscoveredPeers>, CanTransfer<DiscoveredPeers> {

  static final WlanP2pConnectivityAdapter _singleton =
  WlanP2pConnectivityAdapter._internal();
  WlanP2pConnectivityAdapter._internal();
  factory WlanP2pConnectivityAdapter() => _singleton;

  @override
  final ConnectivityAdapterTypes type = ConnectivityAdapterTypes.WifiP2p;
  @override
  final ConnectionType connectionType = ConnectionType.hb;
  @override
  final List<Permission> permissions = [
    Permission.locationWhenInUse,
    Permission.nearbyWifiDevices
  ];

  @override
  RxBool connected = false.obs;

  @override
  RxBool isAvailable = false.obs;

  @override
  RxBool isBroadcasting = false.obs;

  @override
  bool isInitialized = false;

  @override
  RxBool isScanning = false.obs;

  @override
  RxList<DiscoveredPeers> scanResults = <DiscoveredPeers>[].obs;

  @override
  Rx<ConnectionState> connectionState = ConnectionState.Unknown.obs;

  @override
  Rx<TransferState> transferState = TransferState.Unknown.obs;

  WebsocketServer? _server;
  WifiP2PGroupInfo? info;

  final inner = FlutterP2pConnection();

  StreamSubscription? _wifiInfoSubscription;
  StreamSubscription? _discoveredPeersSubscription;
  Timer? _broadcastTimer;
  Timer? _discoveryTimer;

  String? groupOwnerAddress;

  @override
  Future<void> initialize() async {
    if (!isInitialized) {
      await checkPermissions(this);
      await inner.initialize();
      isInitialized = true;
      isAvailable.value = true;
    }
  }

  @override
  Future<bool> turnOff() async {
    _wifiInfoSubscription?.cancel();
    _discoveredPeersSubscription?.cancel();

    _wifiInfoSubscription = null;
    _discoveredPeersSubscription = null;

    await inner.unregister();
    return true;
  }

  @override
  Future<bool> turnOn() async {
    if (isAvailable.isFalse) {
      return false;
    }

    final res = await inner.register();
    if (!res) {
      return false;
    }
    await inner.removeGroup();
    _wifiInfoSubscription = inner.streamWifiP2PInfo().listen((event) {
      print("wifi info updated: ${event.groupOwnerAddress} ${event.isConnected}");
      if (event.isConnected) {
        groupOwnerAddress = event.groupOwnerAddress;
        connected.value = true;
      }

      if (isBroadcasting.value && event.isGroupOwner) {}
    });

    _discoveredPeersSubscription = inner.streamPeers().listen((event) {
      if (event.isNotEmpty) {
        scanResults.assignAll(event);
      }
    });

    return true;
  }

  @override
  Future<bool> hardConnect(DiscoveredPeers result) async {
    final ok = await hardDisconnect(result);
    // if(connected.isTrue) {
    //   return true;
    // }

    await inner.discover();
    final res = await inner.connect(result.deviceAddress);
    if (!res) {

      connected.value = false;
      return false;
    }

    connected.value = true;
    return true;
  }

  @override
  Future<bool> hardDisconnect(DiscoveredPeers result) async {
    final res = await inner.removeGroup();
    if (res) {
      groupOwnerAddress = null;

      isBroadcasting.value = false;
      connected.value = false;
    }
    return res;
  }

  @override
  Future<bool> startBroadcast(int duration) async {
    if(isBroadcasting.isTrue || connected.isTrue) {
      info = await inner.groupInfo();
      const targetService = BLEConnectivityAdapter.handshakeUuid;
      final newStr = "${fingerPrint},${nickName},${deviceName},${info?.groupNetworkName}";
      FlutterBlePeripheral().write(targetService, Uint8List.fromList(newStr.codeUnits));
      return true;
    }

    final res = await inner.createGroup();
    if(!res) {
      showToastError("Failed to create p2p group");
    }
    info = await inner.groupInfo();
    const targetService = BLEConnectivityAdapter.handshakeUuid;
    final newStr = "${fingerPrint},${nickName},${deviceName},${info?.groupNetworkName}";
    FlutterBlePeripheral().write(targetService, Uint8List.fromList(newStr.codeUnits));

    if (res) {
      isBroadcasting.value = res;
      if(duration > 0) {
        _broadcastTimer = Timer.periodic(duration.seconds, (timer) async {
          timer.cancel();
          await stopBroadcast();
        });
      }
    }
    return res;
  }

  @override
  Future<bool> startScan(int duration) async {
    final res = await inner.discover();
    if (res) {
      isScanning.value = res;
      if(duration > 0) {
        _discoveryTimer = Timer.periodic(duration.seconds, (timer) async {
          timer.cancel();
          await stopScan();
        });
      }
    }
    return res;
  }

  @override
  Future<bool> stopBroadcast() async {

    final res = await inner.removeGroup();
    if (res) {
      isBroadcasting.value = false;
    }
    return res;
  }

  @override
  Future<bool> stopScan() async {
    final res = await inner.stopDiscovery();
    if (res) {
      isScanning.value = false;
    }
    return res;
  }

  @override
  Future<bool> softConnect(PeerData result) async {
    final adapter = this;
    _server = WebsocketServer();
    // start socket?
    if(adapter.groupOwnerAddress == null) {
      return false;
    }

    return await _server!.connectToSocket(
        address: adapter.groupOwnerAddress!,
        downloadPath: "/storage/emulated/0/Download/",
        onConnect: (name) {
          print("Scoket Connected to $name ${adapter.groupOwnerAddress}");
        },
        transferUpdate: (transfer) {
          if(!transfer.completed) {
            showToastInfo("Transfer: ${transfer.count}/${transfer.total}");
          } else {
            showToastSuccess("Transfer completed");
          }

          print("Bytes transfered: ${transfer.count}");
          print("Total bytes: ${transfer.total}");
        },
        receiveString: (str) {
          print("String received: $str");
        });
  }

  @override
  Future<bool> softDisconnect(PeerData result) {
    return stopListen();
    // _server?.closeSocket();

  }

  @override
  Future<bool> listen() async {
    await stopListen();
    _server = WebsocketServer();
    return _server!.startSocket(
      address: "0.0.0.0",
      onConnect: (name, address) {
        print("Connected to $name $address");
      },
      transferUpdate: (transfer) {
        if(!transfer.completed) {
          showToastInfo("Transfer: ${transfer.count}/${transfer.total}");
        } else {
          showToastSuccess("Transfer completed");
        }

        print("Bytes transfered: ${transfer.count}");
        print("Total bytes: ${transfer.total}");
      },
      receiveString: (req) {
        showToastInfo("String received: $req");
        print("String received: $req");
      },
      deleteOnError: true,
      downloadPath: "/storage/emulated/0/Download/",
      maxConcurrentDownloads: 2,
    );
  }

  @override
  Future<bool> stopListen() async {
    _server?.closeSocket();
    _server = null;

    return true;
  }

  @override
  Future<bool> transferBlockData(PeerData target, String data, isPath) async {
    return _server!.sendStringToSocket(data.toString());
  }

  @override
  Future<PeerData> sayHello(DiscoveredPeers target) {
    // TODO: implement sayHello
    throw UnimplementedError();
  }
}

// static final WlanP2pConnectivityAdapter _singleton =
// WlanP2pConnectivityAdapter._internal();
//
// // 定义私有构造函数
// WlanP2pConnectivityAdapter._internal();
//
// bool _initialized = false;
//
// // 定义公共工厂构造函数
// factory WlanP2pConnectivityAdapter() => _singleton;
//
// // 使用 async 和 await 实现异步初始化
// @override
// Future<void> initialize() async {
//   if (!_initialized) {
//     await _init();
//     _initialized = true;
//   }
// }
//
// WifiP2PInfo? curState;
// late final StreamProvider<WifiP2PInfo> stateProvider;
// late final StreamProvider<List<DiscoveredPeers>> scanResultsProvider;
//
//
// @override
// late final String broadcastingType;
//
// final FlutterP2pConnection inner = FlutterP2pConnection();
//
// Future<void> _init() async {
//   await Permission.location.request();
//   await Permission.locationWhenInUse.request();
//
//   await Permission.nearbyWifiDevices.request();
//
//
//   await inner.initialize();
//   await inner.register();
//
//   stateProvider = StreamProvider((ref) async* {
//     await for (final state in inner.streamWifiP2PInfo()) {
//       curState = state;
//       yield state;
//     }
//   });
//
//   scanResultsProvider = StreamProvider((ref) async* {
//     List<DiscoveredPeers> cache = [];
//     await for (final devices in inner.streamPeers()) {
//       if (devices.isEmpty) {
//         yield cache;
//       } else {
//         cache = devices;
//         yield devices;
//       }
//     }
//   });
// }
//
// @override
// Future<bool> connect(DiscoveredPeers result) async {
//   print("Connecting to ${result.deviceAddress}");
//   final ret1 = await inner.connect(result.deviceAddress);
//   if (!ret1) {
//     return false;
//   }
//
//   for (var cnt = 0; cnt < 100; cnt++) {
//     if (curState != null && curState!.isConnected) {
//       break;
//     } else {
//       print("curState is null, wating...");
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//   }
//
//   if (curState == null) {
//     await disconnect(result);
//     return false;
//   }
//
//   final address = curState!.groupOwnerAddress;
//   print("address: $address");
//
//   final ret2 = await inner.connectToSocket(
//       groupOwnerAddress: address,
//       downloadPath: "/storage/emulated/0/Download/",
//       onConnect: (name) {
//         print("Scoket Connected to $name $address");
//       },
//       transferUpdate: (transfer) {
//         print("Bytes transfered: ${transfer.count}");
//         print("Total bytes: ${transfer.total}");
//       },
//       receiveString: (str) {
//         print("String received: $str");
//       }
//   );
//
//   return ret2 != false;
// }
//
// @override
// Future<bool> disconnect(DiscoveredPeers result) async {
//   final ret = await inner.removeGroup();
//   return ret != false;
// }
//
// @override
// Future<bool> startBroadcast() async {
//   final ret = await inner.createGroup();
//   return ret != false;
// }
//
// @override
// Future<bool> startScan() async {
//   final ret = await inner.discover();
//   return ret != false;
// }
//
// @override
// Future<bool> stopBroadcast() async {
//   final ret = await inner.removeGroup();
//   return ret != false;
// }
//
// @override
// Future<bool> listen() async {
//   for (var cnt = 0; cnt < 100; cnt++) {
//     if (curState != null && curState!.isGroupOwner) {
//       break;
//     } else {
//       print("curState is null, wating...");
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//   }
//
//   if (curState == null || !curState!.isGroupOwner) {
//     return false;
//   }
//
//   final ip = curState?.groupOwnerAddress;
//
//   print("ip: $ip");
//   await Future.delayed(const Duration(milliseconds: 1000));
//   return await inner.startSocket(
//     groupOwnerAddress: ip!,
//     onConnect: (name, address) {
//       print("Connected to $name $address");
//     },
//     transferUpdate: (TransferUpdate transfer) {
//       print("Bytes transfered: ${transfer.count}");
//       print("Total bytes: ${transfer.total}");
//     },
//     receiveString: (req) {
//       showToastInfo("received: $req");
//       print("String received: $req");
//     },
//     deleteOnError: true,
//     downloadPath: "/storage/emulated/0/Download/",
//     maxConcurrentDownloads: 2,
//   );
// }
//
// @override
// Future<bool> stopListen() async {
//   return inner.closeSocket();
// }
//
// @override
// Future<bool> stopScan() async {
//   final ret = await inner.stopDiscovery();
//   return ret != false;
// }
//
// @override
// Future<bool> transferData(DiscoveredPeers target, String data) async {
//   return inner.sendStringToSocket("Ok, it works");
// }
