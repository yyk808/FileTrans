import 'dart:async';
import 'dart:isolate';

import 'package:bonsoir/bonsoir.dart';
import 'package:file_trans_rework/common/global.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/core/base.dart';
import 'package:file_trans_rework/core/ble.dart';
import 'package:file_trans_rework/core/lan.dart';
import 'package:file_trans_rework/core/wlan_p2p.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';

final _log = Logger("Control");

class TransferController {
  static final TransferController _singleton = TransferController._internal();

  TransferController._internal();

  factory TransferController() => _singleton;

  RxMap<int, PeerData> discoveredPeers = RxMap<int, PeerData>();
  bool _broadcasting = false;
  Timer? _broadcastScheduler;
  Timer? _scanScheduler;
  String? _targetNetwork;

  Map<String, bool> _found = Map();
  StreamSubscription<List<ScanResult>>? bleSub;
  StreamSubscription<List<ResolvedBonsoirService>>? lanSub;

  Future<void> initialize() async {
    final adapters = Global.adapters;
    for (final k in adapters.keys) {
      await adapters[k]!.turnOn();
    }
  }

  void _mergePeers(PeerData peer) {
    print("peer status: ${peer.supportLan},${peer.supportBle},${peer.supportWlanP2p}");
    if (discoveredPeers.containsKey(peer.unifiedId)) {
      final cur = discoveredPeers[peer.unifiedId]!;
      if (peer.supportBle) {
        print("merging ble: ${peer.btAddress}, ${peer.btDevice?.device.mtuNow}");
        cur.supportBle = true;
        cur.btAddress = peer.btAddress;
        cur.btDevice = peer.btDevice;
      }
      if (peer.supportLan) {
        print("merging lan");
        cur.supportLan = true;
        cur.ipAddr = peer.ipAddr;
      }
      if (peer.supportWlanP2p) {
        print("merging p2p: ${peer.networkName}");
        cur.supportWlanP2p = true;
        if(peer.networkName != null && peer.networkName != "null") {
          cur.networkName = peer.networkName;
        }
      }
      discoveredPeers.update(peer.unifiedId, (_) => cur);
    } else {
      discoveredPeers[peer.unifiedId] = peer;
    }
  }

  void startScheduledBroadcast() {
    if (_broadcasting) {
      return;
    }
    _broadcasting = true;

    const broadcastInterval = 15;

    final ble = BLEConnectivityAdapter();
    final lan = LocalAreaConnectivityAdapter();
    final p2p = WlanP2pConnectivityAdapter();
    f() async {
      await ble.stopBroadcast();
      await ble.startBroadcast(broadcastInterval);

      // lan.stopBroadcast();
      await lan.startBroadcast(broadcastInterval + 5);

      // await p2p.stopBroadcast();
      await p2p.startBroadcast(-1);
    }

    // filter out low energy adapters to broadcast continuously.
    // final adapters = Global.adapters.values
    //     .where((element) =>/* element.connectionType == ConnectionType.le && */element is CanBroadcast)
    //     .map((element) => element as CanBroadcast);

    f();
    _broadcastScheduler =
        Timer.periodic((1.2 * broadcastInterval).seconds, (timer) async {
      // non-sense... for now.
      // for(final ada in adapters) {
      //   await ada.stopBroadcast();
      //   await ada.startBroadcast(broadcastInterval);
      // }
      await f();
    });

    // start server
    ble.listen();
    lan.listen();
    p2p.listen();
  }

  void startScan() {
    if (_scanScheduler != null) {
      return;
    }

    const scanInterval = 5;

    final ble = BLEConnectivityAdapter();
    bleSub = ble.scanResults.stream.listen((results) async {
      if (results.isNotEmpty) {
        _log.fine(
            "found: ${_found.length}, peers: ${discoveredPeers.length}, result: ${results.length}");
        _log.fine("${results[0].device.remoteId}");
      } else {
        return;
      }
      for (final item in results) {
        final id = item.device.remoteId.str;
        if (!(_found.containsKey(id) && _found[id] == true)) {
          if (await ble.hardConnect(item)) {
            final peer = await ble.sayHello(item);
            _found[id] = await ble.softConnect(peer);
            _mergePeers(peer);
          }
        }
      }
    });

    final lan = LocalAreaConnectivityAdapter();
    lanSub = lan.scanResults.stream.listen((services) async {
      _log.info("Lan ScanResult: ${services.length}, fp ${fingerPrint}");
      for (final s in services) {
        final peer = await lan.sayHello(s);
        _log.info("peer: ${peer.unifiedId}");
        _mergePeers(peer);
      }
    });

    final p2p = WlanP2pConnectivityAdapter();
    p2p.scanResults.stream.listen((devices) async {
      for (final d in devices) {
        // final peer = await p2p.sayHello(d);
        // _mergePeers(peer);
        print(
            "Wlan P2P info: ${d.deviceName}, ${d.deviceAddress}, ${d.primaryDeviceType}, ${d.secondaryDeviceType}");
      }
    });

    FlutterBlePeripheral().getDataReceived.listen((data) {
      print("Data received: ${data.characteristicUUID}:${String.fromCharCodes(data.value)}");
      if (data.characteristicUUID == "00000002-a123-48ce-896b-4c76973373e7") {
        final s = String.fromCharCodes(data.value).split(",");
        PeerData peer;
        print("data: ${s},length: ${s.length}");
        if(s[0] == fingerPrint.toString()) {
          _log.info("Ignore self ble");
          return;
        }

        if (s.length == 3) {
          peer = PeerData(
              unifiedId: int.parse(s[0]), nickName: s[1], deviceName: s[2], supportBle: true);
          _mergePeers(peer);
        } else if (s.length == 4) {
          print("Target network name: ${s[3]}");
          _targetNetwork = s[3];
          peer = PeerData(
              unifiedId: int.parse(s[0]),
              nickName: s[1],
              deviceName: s[2],
              supportWlanP2p: true,
              networkName: s[3],

              supportBle: true,
          );
          _mergePeers(peer);
        }
      }
    });

    _scanScheduler = Timer.periodic((scanInterval.seconds), (timer) async {
      _log.info("Start scan...");
      await ble.stopScan();
      await lan.stopScan();
      await p2p.stopScan();
      await ble.startScan(scanInterval);
      await lan.startScan(scanInterval);
      await p2p.startScan(scanInterval);
    });
  }

  Future<bool> sendFile(PeerData peer, String path) async {
    if (peer.supportLan) {
      final lan = LocalAreaConnectivityAdapter();
      await lan.softConnect(peer);
      return lan.transferBlockData(peer, path, true);
    } else if (peer.supportWlanP2p) {
      final p2p = WlanP2pConnectivityAdapter();
      final name = peer.networkName!;
      print("found p2p devices: ${p2p.scanResults.length}");
      final target = p2p.scanResults.firstWhere((element) => name.split("-")[2] == element.deviceName);
      showToastInfo("Hard connecting...");
      if(!await p2p.hardConnect(target)) {
        showToastError("Hard connect failed");
        // return false;
      }

      showToastInfo("Soft connecting...");
      // await p2p.softDisconnect(peer);
      await p2p.softConnect(peer);

      showToastInfo("Transferring..");
      return p2p.transferBlockData(peer, path, true);
    }

    return false;
  }

  void stopScheduledBroadcast() {
    if (!_broadcasting) {
      return;
    }
    _broadcasting = false;
    _broadcastScheduler?.cancel();
    _broadcastScheduler = null;

    BLEConnectivityAdapter().stopListen();
    LocalAreaConnectivityAdapter().stopListen();
  }

  Future<void> _turnOnAdapter(ConnectivityAdapterTypes type) async {
    final ada = Global.adapters[type]!;

    if (ada.isAvailable.isTrue) {
      final res = await ada.turnOn();
      if (!res) {
        _log.info("Failed to turn on $type");
      }
    } else {
      _log.info("Adapter not available $type");
    }
  }

  Future<void> _turnOffAdapter(ConnectivityAdapterTypes type) async {
    final ada = Global.adapters[type]!;

    final res = await ada.turnOff();
    if (!res) {
      _log.info("Failed to turn off $type");
    }
  }
}
