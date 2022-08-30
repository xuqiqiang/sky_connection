import 'dart:convert';
import 'dart:io';

import '../utils/utils.dart';
import 'beans.dart';
import 'websocket_utils.dart';

abstract class ClientListener {
  void onConnected(ServerInfo serverInfo);

  void onMessage(WSMessage message);

  void onDisconnected({error, isConnecting});
}

class WSClient extends _WSClient {
  static const tag = "WSClient";
  ClientListener? _listener;

  void start(WSConnectionType type, String serverIp, ClientInfo clientInfo,
      {ClientListener? listener}) {
    _listener = listener;
    _start('$serverIp:${getPort(type)}', params: {
      'model': clientInfo.model,
      'sn': clientInfo.sn,
      'extra': clientInfo.extra
    },
        headers: createAuthHeaders());
  }

  void send(WSMessage message) {
    _send(jsonEncode(message));
  }

  @override
  _onReceive(/*String|List<int>*/ data) {
    WSMessage message = WSMessage.fromJson(jsonDecode(data));
    log('baseResponse $message');
    if (message.code == wsMsgConnected) {
      ServerInfo serverInfo = ServerInfo.fromJson(jsonDecode(message.data!));
      if (_listener != null) {
        _listener!.onConnected(serverInfo);
      }
    } else {
      if (_listener != null) {
        _listener!.onMessage(message);
      }
    }
  }

  @override
  void _onDisconnected(/*String|List<int>*/ {error, isConnecting}) {
    log('onDisconnected $error', tag: tag);
    if (_listener != null) {
      _listener!.onDisconnected(error: error, isConnecting: isConnecting);
    }
  }
}

abstract class _WSClient {
  static const tag = "_WSClient";
  WebSocket? _client;
  String? _address;

  String createUrl(String address, {Map<String, dynamic>? params}) {
    String url = 'ws://$address/ws';
    if (params != null && params.isNotEmpty) {
      url += '?';
      params.forEach((key, value) {
        if (value.toString().isNotEmpty) url += '$key=$value&';
      });
      url = url.substring(0, url.length - 1);
    }
    log('_start url $url', tag: tag);
    return url;
  }

  void _start(String address,
      {Map<String, dynamic>? params, Map<String, dynamic>? headers}) async {
    try {
      _address = address;
      String url = createUrl(address, params: params);
      HttpClient _httpClient = HttpClient();
      _httpClient.connectionTimeout = const Duration(seconds: 2);
      _httpClient.idleTimeout = const Duration(seconds: 10);
      _client = await WebSocket.connect(url,
          headers: headers, customClient: _httpClient);
      _client!.pingInterval = const Duration(seconds: 3);
      _client!.listen(_onReceive, onDone: () {
        log('onDone', tag: tag);
        _onDisconnected();
        stop();
      }, onError: (error) {
        log('onError', tag: tag);
        _onDisconnected(error: error);
        stop();
      }, cancelOnError: true);
    } catch (e) {
      log('onError', tag: tag);
      _onDisconnected(error: e, isConnecting: true);
    }
  }

  String? get address =>
      _client != null && _client!.readyState == WebSocket.open
          ? _address
          : null;

  void _onReceive(/*String|List<int>*/ data);

  void _onDisconnected({error, isConnecting});

  void _send(/*String|List<int>*/ data) {
    if (_client != null && _client!.readyState == WebSocket.open) {
      _client!.add(data);
    }
  }

  void stop() {
    if (_client != null) {
      _client!.close();
    }
    _client = null;
  }
}
