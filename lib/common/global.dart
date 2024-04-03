import '../core/base.dart';
import '../core/wlan_p2p.dart';

class Global {
  static Map<ConnectivityAdapterTypes, AdapterAbstractionBase> adapters =
      <ConnectivityAdapterTypes, AdapterAbstractionBase>{};
}
