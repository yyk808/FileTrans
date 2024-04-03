import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceControlCard extends StatelessWidget {
  const DeviceControlCard({super.key});

  //Container(
  //       alignment: Alignment.center,
  //       margin: EdgeInsets.zero,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(10),
  //         color: Colors.blueGrey,
  //       ),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.start,
  //         children: [
  //           /* ============ Header ============= */
  //           AppBar(
  //             leading: IconButton(
  //               onPressed: () {}, // TODO: add back
  //               icon: const Icon(Icons.cancel_outlined),
  //             ),
  //             title: const Text("Device Control"),
  //             centerTitle: true,
  //             elevation: 0,
  //             backgroundColor: Colors.transparent,
  //             actions: [
  //               IconButton(
  //                 onPressed: () {},
  //                 icon: const Icon(Icons.settings),
  //               )
  //             ],
  //           ),
  //         ],
  //       ),
  //     );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey,
      ),
      child: Column(
        children: [
          /* ============= header ============ */
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: IconButton(
                  onPressed: () => print("knock"),
                  icon: const Icon(Icons.cancel_outlined),
                ),
              ),
              const Text("Device Control", style: TextStyle(
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ],
      ),
    );
  }
}
