import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/wigets/toast_body.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../core/base.dart';
import 'discovered_device.dart';

// class ConnectionDialog extends StatelessWidget {
//   const ConnectionDialog({super.key, required this.device});
//
//   final DeviceData device;
//
//   @override
//   Widget build(BuildContext context) {
//     final manager = device.manager;
//
//     return AlertDialog(
//       content: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ElevatedButton(
//               onPressed: () async {
//                 final ret = await manager.connect(device.device);
//                 showToastSuccess("Connect: $ret");
//               },
//               child: const Text("Connect")),
//           ElevatedButton(
//               onPressed: () async {
//                 final ret = await manager.transferData(device.device, "");
//                 showToastSuccess("Transfer: $ret");
//               },
//               child: const Text("Transfer")),
//           ElevatedButton(
//               onPressed: () async {
//                 final ret = await manager.disconnect(device.device);
//                 showToastSuccess("Disconnect: $ret");
//               },
//               child: const Text("Disconnect")),
//         ],
//       ),
//     );
//   }
// }