import 'package:file_trans_rework/common/global.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/base.dart';

final _log = Logger("Permission");

Future<bool> checkPermissions(AdapterAbstractionBase adapter) async {
  if (adapter.permissions.isNotEmpty) {
    final Map<Permission, PermissionStatus> statuses = await adapter.permissions.request();
    _log.info('status: $statuses');
  }
  return true;
}