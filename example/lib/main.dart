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
              ElevatedButton(
                  child: Text(
                      '${mDeviceFind != null ? 'Stop' : 'Start'} find server'),
                  onPressed: () => setState(mDeviceFind != null
                      ? stopDeviceFindServer
                      : startDeviceFindServer)),
              ElevatedButton(
                child: Text(
                    '${wsServer != null ? 'Stop' : 'Start'} websocket server'),
                onPressed: () =>
                    setState(wsServer != null ? stopWSServer : startWSServer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  WSServer? wsServer;
  DeviceFindFactory? mDeviceFind;

  void startDeviceFindServer() {
    stopDeviceFindServer();
    mDeviceFind = DeviceFindFactory(onState: onState);
    mDeviceFind!.init().then(
        (value) => mDeviceFind!.startServer(SSNWT_FLAG_FLY_SCREEN_SERVER));
  }

  void stopDeviceFindServer() {
    if (mDeviceFind != null) {
      mDeviceFind?.stopServer();
      mDeviceFind?.release();
    }
    mDeviceFind = null;
  }

  void onState(int state) {
    log('onState $state');
    if (state == STATE_BROADCAST_INIT_SOCKET_ERROR ||
        state == STATE_SSDP_INIT_SOCKET_ERROR) {
      Fluttertoast.showToast(msg: "网络发现服务异常");
    }
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
