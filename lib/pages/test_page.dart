import 'package:file_trans_rework/control/transfer_controller.dart';
import 'package:file_trans_rework/core/base.dart';
import 'package:file_trans_rework/core/ble.dart';
import 'package:file_trans_rework/core/lan.dart';
import 'package:file_trans_rework/core/wlan_p2p.dart';
import 'package:file_trans_rework/wigets/dialogs/device_control_card.dart';
import 'package:file_trans_rework/wigets/discovered_device.dart';
import 'package:file_trans_rework/wigets/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransferController();
    final ble = BLEConnectivityAdapter();
    final p2p = WlanP2pConnectivityAdapter();
    final lan = LocalAreaConnectivityAdapter();
    
    final bleConnected = Get.put(ble.connected);
    final bleBroadcasting = Get.put(ble.isBroadcasting);
    final bleScanning = Get.put(ble.isScanning);
    
    final p2pConnected = Get.put(p2p.connected);
    final p2pBroadcasting = Get.put(p2p.isBroadcasting);
    final p2pScanning = Get.put(p2p.isScanning);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Debug Screen"),
      ),

      body: Padding(padding: const EdgeInsets.only(left: 15, right: 15), child: ListView(
        children: [
          const SizedBox(height: 8),
          Obx(() => _InfoTile(title: "BLE", info: {
            "Connected": bleConnected.toString(),
            "Broadcasting": bleBroadcasting.toString(),
            "Scanning": bleScanning.toString()
          })),
          const SizedBox(height: 8),
          Obx(() => _InfoTile(title: "P2P", info: {
            "Connected": p2pConnected.value.toString(),
            "Broadcasting": p2pBroadcasting.value.toString(),
            "Scanning": p2pScanning.value.toString()
          }))
        ],
      ),),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({super.key, required this.title, required this.info});

  final String title;
  final Map<String, String> info;

  Widget _infoBox(String title, String? content,
      {Color contentColor = Colors.black38}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 30,
          width: 150,
          child: Text("$title: ",
              softWrap: true,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        Text(content ?? "null",
            softWrap: true,
            style: TextStyle(
                color: contentColor,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(padding: const EdgeInsets.all(4), child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
              color: Colors.black54,
              fontSize: 20,
              fontWeight: FontWeight.bold
          )),
          
          Column(children: info.entries.map((e) => _infoBox(e.key, e.value)).toList())
        ],
      ))
    );
  }

}
