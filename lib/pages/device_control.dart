import 'package:file_trans_rework/core/base.dart';
import 'package:file_trans_rework/wigets/file_picker.dart';
import 'package:flutter/material.dart';

import '../wigets/peer_info.dart';

class DeviceControlPage extends StatelessWidget {
  DeviceControlPage({super.key, required this.deviceData});

  final PeerData deviceData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Control"),
      ),

      body: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Send Something...", style: TextStyle(
                color: Colors.black54,
                fontSize: 25,
                fontWeight: FontWeight.bold
            )),
            HorizontalFilePicker(peer: deviceData,),
            SizedBox(height: 20),

            const Text("Peer Detailed Info", style: TextStyle(
                color: Colors.black54,
                fontSize: 25,
                fontWeight: FontWeight.bold
            )),
            PeerInfo(deviceData: deviceData),
          ],
        ),
      )
    );
  }

}