import 'package:fluttertoast/fluttertoast.dart';

import '../wigets/toast_body.dart';

void showToastSuccess(String msg) {
  final t = FToast();
  t.removeCustomToast();
  t.showToast(child: SuccessToastBody(msg: msg));
}

void showToastInfo(String msg) {
  final t = FToast();
  t.removeCustomToast();
  t.showToast(child: InfoToastBody(msg: msg));
}

void showToastError(String msg) {
  final t = FToast();
  t.removeCustomToast();
  t.showToast(child: ErrorToastBody(msg: msg));
}
