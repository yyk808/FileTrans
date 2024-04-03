import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_trans_rework/control/protocol.dart';
import 'package:file_trans_rework/core/lan.dart';
import 'package:file_trans_rework/core/wlan_p2p.dart';
import 'package:file_trans_rework/wigets/discovered_device.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:permission_handler/permission_handler.dart';

import '../common/global.dart';
import 'ble.dart';

enum ConnectivityAdapterTypes {
  unknown,
  BLE,
  WifiP2p,
  LAN,
}

enum ConnectionState {
  Unknown, // Default
  Ready,  // Initialized
  Connected,
}

enum TransferState {
  Unknown,
  Ready,
  Listening, // host side
  Connecting, // client side
  Transferring, // Transferring and available
  Occupied // Transferring but not available
}

enum ConnectionType {
  unknown,
  le,
  hb
}

final fingerPrint = Random(DateTime.timestamp().microsecond).nextInt(1 << 32);
final nickName = "nickName";
final deviceName = "randomDevice";

class PeerData{
  // directly stores data to display and the key to connect
  PeerData({
    required this.unifiedId,
    required this.nickName,
    required this.deviceName,

    this.supportBle = false,
    this.btAddress,
    this.btDevice,

    this.supportWlanP2p = false,
    this.networkName,

    this.supportLan = false,
    this.ipAddr,
  });

  final int unifiedId;
  final String nickName;
  final String deviceName;

  bool supportBle;
  String? btAddress;
  ScanResult? btDevice;

  bool supportWlanP2p;
  String? networkName;

  bool supportLan = false;
  String? ipAddr;
}



// TODO: ResultData need a identification to clarify what inner is and help choose adapter to use.

abstract class ScanResults {
  void addResult(PeerData result);
  void replaceResults(List<PeerData> results);
  void deleteResult(PeerData result);
  void clearResult(List<PeerData> results);
}

// initialize -> turnOn -> [startScan | startBroadcast] -> connect(central only) -> transfer

abstract class AdapterAbstractionBase {
  final ConnectivityAdapterTypes type = ConnectivityAdapterTypes.unknown;
  final List<Permission> permissions = [];
  final ConnectionType connectionType = ConnectionType.unknown;

  bool isInitialized = false;

  // true if hardware supports and permissions acquired
  RxBool isAvailable = false.obs;

  Future<void> initialize();

  // can be called if available
  Future<bool> turnOn() async => false;
  Future<bool> turnOff() async => false;
}

abstract class CanBroadcast<Res> {
  RxList<Res> scanResults = <Res>[].obs;
  RxBool isBroadcasting = false.obs;
  RxBool isScanning = false.obs;
  RxBool connected = false.obs;

  Future<bool> startScan(int duration) async => false;
  Future<bool> stopScan() async => false;
  // hardware connection
  Future<bool> hardConnect(Res result) async => false;
  Future<bool> hardDisconnect(Res result) async => false;

  Future<bool> startBroadcast(int duration) async => false;
  Future<bool> stopBroadcast() async => false;
}


abstract class CanTransfer<Res> {
  late final Rx<TransferState> transferState;
  late final Rx<ConnectionState> connectionState;

  // handshake
  Future<PeerData> sayHello(Res target);

  // client(software connection)
  Future<bool> softConnect(PeerData result) async => false;
  Future<bool> softDisconnect(PeerData result) async => false;

  // host
  Future<bool> listen() async => false;
  Future<bool> stopListen() async => false;

  // p2p
  Future<bool> transferBlockData(PeerData target, String data, bool isPath);
  // Future<bool> transferStreamData(ResultData target, String data) async => false;
}

Future<void> registerCore() async {
  final bleAdapter = BLEConnectivityAdapter();
  final lanAdapter = LocalAreaConnectivityAdapter();
  final wlanP2pAdapter = WlanP2pConnectivityAdapter();

  await wlanP2pAdapter.initialize();
  await bleAdapter.initialize();
  await lanAdapter.initialize();

  Global.adapters[ConnectivityAdapterTypes.BLE] = bleAdapter;
  Global.adapters[ConnectivityAdapterTypes.WifiP2p] = wlanP2pAdapter;
  Global.adapters[ConnectivityAdapterTypes.LAN] = lanAdapter;
}
