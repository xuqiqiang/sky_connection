import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sky_connection/sky_connection.dart';
import 'package:sky_connection/utils/utils.dart';
import 'package:sky_connection/websocket/beans.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with ServerListener {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin sky connection'),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              ElevatedButton(
                  child: Text(
                      '${_deviceFindServer != null ? 'Stop' : 'Start'} find server'),
                  onPressed: () => setState(_deviceFindServer != null
                      ? stopDeviceFindServer
                      : startDeviceFindServer)),
              const SizedBox(height: 4),
              ElevatedButton(
                  child: Text(
                      '${_deviceFindClient != null ? 'Stop' : 'Start'} find client'),
                  onPressed: () => setState(_deviceFindClient != null
                      ? stopDeviceFindClient
                      : startDeviceFindClient)),
              const SizedBox(height: 4),
              ElevatedButton(
                child: Text(
                    '${wsServer != null ? 'Stop' : 'Start'} websocket server'),
                onPressed: () =>
                    setState(wsServer != null ? stopWSServer : startWSServer),
              ),
              const SizedBox(height: 4),
              Column(
                children: [
                  ..._findDeviceList.map((e) => Text(e)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  WSServer? wsServer;
  DeviceFindFactory? _deviceFindServer;

  void startDeviceFindServer() {
    stopDeviceFindServer();
    _deviceFindServer = DeviceFindFactory(onState: onState);
    _deviceFindServer!.init().then(
        (value) => _deviceFindServer!.startServer(SSNWT_FLAG_FLY_SCREEN_SERVER));
  }

  void stopDeviceFindServer() {
    if (_deviceFindServer != null) {
      _deviceFindServer?.stopServer();
      _deviceFindServer?.release();
    }
    _deviceFindServer = null;
  }

  void onState(int state) {
    log('onState $state');
    if (state == STATE_BROADCAST_INIT_SOCKET_ERROR ||
        state == STATE_SSDP_INIT_SOCKET_ERROR) {
      Fluttertoast.showToast(msg: "网络发现服务异常");
    }
  }

  DeviceFindFactory? _deviceFindClient;
  final Set<String> _findDeviceList = {};

  void startDeviceFindClient() {
    stopDeviceFindClient();
    _deviceFindClient = DeviceFindFactory(onState: onState);
    _deviceFindClient!.init().then(
            (value) => _deviceFindClient!.startClient(SSNWT_FLAG_FLY_SCREEN_SERVER, onDeviceFind));
  }

  void onDeviceFind(String address, int flag, String data) {
    setState(() {
      _findDeviceList.add(address);
    });
  }

  void stopDeviceFindClient() {
    if (_deviceFindClient != null) {
      _deviceFindClient?.stopClient();
      _deviceFindClient?.release();
    }
    _deviceFindClient = null;
  }

  void startWSServer() {
    stopWSServer();
    wsServer = WSServer(
        serverInfo: ServerInfo(type: deviceTypeAndroid, name: 'Huawei'));
    wsServer!.start(WSConnectionType.flyScreen, listener: this);
  }

  void stopWSServer() {
    if (wsServer != null) {
      wsServer!.stop();
    }
    wsServer = null;
  }

  @override
  void onClientChanged(List<ClientInfo> clients) {
    log('onClientChanged $clients');
  }

  @override
  void onHttpRequest(HttpRequest request) {
    log('onHttpRequest $request');
  }

  @override
  void onMessage(WebSocket webSocket, WSMessage message) {
    log('onMessage $message');
  }

  @override
  void onServerError({error}) {
    log('onServerError $error');
  }

  @override
  void onServerStart() {
    getIntranetIp().then((value) => log('onServerStart $value'));
  }
}
