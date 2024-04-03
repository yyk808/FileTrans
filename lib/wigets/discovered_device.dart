import 'package:bonsoir/bonsoir.dart';
import 'package:file_trans_rework/core/base.dart';
import 'package:file_trans_rework/core/lan.dart';
import 'package:file_trans_rework/pages/device_control.dart';
import 'package:file_trans_rework/pages/device_screen.dart';
import 'package:file_trans_rework/wigets/dialogs/device_control_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:get/get.dart';
import 'package:flip_card/flip_card.dart';

import '../core/wlan_p2p.dart';
import 'dialog.dart';

// enum DeviceType {
//   bluetooth,
//   wifi,
//   bonjour,
// }
//
// final Map<DeviceType, Icon> _deviceTypeIconMap = {
//   DeviceType.bluetooth: Icon(Icons.bluetooth),
//   DeviceType.wifi: Icon(Icons.wifi),
//   DeviceType.bonjour: Icon(Icons.back_hand),
// };
//
// // The data shown in device widget
// class DeviceData {
//   DeviceData({
//     required this.type,
//     required this.name,
//     required this.id,
//     required this.nextPageRouter,
//     required this.manager,
//     required this.device,
//   });
//
//   final DeviceType type;
//   final String name;
//   final String id;
//
//   final String nextPageRouter;
//   final AdapterAbstractionBase manager;
//   final dynamic device;
// }
//
// class DiscoveredDevice extends StatelessWidget {
//   const DiscoveredDevice({
//     super.key,
//     required this.deviceData
//   });
//
//   final DeviceData deviceData;
//
//   @override
//   Widget build(BuildContext context) {
//     return     Card(
//       clipBehavior: Clip.antiAlias,
//       child: ListTile(
//         leading: _deviceTypeIconMap[deviceData.type],
//         title: Text(deviceData.name),
//         subtitle: Text(deviceData.id),
//         trailing: const Icon(Icons.arrow_right_outlined),
//         onTap: () async {
//           // Navigator.of(context).pushNamed(deviceData.nextPageRouter, arguments: deviceData.device);
//           await showAdaptiveDialog(
//             context: context,
//             builder: (context) => ConnectionDialog(device: deviceData),
//           );
//         },
//       ),
//     );
//   }
// }

class ExpansionDetails extends StatelessWidget {
  const ExpansionDetails({
    super.key,
    required this.deviceData,
  });

  final PeerData deviceData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text("Details"),
        initiallyExpanded: false,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        children: [Text("data"), Text("data")],
      ),
    );
  }
}

class DiscoveredDeviceTile extends StatelessWidget {
  const DiscoveredDeviceTile({super.key, required this.deviceData});

  final PeerData deviceData;

  // Row(children: [
  //         CircleAvatar(
  //           child: Icon(Icons.person),
  //         ),
  //         Expanded(child: Column(children: [
  //           Text(deviceData.nickName),
  //           ExpansionDetails(deviceData: deviceData)
  //         ])),
  //         IconButton(onPressed: null, icon: Icon(Icons.star)),
  //       ]),

  Widget _tip(String s) {
    return Container(
      padding: EdgeInsets.only(left: 5 ,right: 5),
      margin: EdgeInsets.only(left: 5, right: 5),
      decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(5)
      ),
      child: Text(s),
    );
  }

  List<Widget> _tips() {
    List<Widget> ret = [];
    if(deviceData.supportBle) {
      ret.add(_tip("BLE"));
    }
    if(deviceData.supportWlanP2p) {
      ret.add(_tip("WlanP2P"));
    }
    if(deviceData.supportLan) {
      ret.add(_tip("Lan"));
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        surfaceTintColor: Colors.red,
        margin: EdgeInsets.only(left: 15, right: 15,top: 5),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.person),
          ),
          title: Text(deviceData.nickName, style: TextStyle(fontSize: 20),),
          subtitle: Row(
            children: _tips(),
          ),
          trailing: IconButton(onPressed: null, icon: Icon(Icons.star)),
          onTap: () {
            Get.to(() => DeviceControlPage(deviceData: deviceData))?.then((val) async {
              final lan = LocalAreaConnectivityAdapter();
              final p2p = WlanP2pConnectivityAdapter();
              // await lan.softDisconnect(deviceData);
              // await p2p.softDisconnect(deviceData);

              // await p2p.hardDisconnect(const DiscoveredPeers(deviceName: "", deviceAddress: "", isGroupOwner: false, isServiceDiscoveryCapable: false, primaryDeviceType: "", secondaryDeviceType: "", status: 0));

            });
          },
        )
    );
  }
}
