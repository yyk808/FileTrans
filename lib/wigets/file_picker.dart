import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_trans_rework/common/saved_files.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/control/transfer_controller.dart';
import 'package:file_trans_rework/core/base.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

final _log = Logger("DeviceControl");

class FilePickerItem extends StatelessWidget {
  const FilePickerItem(
      {super.key,
      required this.category,
      required this.icon,
      required this.onPressed});

  final String category;
  final IconData icon;
  final VoidCallback onPressed;

  static const _width = 80.0;
  static const _height = 80.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[100],
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      height: _height,
      width: _width,
      margin: EdgeInsets.only(right: 10),
      child: Stack(fit: StackFit.expand, children: [
        // Column(children: [
        //   const Spacer(),
        //   Flexible(flex: 6, child: Icon(icon, size: 30)),
        //   const Spacer(),
        //   Flexible(flex: 2, child: Text(category)),
        // ]),
        Align(
          alignment: Alignment.bottomCenter,
          child: Text(category,
              style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
        IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 35,
            )),
      ]),
    );
  }
}

class HorizontalFilePicker extends StatelessWidget {
  const HorizontalFilePicker({super.key, required this.peer});

  final PeerData peer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilePickerItem(
            category: "Documents",
            icon: Icons.document_scanner,
            onPressed: () async {
              // try {
              //   FilePickerResult? result = await FilePicker.platform.pickFiles();
              // } on PlatformException catch (e) {
              //   _log.severe("Operation invalid ${e.toString()}");
              // } catch (e) {
              //   _log.severe(e.toString());
              // }
              final controller = TransferController();
              final path = await FilesystemPicker.open(
                  context: context,
                  rootDirectory: Directory("/storage/emulated/0/Download/"));
              if (path == null) {
                showToastError("No path selected");
                return;
              }

              await controller.sendFile(peer, path);
            },
          ),
          FilePickerItem(
            category: "Images",
            icon: Icons.image,
            onPressed: () async {},
          ),
          FilePickerItem(
            category: "Pasteboard",
            icon: Icons.paste,
            onPressed: () async {
              final controller = TransferController();
              const path = "/storage/emulated/0/Download/yscloud_4.2.0.apk";

              controller.sendFile(peer, path);
            },
          ),
          FilePickerItem(
              category: "Test",
              icon: Icons.bug_report_outlined,
              onPressed: () async {
                final controller = TransferController();
                const path = "/storage/emulated/0/Download/Calendar.apk";

                controller.sendFile(peer, path);
              })
        ],
      ),
    );
  }
}
