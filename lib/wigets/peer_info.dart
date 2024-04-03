import 'package:flutter/material.dart';

import '../common/toast.dart';
import '../common/websocket.dart';
import '../core/base.dart';

class PeerInfo extends StatelessWidget {
  const PeerInfo({super.key, required this.deviceData});

  final PeerData deviceData;

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

  List<Widget> _getBleInfo() {
    final device = deviceData.btDevice;
    final mac = deviceData.btAddress;

    return [
      _infoBox("Bluetooth MAC", mac),
      _infoBox("Bluetooth MTU", device?.device.mtuNow.toString()),
    ];
  }

  List<Widget> _getWlanP2pInfo() {
    final network = deviceData.networkName!;

    return [
      _infoBox("Peer network", network),
    ];
  }

  List<Widget> _getLanInfo() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> infoData = [
      _infoBox("Device Name", deviceData.deviceName),
      _infoBox("Nick Name", deviceData.nickName),
      _infoBox("Unified ID", deviceData.unifiedId.toString()),
    ];

    infoData.add(
        _infoBox("Support BLE", deviceData.supportBle.toString(),
            contentColor: deviceData.supportBle ? Colors.green : Colors.red)
    );
    if (deviceData.supportBle) {
      infoData.addAll(_getBleInfo());
    }

    infoData.add(
        _infoBox("Support WlanP2P", deviceData.supportWlanP2p.toString(),
            contentColor:
            deviceData.supportWlanP2p ? Colors.green : Colors.red));
    if (deviceData.supportWlanP2p) {
      infoData.addAll(_getWlanP2pInfo());
    }

    infoData.add(_infoBox("Support Lan", deviceData.supportLan.toString(),
        contentColor: deviceData.supportLan ? Colors.green : Colors.red));
    if (deviceData.supportLan) {
      infoData.addAll(_getLanInfo());
    }

    final server = WebsocketServer();


    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: infoData,
        ));
  }
}
