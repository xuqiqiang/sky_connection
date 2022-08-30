import 'dart:convert';
import 'dart:io';

import '../utils/utils.dart';
import 'beans.dart';
import 'websocket_utils.dart';

abstract class ServerListener {
  void onServerStart();

  void onClientChanged(List<ClientInfo> clients);

  void onMessage(WebSocket webSocket, WSMessage message);

  void onServerError({error});

  void onHttpRequest(HttpRequest request);
}

class WSServer extends _WSServer<ClientInfo> {
  static const tag = "WSServer";
  final Map<WebSocket, ClientInfo> _clients = {};
  final ServerInfo serverInfo;
  ServerListener? _listener;
  WSConnectionType? _type;

  WSServer({required this.serverInfo});

  void start(WSConnectionType type, {ServerListener? listener}) {
    stop();
    _type = type;
    _listener = listener;
    _start(getPort(type));
  }

  @override
  void stop() {
    _listener = null;
    for (WebSocket client in _clients.keys) {
      client.close();
    }
    _clients.clear();
    super.stop();
  }

  Future<String?> fileUrl(String filePath) async {
    if (_type == null) return null;
    String? ip = await getIntranetIp();
    if (ip == null) return null;
    return "http://$ip:${getPort(_type!)}/file?path=${encBase64(filePath)}";
  }

  int get clientCount => _clients.length;

  ClientInfo? getClientInfo(WebSocket webSocket) => _clients[webSocket];

  WebSocket? getWebSocket(ClientInfo clientInfo) {
    for (var e in _clients.entries) {
      if (e.value == clientInfo) return e.key;
    }
    return null;
  }

  void send(WebSocket webSocket, WSMessage message) {
    _send(webSocket, jsonEncode(message));
  }

  void broadcast(WSMessage message) {
    _broadcast(jsonEncode(message));
  }

  void disconnect(WebSocket webSocket) {
    _clients.remove(webSocket);
    webSocket.close();
    if (_listener != null) {
      _listener!.onClientChanged(_clients.values.toList());
    }
  }

  @override
  _onStart() {
    if (_listener != null) {
      _listener!.onServerStart();
    }
  }

  @override
  ClientInfo? _onHandshake(HttpRequest request) {
    if (!checkAuth(request)) return null;
    Map param = request.uri.queryParameters;
    String? model = param['model'];
    String? sn = param['sn'];
    if (model == null || sn == null) return null;
    return ClientInfo(model: model, sn: sn, extra: param['extra']);
  }

  @override
  _onConnected(WebSocket webSocket, ClientInfo client) {
    _clients[webSocket] = client;
    if (_listener != null) {
      _listener!.onClientChanged(_clients.values.toList());
    }
    send(webSocket,
        WSMessage(code: wsMsgConnected, data: jsonEncode(serverInfo)));
  }

  @override
  _onDisconnected(WebSocket webSocket, {error}) {
    log('onDisconnected ${_clients[webSocket]} $error', tag: tag);
    _clients.remove(webSocket);
    if (_listener != null) {
      _listener!.onClientChanged(_clients.values.toList());
    }
  }

  @override
  _onReceive(WebSocket webSocket, /*String|List<int>*/ data) {
    WSMessage message = WSMessage.fromJson(jsonDecode(data));
    if (_listener != null) {
      _listener!.onMessage(webSocket, message);
    }
  }

  @override
  _onError(error) {
    if (_listener != null) {
      _listener!.onServerError(error: error);
    }
  }

  @override
  _onHttpRequest(HttpRequest request) {
    super._onHttpRequest(request);
    if (_listener != null) {
      _listener!.onHttpRequest(request);
    }
  }

  void _broadcast(/*String|List<int>*/ data) {
    for (WebSocket client in _clients.keys) {
      if (client.readyState == WebSocket.open) {
        _send(client, data);
      }
    }
  }
}

abstract class _WSServer<T> {
  static const tag = "_WSServer";

  HttpServer? server;

  void _send(WebSocket webSocket, /*String|List<int>*/ data) {
    webSocket.add(data);
  }

  _onStart();

  T? _onHandshake(HttpRequest request);

  _onConnected(WebSocket webSocket, T client);

  _onDisconnected(WebSocket webSocket, {error});

  _onReceive(WebSocket webSocket, /*String|List<int>*/ data);

  _onError(error);

  _onHttpRequest(HttpRequest request) {
    List<String> pathSegments = request.uri.pathSegments;
    if (pathSegments.isNotEmpty && pathSegments[0] == 'file') {
      _onRequestFile(request);
    }
  }

  _onRequestFile(HttpRequest request) async {
    Map param = request.uri.queryParameters;
    log('param $param');
    File? file;
    String? path = param["path"];
    if (path != null) {
      path = decBase64(path)!;
      FileSystemEntityType type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.file) {
        file = File(path);
        if (!await file.exists()) {
          file = null;
        }
      }
    }
    sendResponseFile(request, file);
    return;
  }

  void _start(int port) async {
    log('start', tag: tag);
    try {
      server =
          await HttpServer.bind(InternetAddress.anyIPv6, port, shared: true);
    } catch (e) {
      log('bind error $e', tag: tag);
      _onError(e);
      return;
    }
    _onStart();
    server!.listen((HttpRequest request) async {
      log(
          '_ws_ request '
          'uri:${request.uri} \n'
          'uri path:${request.uri.path} \n'
          'uri pathSegments:${request.uri.pathSegments} \n'
          'uri queryParameters:${request.uri.queryParameters} \n'
          'method:${request.method}\n'
          'headers:${request.headers}\n',
          tag: tag);

      setAllowOriginHeader(request);

      List<String> pathSegments = request.uri.pathSegments;
      if (pathSegments.isNotEmpty && pathSegments[0] == 'ws') {
        T? t = _onHandshake(request);
        if (t != null) {
          WebSocket webSocket = await WebSocketTransformer.upgrade(request);
          log('upgrade ${webSocket.readyState}', tag: tag);
          if (webSocket.readyState == WebSocket.open) {
            _onConnected(webSocket, t);
            webSocket.listen((event) {
              _onReceive(webSocket, event);
            }, onError: (error) {
              _onDisconnected(webSocket, error: error);
            }, onDone: () {
              _onDisconnected(webSocket);
            });
          }
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..close();
        }
        return;
      }

      _onHttpRequest(request);
    });
  }

  void stop() {
    if (server != null) {
      server!.close();
    }
    server = null;
  }
}
