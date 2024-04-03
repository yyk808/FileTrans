import 'dart:async';

import 'package:file_trans_rework/common/saved_files.dart';
import 'package:file_trans_rework/control/transfer_controller.dart';
import 'package:file_trans_rework/pages/broadcast_screen.dart';
import 'package:file_trans_rework/pages/device_control.dart';
import 'package:file_trans_rework/pages/device_screen.dart';
import 'package:file_trans_rework/pages/test_page.dart';
import 'package:file_trans_rework/wigets/bottom_bar.dart';
import 'package:file_trans_rework/wigets/scan_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/base.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  await registerCore();

  // Database initialize
  final db = SavedFiles();
  await db.initialize();

  // Controller initialize
  final controller = TransferController();
  await controller.initialize();
  controller.startScheduledBroadcast();
  controller.startScan();

  runApp(MaterialApp(
    builder: FToastBuilder(),
    home: const GetMaterialApp(home: FileTrans()),
    navigatorKey: navigatorKey,
  ));
}

class FileTrans extends StatefulWidget {
  const FileTrans({super.key});

  @override
  State<StatefulWidget> createState() => _FileTransState();
}

class _FileTransState extends State<FileTrans> {
  var bottomBarIndex = 0;
  final PageController _controller = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();

    var fToast = FToast();
    fToast.init(navigatorKey.currentContext!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _controller,
        children: [
          DeviceScreen(),
          DeviceControlPage(deviceData: PeerData(
         unifiedId: 12345, nickName: "hhaha", deviceName: "xiaomi")),
          TestPage(),
          // DeviceControlPage(deviceData: PeerData(
          //     unifiedId: 12345, nickName: "hhaha", deviceName: "xiaomi"))
        ],
      ),
      floatingActionButton: bottomBarIndex == 0 ? null : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: bottomBarIndex,
        onTap: (int index) {
          setState(() {
            bottomBarIndex = index;
            _controller.jumpToPage(bottomBarIndex);
          });
        },
        items: bottomNavBarItems(),
      ),
    );
  }
}
