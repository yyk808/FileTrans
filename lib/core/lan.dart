import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:file_trans_rework/common/websocket.dart';
import 'package:get/get.dart';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../common/permission.dart';
import 'base.dart';

class BonsoirNeighbor {
  BonsoirNeighbor({
    required this.name,
    required this.ip,
    required this.port,
    required this.service,
    this.attributes,
  });

  final String name;
  final String ip;
  final int port;
  final String service;
  final Map<String, String>? attributes;
  late final String id = "$name:$ip:$port:$service";
}

final _log = Logger("Lan");

class LocalAreaConnectivityAdapter
    implements AdapterAbstractionBase, CanBroadcast<ResolvedBonsoirService>, CanTransfer<ResolvedBonsoirService> {
  static final LocalAreaConnectivityAdapter _singleton =
  LocalAreaConnectivityAdapter._internal();
  LocalAreaConnectivityAdapter._internal();
  factory LocalAreaConnectivityAdapter() => _singleton;

  @override
  final ConnectivityAdapterTypes type = ConnectivityAdapterTypes.LAN;
  @override
  final ConnectionType connectionType = ConnectionType.hb;
  @override
  final List<Permission> permissions = [];

  @override
  bool isInitialized = false;

  @override
  RxBool connected = false.obs;

  @override
  RxBool isBroadcasting = false.obs;

  @override
  RxBool isScanning = false.obs;

  @override
  RxList<ResolvedBonsoirService> scanResults = <ResolvedBonsoirService>[].obs;

  // true if hardware supports and permissions acquired
  @override
  RxBool isAvailable = false.obs;

  @override
  Rx<ConnectionState> connectionState = ConnectionState.Unknown.obs;

  @override
  Rx<TransferState> transferState = TransferState.Unknown.obs;

  WebsocketServer? _server;

  (BonsoirBroadcast, Timer)? _broadcast;
  (BonsoirDiscovery, Timer)? _discovery;

  StreamSubscription? _discoveryEventSubscription;

  // configs
  static const String bonsoirType = '_ft._tcp';
  final BonsoirService serviceData = BonsoirService(
    name: 'File Trans Broadcast',
    // Put your service name here.
    type: bonsoirType,
    // Put your service type here. Syntax : _ServiceType._TransportProtocolName. (see http://wiki.ros.org/zeroconf/Tutorials/Understanding%20Zeroconf%20Service%20Types).
    port: 4044, // TODO: randomize
    // Put your service port here.
    attributes: {'tbNail': '$fingerPrint', 'nickName': nickName}
  );

  // can be called if available
  @override
  Future<bool> turnOn() async => false;

  @override
  Future<bool> turnOff() async => false;

  @override
  Future<void> initialize() async {
    if(!isInitialized) {
      checkPermissions(this);
      _server = WebsocketServer();
      isInitialized = true;
    }
  }

  @override
  Future<bool> hardConnect(BonsoirService result) async {
    if (isAvailable.isTrue) {
      connected.value = (true);
      return true;
    } else {
      connected.value = (false);
      return false;
    }
  }

  @override
  Future<bool> hardDisconnect(BonsoirService result) async {
    connected.value = (false);
    return true;
  }

  @override
  Future<bool> startBroadcast(int duration) async {
    if (isBroadcasting.isFalse) {
      isBroadcasting.value = true;
      // mutex?
      final broadcast = BonsoirBroadcast(service: serviceData);
      await broadcast.ready;
      await broadcast.start();
      isBroadcasting.value = (true);

      final timer = Timer.periodic(duration.seconds, (timer) async {
        stopBroadcast();
        timer.cancel();
      });

      _broadcast = (broadcast, timer);
    }
    return true;
  }

  @override
  Future<bool> startScan(int duration) async {
    if (_discovery == null) {
      final discovery = BonsoirDiscovery(type: bonsoirType);
      await discovery.ready;
      await discovery.start();
      isScanning.value = (true);

      final timer = Timer.periodic(duration.seconds, (timer) async {
        timer.cancel();
        stopScan();
      });

      _discovery = (discovery, timer);

      _discoveryEventSubscription = discovery.eventStream!.listen((event) {
        if (event.service == null) {
          return;
        }

        BonsoirService service = event.service!;
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          service.resolve(discovery.serviceResolver);
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceResolved) {
          try {
            if(int.parse(service.attributes["tbNail"]!) != fingerPrint) {
              scanResults.add(service as ResolvedBonsoirService);
            } else {
              _log.info("Filter out self: ${int.parse(service.attributes["tbNail"]!)},$fingerPrint");
            }
          } catch(e) {
            return;
          }
          // scanResults.add(service as ResolvedBonsoirService);
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceLost) {
          scanResults
              .removeWhere((foundService) => foundService.name == service.name);
        }
      });
    }
    return true;
  }

  @override
  Future<bool> stopBroadcast() async {
    isBroadcasting.value = false;
    await _broadcast?.$1.stop();
    _broadcast?.$2.cancel();
    _broadcast = null;
    return true;
  }

  @override
  Future<bool> stopScan() async {
    scanResults.clear();
    await _discoveryEventSubscription?.cancel();
    await _discovery?.$1.stop();
    _discovery?.$2.cancel();

    _discoveryEventSubscription = null;
    _discovery = null;

    return true;
  }

  @override
  Future<bool> softConnect(PeerData result) async {
    if(!result.supportLan || connected.isTrue) {
      return false;
    }

    final address = result.ipAddr!;
    final res = await _server!.connectToSocket(
        address: address,
        downloadPath: "/storage/emulated/0/Download/",
        onConnect: (name) {
          showToastSuccess("Scoket Connected to $name $address");
          print("Scoket Connected to $name $address");
        },
        transferUpdate: (transfer) {
          if(transfer.completed) {
            showToastSuccess("Transfer completed 1");
          }

          print("Bytes transfered: ${transfer.count}");
          print("Total bytes: ${transfer.total}");
        },
        receiveString: (str) {
          showToastSuccess("Receive String: $str");
          print("String received: $str");
        });
    connected.value = res;
    return res;
  }

  @override
  Future<bool> softDisconnect(PeerData result) async {
    stopListen();
    connected.value = false;
    return true;
  }

  @override
  Future<bool> listen() async {
    await stopListen();

    return _server!.startSocket(
      address: "0.0.0.0",
      onConnect: (name, address) {
        showToastSuccess("Connected by $name $address");
        print("Connected by $name $address");
      },
      transferUpdate: (TransferUpdate transfer) {
        if(transfer.completed) {
          showToastSuccess("Transfer completed 2");
        }

        print("Bytes transfered: ${transfer.count}");
        print("Total bytes: ${transfer.total}");
      },
      receiveString: (req) {
        showToastSuccess("String received: $req");
        print("String received: $req");
      },
      deleteOnError: true,
      downloadPath: "/storage/emulated/0/Download/",
      maxConcurrentDownloads: 2,
    );
  }

  @override
  Future<bool> stopListen() async {
    _server?.closeSocket();
    // _server = null;

    return true;
  }

  @override
  Future<bool> transferBlockData(PeerData target, String data, bool isPath) async {
    if(_server == null || !target.supportLan) {
      return false;
    }

    try {
      if(isPath) {
        final res = (await _server!.sendFiletoSocket([data]))?[0];
        if(res != null) {
          showToastInfo("File sent: ${!res.failed}");
          _log.info("File sent: ${!res.failed}");
        }
      } else {
        _server!.sendStringToSocket(data);
      }
    } catch(e) {
      _log.info("Failed to send: ${e.toString()}");
      return false;
    }

    return true;
  }

  @override
  Future<PeerData> sayHello(ResolvedBonsoirService target) async {
    return PeerData(unifiedId: int.parse(target.attributes["tbNail"]!), nickName: target.attributes["nickName"]!, deviceName: target.name, supportLan: true, ipAddr: target.host!);
  }
}

// class LocalAreaConnectivityAdapter
//     extends AdapterAbstractionBase<BonsoirService> {
//   @override
//   Set<String> abilities = {};
//   @override
//   late final ConnectivityAdapterTypes type;
//
//   @override
//   late String broadcastingType;
//
//   @override
//   late final StreamProvider<List<BonsoirService>> scanResults;
//   @override
//   late final StreamProvider<bool> isScanning;
//
//   late final StreamProvider<bool> isBroadcasting;
//
//   late final StreamProvider<BonsoirBroadcastEvent> broadcastEventProvider;
//   late final BonsoirBroadcast broadcast;
//   late final BonsoirDiscovery discovery;
//   final _server = WebsocketServer();
//
//   bool _isScanning = false;
//   bool _isBroadcasting = false;
//   bool _shouldUpdateScan = false;
//   bool _shouldUpdateBroadcast = false;
//   late final StreamController<bool> _scanStateController;
//   late final StreamController<bool> _broadcastStateController;
//
//   @override
//   Future<void> initialize() async {
//     final BonsoirService serviceData = BonsoirService(
//         name: 'My wonderful service',
//         // Put your service name here.
//         type: '_ok._tcp',
//         // Put your service type here. Syntax : _ServiceType._TransportProtocolName. (see http://wiki.ros.org/zeroconf/Tutorials/Understanding%20Zeroconf%20Service%20Types).
//         port: 4045,
//         // Put your service port here.
//         attributes: {'os': 'android', 'name': 'name'});
//     String type = '_ok._tcp';
//
//     broadcast = BonsoirBroadcast(service: serviceData);
//     discovery = BonsoirDiscovery(type: type);
//     await broadcast.ready;
//     await discovery.ready;
//
//     // filter out yourself
//     scanResults = StreamProvider((ref) async* {
//       List<BonsoirService> services = [];
//       await for (final event in discovery.eventStream!) {
//         if (event.service == null) {
//           continue;
//         }
//         BonsoirService service = event.service!;
//         if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
//           services.add(service);
//           service.resolve(discovery.serviceResolver);
//         } else if (event.type ==
//             BonsoirDiscoveryEventType.discoveryServiceResolved) {
//           services
//               .removeWhere((foundService) => foundService.name == service.name);
//           services.add(service);
//         } else if (event.type ==
//             BonsoirDiscoveryEventType.discoveryServiceLost) {
//           services
//               .removeWhere((foundService) => foundService.name == service.name);
//         }
//         // services.sort((a, b) => a.name.compareTo(b.name));
//         yield services;
//       }
//     });
//     broadcastEventProvider = StreamProvider((ref) async* {
//       await for (final event in broadcast.eventStream!) {
//         yield event;
//       }
//     });
//
//     _scanStateController = StreamController<bool>(
//       onListen: () => _shouldUpdateScan = true,
//       onCancel: () => _shouldUpdateScan = false,
//     );
//     _broadcastStateController = StreamController<bool>(
//       onListen: () => _shouldUpdateBroadcast = true,
//       onCancel: () => _shouldUpdateBroadcast = false,
//     );
//
//     isScanning = StreamProvider((ref) async* {
//       await for (final event in _scanStateController.stream) {
//         yield event;
//       }
//     });
//     isBroadcasting = StreamProvider((ref) async* {
//       await for (final event in _broadcastStateController.stream) {
//         yield event;
//       }
//     });
//   }
//
//   @override
//   Future<bool> turnOn() async => true;
//
//   @override
//   Future<bool> turnOff() async => true;
//
//   @override
//   Future<bool> startScan() async {
//     await discovery.start();
//     _isScanning = true;
//     if (_shouldUpdateScan) {
//       _scanStateController.add(_isScanning);
//     }
//     return true;
//   }
//
//   @override
//   Future<bool> stopScan() async {
//     await discovery.stop();
//     _isScanning = false;
//     if (_shouldUpdateScan) {
//       _scanStateController.add(_isScanning);
//     }
//     return true;
//   }
//
//   @override
//   Future<bool> connect(BonsoirService result) async {
//     if (result is! ResolvedBonsoirService) {
//       print("Not been resolved");
//       return false;
//     }
//     final address = (result).host!;
//
//     return await _server.connectToSocket(
//         address: address,
//         downloadPath: "/storage/emulated/0/Download/",
//         onConnect: (name) {
//           print("Scoket Connected to $name $address");
//         },
//         transferUpdate: (transfer) {
//           print("Bytes transfered: ${transfer.count}");
//           print("Total bytes: ${transfer.total}");
//         },
//         receiveString: (str) {
//           print("String received: $str");
//         });
//   }
//
//   @override
//   Future<bool> disconnect(BonsoirService result) async {
//     return _server.closeSocket();
//   }
//
//   @override
//   Future<bool> startBroadcast() async {
//     await broadcast.start();
//     _isBroadcasting = true;
//     if (_shouldUpdateBroadcast) {
//       _broadcastStateController.add(_isBroadcasting);
//     }
//     return true;
//   }
//
//   @override
//   Future<bool> stopBroadcast() async {
//     await broadcast.stop();
//     _isBroadcasting = false;
//     if (_shouldUpdateBroadcast) {
//       _broadcastStateController.add(_isBroadcasting);
//     }
//     return true;
//   }
//
//   @override
//   Future<bool> listen() async {
//     return _server.startSocket(
//       address: "0.0.0.0",
//       onConnect: (name, address) {
//         print("Connected to $name $address");
//       },
//       transferUpdate: (TransferUpdate transfer) {
//         print("Bytes transfered: ${transfer.count}");
//         print("Total bytes: ${transfer.total}");
//       },
//       receiveString: (req) {
//         showToastInfo("received: $req");
//         print("String received: $req");
//       },
//       deleteOnError: true,
//       downloadPath: "/storage/emulated/0/Download/",
//       maxConcurrentDownloads: 2,
//     );
//   }
//
//   @override
//   Future<bool> stopListen() async {
//     _server.closeSocket();
//     return true;
//   }
//
//   @override
//   Future<bool> transferData(BonsoirService target, String data) async {
//     _server.sendStringToSocket("Ok, lan adapter works.");
//     return true;
//   }
// }
