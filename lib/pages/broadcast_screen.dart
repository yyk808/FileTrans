import 'dart:ffi';

import 'package:bonsoir/bonsoir.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/core/lan.dart';
import 'package:file_trans_rework/wigets/toast_body.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../common/global.dart';
import '../core/base.dart';
import '../core/ble.dart';
import '../core/wlan_p2p.dart';

// class BroadcastScreen extends StatelessWidget {
//   const BroadcastScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final wlanP2pAdapter = Global.adapters[ConnectivityAdapterTypes.WifiP2p]!
//     as WlanP2pConnectivityAdapter;
//     final bleAdapter =
//     Global.adapters[ConnectivityAdapterTypes.BLE]! as BLEConnectivityAdapter;
//     final lanAdapter = Global.adapters[ConnectivityAdapterTypes.LAN]! as LocalAreaConnectivityAdapter;
//
//     final wlanP2pBroadcasting = ref.watch(wlanP2pAdapter.stateProvider.select((state) => state.value?.isGroupOwner as bool?));
//
//     final lanBroadcasting = ref.watch(lanAdapter.isBroadcasting.select((state) => state.value));
//
//     return Center(
//         child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         SwitchListTile(
//             value: wlanP2pBroadcasting != null && wlanP2pBroadcasting,
//             onChanged: (bool value) async {
//               if (wlanP2pBroadcasting != null && wlanP2pBroadcasting) {
//                 await wlanP2pAdapter.stopListen();
//                 await wlanP2pAdapter.stopBroadcast();
//               } else {
//                 await wlanP2pAdapter.stopBroadcast();
//                 await wlanP2pAdapter.startBroadcast();
//                 final ret = await wlanP2pAdapter.listen();
//                 showToastInfo("Listening: $ret");
//               }
//             },
//             title: const Text("Wlan P2P Broadcasting"),
//         ),
//
//         SwitchListTile(
//             value: lanBroadcasting ?? false,
//             onChanged: (bool value) async {
//               if(value) {
//                 await lanAdapter.startBroadcast();
//                 final ret = await lanAdapter.listen();
//                 showToastInfo("Listening: $ret");
//               } else {
//                 await lanAdapter.stopListen();
//                 await lanAdapter.stopBroadcast();
//               }
//             },
//             title: const Text("Lan Broadcasting")
//         )
//       ],
//     ));
//   }
// }
