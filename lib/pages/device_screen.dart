import 'package:file_trans_rework/common/global.dart';
import 'package:file_trans_rework/control/transfer_controller.dart';
import 'package:file_trans_rework/pages/files_screen.dart';
import 'package:file_trans_rework/wigets/scan_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../core/ble.dart';
import '../core/base.dart';
import '../core/lan.dart';
import '../core/wlan_p2p.dart';
import '../wigets/discovered_device.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransferController();
    final devices = Get.put(controller.discoveredPeers);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Device Screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            iconSize: 30,
            onPressed: () => Get.to(FileScreen()),
          )
        ],
      ),

      body: Obx(
              () {
            return ListView(
              children: devices.values.map((e) => DiscoveredDeviceTile(deviceData: e)).toList(),
            );
          }
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     Get.to(FileScreen());
      //   },
      // ),
    );
  }

}

// final multiDevicesProvider = StreamProvider<List<DeviceData>>((ref) async* {
//   final wlanP2pAdapter = Global.adapters[ConnectivityAdapterTypes.WifiP2p]!
//       as WlanP2pConnectivityAdapter;
//   final bleAdapter =
//       Global.adapters[ConnectivityAdapterTypes.BLE]! as BLEConnectivityAdapter;
//   final lanAdapter = Global.adapters[ConnectivityAdapterTypes.LAN]!
//       as LocalAreaConnectivityAdapter;
//
//   final wlanP2pDevices = ref.watch(wlanP2pAdapter.scanResultsProvider);
//   final bleDevices = ref.watch(bleAdapter.scanResults);
//   final lanDevices = ref.watch(lanAdapter.scanResults);
//
//   final a = wlanP2pDevices.when(
//     data: (e) {
//       final data = e;
//       return data.map((e) {
//         return DeviceData(
//             type: DeviceType.wifi,
//             name: e.deviceName,
//             id: e.deviceAddress,
//             nextPageRouter: "/wifiInfo",
//             manager: wlanP2pAdapter,
//             device: e);
//       }).toList();
//     },
//     error: (e, s) => null,
//     loading: () => null,
//   );
//
//   final b = bleDevices.when(
//       data: (e) {
//         final data = e;
//         return data
//             .map((e) => DeviceData(
//                 type: DeviceType.bluetooth,
//                 name: e.device.advName,
//                 id: e.device.remoteId.str,
//                 nextPageRouter: "/bleInfo",
//                 manager: bleAdapter,
//                 device: e))
//             .toList();
//       },
//       error: (e, s) => null,
//       loading: () => null);
//
//   final c = lanDevices.when(
//       data: (value) {
//         // print("Something happens...");
//         return value.map((e) => DeviceData(
//             type: DeviceType.bonjour,
//             name: e.name,
//             id: "",
//             nextPageRouter: "/lanInfo",
//             manager: lanAdapter,
//             device: e
//         )).toList();
//       },
//       error: (e,s) => null,
//       loading: () => null,
//   );
//
//   yield (a ?? []) + (b ?? []) + (c ?? []);
// });
//
// List<Widget> _buildChildren(List<DeviceData> devices) {
//   return devices
//       .where((e) => e.name != "")
//       .map((e) => DiscoveredDevice(deviceData: e))
//       .toList();
// }
//
// class DeviceScreen extends ConsumerWidget {
//   const DeviceScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final devices = ref.watch(multiDevicesProvider);
//
//     return ListView(
//       children: devices.when(
//           skipLoadingOnReload: true,
//           skipLoadingOnRefresh: true,
//           data: (devices) => _buildChildren(devices),
//           error: (e, s) => [Text("Error: $e")],
//           loading: () => [const Text("Loading...")]),
//     );
//   }
// }
