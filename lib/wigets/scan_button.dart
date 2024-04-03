import 'package:flutter/material.dart';

import '../common/global.dart';
import '../core/ble.dart';
import '../core/base.dart';
import '../core/lan.dart';
import '../core/wlan_p2p.dart';

// Future<void> _scanAll() {
//   return Future.wait([
//     Global.adapters[ConnectivityAdapterTypes.BLE]!.startScan(),
//     Global.adapters[ConnectivityAdapterTypes.WifiP2p]!.startScan(),
//     Global.adapters[ConnectivityAdapterTypes.LAN]!.startScan(),
//   ]);
// }
//
// Future<void> _stopAll() {
//   return Future.wait([
//     Global.adapters[ConnectivityAdapterTypes.BLE]!.stopScan(),
//     Global.adapters[ConnectivityAdapterTypes.WifiP2p]!.stopScan(),
//     Global.adapters[ConnectivityAdapterTypes.LAN]!.stopScan(),
//   ]);
// }
//
// class ScanButton extends ConsumerWidget {
//   const ScanButton({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final wlanP2pAdapter = Global.adapters[ConnectivityAdapterTypes.WifiP2p]!
//         as WlanP2pConnectivityAdapter;
//     final bleAdapter = Global.adapters[ConnectivityAdapterTypes.BLE]!
//         as BLEConnectivityAdapter;
//     final lanAdapter = Global.adapters[ConnectivityAdapterTypes.LAN]!
//         as LocalAreaConnectivityAdapter;
//
//     final wlanP2pScanning = ref.watch(wlanP2pAdapter.stateProvider
//         .select((state) => state.value?.groupFormed));
//     final bleScanning =
//         ref.watch(bleAdapter.isScanning.select((state) => state.value));
//     final lanScanning =
//         ref.watch(lanAdapter.isScanning.select((state) => state.value));
//
//     if ((wlanP2pScanning ?? false) || (bleScanning ?? false) || (lanScanning ?? false)) {
//       return const FloatingActionButton(
//         onPressed: _stopAll,
//         backgroundColor: Colors.red,
//         child: Icon(Icons.stop),
//       );
//     } else {
//       return const FloatingActionButton(
//           onPressed: _scanAll,
//           backgroundColor: Colors.green,
//           child: Text("SCAN"));
//     }
//   }
// }
