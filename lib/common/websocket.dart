import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_trans_rework/common/saved_files.dart';
import 'package:file_trans_rework/common/toast.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:mime_type/mime_type.dart';

import 'package:dio/dio.dart';

class WebsocketServer {
  static final WebsocketServer _singleton = WebsocketServer._internal();
  WebsocketServer._internal();
  factory WebsocketServer() => _singleton;

  final int _port = 4044;
  final int _code = 4044;
  int _maxDownloads = 2;
  final String _fileTransferCode = "~~&&^^>><<{|MeSsAgEs|}>><<^^&&~~";
  final String _fileSizeSeperation =
      "~~&&^^>><<{|FiLeSiZeSePeRaTiOn|}>><<^^&&~~";
  final String _groupSeparation = "~~&&^^>><<{||||}>><<^^&&~~";
  final String _andSymbol = "%4AA5%";
  final String _equalsSymbol = "%6EE7%";
  final String _questionSymbol = "%8QQ9%";
  final List<WebSocket?> _sockets = [];
  final List<FutureDownload> _futureDownloads = [];
  final Dio _dio = Dio();
  bool _deleteOnError = false;
  String _ipAddress = '';
  String _as = '';
  HttpServer? _server;

  bool running = false;
  bool connected = false;

  Future<bool> startSocket({
    required String address,
    required String downloadPath,
    int maxConcurrentDownloads = 2,
    bool deleteOnError = true,
    required void Function(String name, String address) onConnect,
    required void Function(TransferUpdate transfer) transferUpdate,
    required void Function(dynamic req) receiveString,
  }) async {
    if (address.isEmpty) return false;
    try {
      closeSocket(notify: false);
      _maxDownloads = maxConcurrentDownloads;
      _deleteOnError = deleteOnError;
      address = address.replaceFirst("/", "");
      _ipAddress = address;
      HttpServer httpServer = await HttpServer.bind(
        address,
        _port,
        shared: true,
      );
      httpServer.listen(
            (req) async {
          if (req.uri.path == '/ws') {
            WebSocket socketServer = await WebSocketTransformer.upgrade(req);
            _sockets.add(socketServer);
            socketServer.listen(
                  (event) async {
                // SHARE TO CLIENTS
                for (WebSocket? socket in _sockets) {
                  if (socket != null) {
                    socket.add(event);
                  }
                }
                if (event.toString().startsWith(_fileTransferCode)) {
                  // ADD TO FUTURE DOWNLOADS
                  for (String msg in event.toString().split(_groupSeparation)) {
                    String url = msg.toString().split(_fileSizeSeperation).last;
                    int size = int.tryParse(msg
                        .toString()
                        .replaceFirst(_fileTransferCode, "")
                        .split(_fileSizeSeperation)
                        .first) ??
                        0;
                    int id = int.tryParse(url.split("&id=").last) ??
                        Random().nextInt(10000);
                    String filename = await _setName(
                        url
                            .split("/")
                            .last
                            .replaceFirst("&id=${url.split("&id=").last}", ""),
                        downloadPath);
                    String path = "$downloadPath$filename";
                    CancelToken token = CancelToken();

                    // UPDATE TRANSFER
                    transferUpdate(
                      TransferUpdate(
                        filename: filename,
                        path: path,
                        count: 0,
                        total: size,
                        completed: false,
                        failed: false,
                        receiving: true,
                        id: id,
                        cancelToken: token,
                      ),
                    );
                    // ADD TO FUTURES
                    _futureDownloads.add(
                      FutureDownload(
                        url: url,
                        downloading: false,
                        id: id,
                        filename: filename,
                        path: path,
                        cancelToken: token,
                      ),
                    );
                  }
                } else {
                  // RECEIVE MESSAGE
                  receiveString(event
                      .toString()
                      .substring(event.toString().indexOf('@') + 1));
                }
              },
              cancelOnError: true,
              onDone: () {
                print(
                    "Websocket: A Device Disconnected from Socket!");
                socketServer.close(_code);
                _sockets.removeWhere(
                        (e) => e == null ? true : e.closeCode == _code);
              },
            );
            onConnect("${req.uri.queryParameters['as']}",
                "${req.uri.queryParameters['ip']}:$_port");
            print(req.uri.queryParametersAll);
            print(
                "Websocket: ${req.uri.queryParameters['as']} connected to Socket!");

            // HANDLE FILE REQUEST
          } else if (req.uri.path == '/file' && req.uri.hasQuery) {
            _handleFileRequest(req, transferUpdate);
          }
        },
        cancelOnError: true,
        onError: (error, stack) {},
        onDone: () {
          closeSocket();
        },
      );
      _server = httpServer;
      running = true;
      print("Websocket: Opened a Socket!");
      _listenThenDownload(transferUpdate, downloadPath);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connectToSocket({
    required String address,
    String? as,
    int maxConcurrentDownloads = 2,
    bool deleteOnError = true,
    required String downloadPath,
    required void Function(String address) onConnect,
    required void Function(TransferUpdate transfer) transferUpdate,
    required void Function(dynamic req) receiveString,
  }) async {
    if (address.isEmpty || connected) return false;
    try {
      closeSocket(notify: false);
      _maxDownloads = maxConcurrentDownloads;
      _deleteOnError = deleteOnError;
      _ipAddress = "0.0.0.0";
      // _as = as ??
      //     await WebsocketPlatform.instance.getPlatformModel() ??
      //     (Random().nextInt(5000) + 1000).toString();
      if (address.isNotEmpty) {
        address = address.replaceFirst("/", "");
        HttpServer httpServer = await HttpServer.bind(
          _ipAddress,
          _port,
          shared: true,
        );
        httpServer.listen(
              (req) async {
            // HANDLE FILE REQUEST
            if (req.uri.path == '/file' && req.uri.hasQuery) {
              _handleFileRequest(req, transferUpdate);
            }
          },
          cancelOnError: true,
          onError: (error, stack) {},
          onDone: () {
            closeSocket();
          },
        );
        _server = httpServer;
        WebSocket socket = await WebSocket.connect(
            'ws://$address:$_port/ws?as=$_as&ip=$_ipAddress');
        _sockets.add(socket);
        print(
            "Websocket: Connected to Socket: $address:$_port");
        socket.listen(
              (event) async {
            if (event.toString().startsWith(_fileTransferCode)) {
              // ADD TO FUTURE DOWNLOADS
              for (String msg in event.toString().split(_groupSeparation)) {
                String url = msg.toString().split(_fileSizeSeperation).last;
                int size = int.tryParse(msg
                    .toString()
                    .replaceFirst(_fileTransferCode, "")
                    .split(_fileSizeSeperation)
                    .first) ??
                    0;
                if (!(url.startsWith("http://$_ipAddress:$_port/"))) {
                  int id = int.tryParse(url.split("&id=").last) ??
                      Random().nextInt(10000);
                  String filename = await _setName(
                      url
                          .split("/")
                          .last
                          .replaceFirst("&id=${url.split("&id=").last}", ""),
                      downloadPath);
                  String path = "$downloadPath$filename";
                  CancelToken token = CancelToken();

                  // UPDATE TRANSFER
                  transferUpdate(
                    TransferUpdate(
                      filename: filename,
                      path: path,
                      count: 0,
                      total: size,
                      completed: false,
                      failed: false,
                      receiving: true,
                      id: id,
                      cancelToken: token,
                    ),
                  );
                  // ADD TO FUTURES
                  _futureDownloads.add(
                    FutureDownload(
                      url: url,
                      downloading: false,
                      id: id,
                      filename: filename,
                      path: path,
                      cancelToken: token,
                    ),
                  );
                }
              }
            } else if (event.toString().split("@").first !=
                _ipAddress.split(".").last) {
              // RECEIVE MESSGAE
              receiveString(event
                  .toString()
                  .substring(event.toString().indexOf('@') + 1));
            }
          },
          cancelOnError: true,
          onDone: () {
            closeSocket();
          },
        );
        onConnect("$address:$_port");
        _listenThenDownload(transferUpdate, downloadPath);

        connected = true;
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  void _listenThenDownload(
      void Function(TransferUpdate) transferUpdate,
      String downloadPath,
      ) async {
    while (_server != null) {
      await Future.delayed(const Duration(seconds: 1));
      if (_futureDownloads.isNotEmpty) {
        if (_futureDownloads.where((i) => i.downloading == true).isEmpty) {
          if (_futureDownloads.length <= _maxDownloads) {
            List<Future> futures = [];

            //ADD TO FUTURES
            for (int i = 0; i < _futureDownloads.length; i++) {
              _futureDownloads[i].downloading = true;
              futures.add(
                Future(
                      () async {
                    FutureDownload download = _futureDownloads[i];
                    await _downloadFile(
                      url: download.url,
                      transferUpdate: transferUpdate,
                      downloadPath: downloadPath,
                      done: () {
                        _futureDownloads
                            .removeWhere((i) => i.id == download.id);
                      },
                      filename: download.filename,
                      id: download.id,
                      path: download.path,
                      token: download.cancelToken,
                    );
                    return true;
                  },
                ),
              );
            }
            // RUN FUTURES
            await Future.wait(futures);
          } else {
            List<Future> futures = [];

            //ADD TO FUTURES
            for (int i = 0; i < _maxDownloads; i++) {
              _futureDownloads[i].downloading = true;
              futures.add(
                Future(
                      () async {
                    FutureDownload download = _futureDownloads[i];
                    await _downloadFile(
                      url: download.url,
                      transferUpdate: transferUpdate,
                      downloadPath: downloadPath,
                      done: () {
                        _futureDownloads
                            .removeWhere((i) => i.id == download.id);
                      },
                      filename: download.filename,
                      id: download.id,
                      path: download.path,
                      token: download.cancelToken,
                    );
                    return true;
                  },
                ),
              );
            }
            //RUN FUTURES
            await Future.wait(futures);
          }
        }
      }
    }
  }

  Future _handleFileRequest(
      HttpRequest req,
      void Function(TransferUpdate) transferUpdate,
      ) async {
    String cancel = req.uri.queryParameters['cancel'] ?? "";
    String path = (req.uri.queryParameters['path'] ?? "")
        .replaceAll(_andSymbol, "&")
        .replaceAll(_equalsSymbol, "=")
        .replaceAll(_questionSymbol, "?");
    int id = int.tryParse(req.uri.queryParameters['id'] ?? "0") ?? 0;
    File? file;
    List m = (mime(path.split("/").last) ?? "text/plain").split("/");
    String filename = path.split("/").last;
    int count = 0;
    try {
      file = File(path);
      if (cancel == "true") {
        req.response
          ..write("cancelled")
          ..close();
        transferUpdate(
          TransferUpdate(
            filename: filename,
            path: path,
            count: count,
            total: await file.length(),
            completed: true,
            failed: true,
            receiving: false,
            id: id,
            cancelToken: null,
          ),
        );
        print("<<<<<<<<< CANCELLED >>>>>>>>> $path");
        return;
      }
      if (path.isEmpty) {
        req.response
          ..addError(const HttpException("not found"))
          ..close();
        transferUpdate(
          TransferUpdate(
            filename: filename,
            path: path,
            count: count,
            total: await file.length(),
            completed: true,
            failed: true,
            receiving: false,
            id: id,
            cancelToken: null,
          ),
        );
      } else {
        print("<<<<<<<<< SENDING >>>>>>>>> $path");
        req.response
          ..headers.contentType = ContentType(m.first, m.last)
          ..headers.contentLength = await file.length()
          ..addStream(
            _fileStream(
              file: file,
              filename: filename,
              id: id,
              transferUpdate: transferUpdate,
              updateCount: (c) => count = c,
            ),
          ).whenComplete(() async {
            req.response.close();
            transferUpdate(
              TransferUpdate(
                filename: filename,
                path: path,
                count: count,
                total: file == null ? 0 : await file.length(),
                completed: true,
                failed: count == (file == null ? 0 : await file.length())
                    ? false
                    : true,
                receiving: false,
                id: id,
                cancelToken: null,
              ),
            );
          });
      }
    } catch (_) {
      req.response
        ..addError(const HttpException("not found"))
        ..close();
      transferUpdate(
        TransferUpdate(
          filename: filename,
          path: path,
          count: count,
          total: file == null ? 0 : await file.length(),
          completed: true,
          failed: true,
          receiving: false,
          id: id,
          cancelToken: null,
        ),
      );
    }
  }

  Stream<List<int>> _fileStream({
    required File file,
    required String filename,
    required int id,
    required void Function(TransferUpdate) transferUpdate,
    required void Function(int) updateCount,
  }) async* {
    int total = await file.length();
    int count = 0;
    try {
      await for (List<int> chip in file.openRead()) {
        count += (chip as Uint8List).lengthInBytes;
        updateCount(count);
        //update transfer
        transferUpdate(
          TransferUpdate(
            filename: filename,
            path: file.path,
            count: count,
            total: total,
            completed: false,
            failed: false,
            receiving: false,
            id: id,
            cancelToken: null,
          ),
        );
        yield chip;
        if (count == total) break;
      }
    } catch(e) {
      showToastError("fstream error: ${e.toString()}");
      print("fstream error: ${e.toString()}");
    }

  }

  Future _downloadFile({
    required String url,
    required void Function(TransferUpdate) transferUpdate,
    required String downloadPath,
    required void Function() done,
    required String filename,
    required String path,
    required int id,
    required CancelToken token,
  }) async {
    if (url.startsWith("http://$_ipAddress:$_port/")) {
      done();
      return;
    }
    if (token.isCancelled == true) {
      transferUpdate(
        TransferUpdate(
          filename: filename,
          path: path,
          count: 0,
          total: 0,
          completed: true,
          failed: true,
          receiving: true,
          id: id,
          cancelToken: token,
        ),
      );

      // send cancelled request
      await _dio.getUri(Uri.parse("$url&cancel=true"));
      print("<<<<<<<<< CANCELLED >>>>>>>>> $path");
      done();
      return;
    }
    int count = 0;
    int total = 0;
    bool failed = false;
    try {
      print("<<<<<<<<< RECEIVING >>>>>>>>> $path");
      showToastInfo("Receiving files...");
      _dio.download(
        "$url&cancel=false",
        path,
        deleteOnError: _deleteOnError,
        cancelToken: token,
        onReceiveProgress: (c, t) {
          count = c;
          total = t;
          transferUpdate(
            TransferUpdate(
              filename: filename,
              path: path,
              count: count,
              total: total,
              completed: false,
              failed: false,
              receiving: true,
              id: id,
              cancelToken: token,
            ),
          );
        },
      )
        ..onError((err, stack) async {
          failed = true;
          showToastError("Failed to receive file");
          Future.delayed(
            const Duration(milliseconds: 500),
                () async {
              if (_deleteOnError == true) {
                if (await File(path).exists()) File(path).delete();
              }
            },
          );
          return Future.value(
              Response(requestOptions: RequestOptions(path: url)));
        })
        ..whenComplete(
              () {
                final files = SavedFiles();
                files.insertFile(filename, path);
            transferUpdate(
              TransferUpdate(
                filename: filename,
                path: path,
                count: count,
                total: total,
                completed: true,
                failed: failed,
                receiving: true,
                id: id,
                cancelToken: token,
              ),
            );
            done();
          },
        );
    } catch (_) {
      transferUpdate(
        TransferUpdate(
          filename: filename,
          path: path,
          count: count,
          total: total,
          completed: true,
          failed: true,
          receiving: true,
          id: id,
          cancelToken: token,
        ),
      );
      done();
    }
  }

  Future<String> _setName(String name, String path) async {
    try {
      if (!(await File(path + name).exists())) return name;
      int number = 1;
      int index = name.lastIndexOf(".");
      String ext = name.substring(index.isNegative ? name.length : index);
      while (true) {
        String newName = name.replaceFirst(ext, "($number)$ext");
        if (!(await File(path + newName).exists())) {
          await File(path + newName).create();
          return newName;
        }
        number++;
      }
    } catch (_) {
      return name;
    }
  }

  bool sendStringToSocket(String string) {
    try {
      for (WebSocket? socket in _sockets) {
        if (socket != null) {
          socket.add("${_ipAddress.split(".").last}@$string");
        }
      }
      return true;
    } catch (e) {
      print("Websocket: Tranfer error: $e");
      return false;
    }
  }

  Future<List<TransferUpdate>?> sendFiletoSocket(List<String> paths) async {
    try {
      // if (_ipAddress.isEmpty) return null;
      paths = paths.where((path) => (File(path).existsSync()) == true).toList();
      _ipAddress = (await FlutterP2pConnection().getIPAddress())!;

      // CREATE IDS
      List<int> ids = [];
      for (var _ in paths) {
        ids.add(Random().nextInt(1000000000));
      }

      // SEND TO SOCKETS
      for (WebSocket? socket in _sockets) {
        if (socket != null) {
          String msg = '';
          for (int i = 0; i < paths.length; i++) {
            var size = await File(paths[i]).length();
            msg +=
            "$_fileTransferCode$size${_fileSizeSeperation}http://$_ipAddress:$_port/file?path=${paths[i].replaceAll("&", _andSymbol).replaceAll("=", _equalsSymbol).replaceAll("?", _questionSymbol)}&id=${ids[i]}";
            if (i < paths.length - 1) msg += _groupSeparation;
          }
          print("Token sent: $msg");
          socket.add(msg);
        }
      }

      // UPDATE TRANSFERS
      List<TransferUpdate> updates = [];
      for (int i = 0; i < paths.length; i++) {
        String filename = paths[i].split("/").last;
        updates.add(
          TransferUpdate(
            filename: filename,
            path: paths[i],
            count: 0,
            total: await File(paths[i]).length(),
            completed: false,
            failed: false,
            receiving: false,
            id: ids[i],
            cancelToken: null,
          ),
        );
      }
      return updates;
    } catch (e) {
      print("Websocket: Tranfer error: $e");
      return null;
    }
  }

  bool closeSocket({bool notify = true}) {
    try {
      if (_server != null) _server?.close();
      for (WebSocket? socket in _sockets) {
        if (socket != null) {
          socket.close(_code);
        }
      }
      _server = null;
      _sockets.clear();
      _futureDownloads.clear();
      _ipAddress = '';
      _as = '';
      running = false;
      connected = false;

      if (notify == true) print("Websocket: Closed Socket!");
      return true;
    } catch (_) {
      return false;
    }
  }
}

class TransferUpdate {
  final String filename;
  final String path;
  final int count;
  final int total;
  final bool completed;
  final bool failed;
  final bool receiving;
  final int id;
  final CancelToken? cancelToken;
  TransferUpdate({
    required this.filename,
    required this.path,
    required this.count,
    required this.total,
    required this.completed,
    required this.failed,
    required this.receiving,
    required this.id,
    required this.cancelToken,
  });
}

class FutureDownload {
  String url;
  bool downloading;
  int id;
  final String filename;
  final String path;
  final CancelToken cancelToken;
  FutureDownload({
    required this.url,
    required this.downloading,
    required this.id,
    required this.filename,
    required this.path,
    required this.cancelToken,
  });
}