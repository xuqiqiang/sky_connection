import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/utils.dart';
import 'device_find.dart';
import 'device_find_utils.dart';

class BroadcastDeviceFind extends DeviceFind {
  static const _TAG = "SSNWTBroadcast";
  static const _PORT = 9898;
  late RawDatagramSocket _mSocket;
  late OnStateListener? _mStateListener;
  bool _mIsSocketInit = false;

  //客户端
  Set<String>? _mClientTargets;
  StreamSubscription? _receiveSub;
  OnFindListener? _mListener;

  //服务端
  String? _mServerTarget;
  Timer? _timer;
  InternetAddress? _BroadcastAddress;
  String _ServerExtra = "";

  BroadcastDeviceFind({OnStateListener? stateListener}) {
    _mStateListener = stateListener;
  }

  @override
  Future<void> init() async {
    await _initSocket();
  }

  @override
  void startClient(int flag, OnFindListener listener) {
    log('startClient,flag = $flag', tag: _TAG);
    if(!_mIsSocketInit){
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _mClientTargets = parse2Targets(flag);
    _mListener = listener;
    _receive();
  }

  @override
  void startServer(int flag) async {
    log('startServer,flag = $flag', tag: _TAG);
    if(!_mIsSocketInit){
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _BroadcastAddress = await getBroadcastAddress();
    if(_BroadcastAddress == null ){
      log('_BroadcastAddress is null!', tag: _TAG);
      return;
    }
    log('startServer,_BroadcastAddress = $_BroadcastAddress', tag: _TAG);
    _mServerTarget = parse2Targets(flag).first;
    _startSend();
  }

  @override
  void stopClient() {
    log('stopClient', tag: _TAG);
    if(!_mIsSocketInit){
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _receiveSub?.cancel();
  }

  @override
  void stopServer() {
    log('stopServer', tag: _TAG);
    if(!_mIsSocketInit){
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _timer?.cancel();
  }

  @override
  void release() {
    log('release', tag: _TAG);
    if(!_mIsSocketInit){
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _mSocket.close();
  }

  @override
  void setServerExtra(String data) {
    log('setServerExtra', tag: _TAG);
    _ServerExtra = data;
  }

  Future<void> _initSocket() async {
    log('_initSocket', tag: _TAG);
    try {
      _mSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _PORT);
      _mIsSocketInit = true;
      _mStateListener?.call(STATE_BROADCAST_INIT_SOCKET_OK);
    } catch (e) {
      _mIsSocketInit = false;
      _mStateListener?.call(STATE_BROADCAST_INIT_SOCKET_ERROR);
      log('_initSocket $e', tag: _TAG);
    }
  }

  void _startSend() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _send();
    });
  }

  void _send() {
    String sendString =
        "BroadCast\nST:" + _mServerTarget! + "\nEXTRA:" + _ServerExtra + "\n;";
    log('_send $sendString', tag: _TAG);
    try {
      _mSocket.send(
          const Utf8Encoder().convert(sendString), _BroadcastAddress!, 9898);
    } catch (e) {
      _mStateListener?.call(STATE_BROADCAST_SEND_ERROR);
    }
  }

  void _receive() {
    _receiveSub = _mSocket.listen((RawSocketEvent e) {
      Datagram? d = _mSocket.receive();
      if (d == null) return;
      String message = String.fromCharCodes(d.data).trim();
      log("Received from ${d.address.address}:${d.port}  data $message",
          tag: _TAG);
      var target = getValue(message, 'ST');
      var data = getValue(message, 'EXTRA');
      if (_mClientTargets!.contains(target)) {
        _mListener?.call(d.address.address, parse2Flag(target!), data!);
      }
    });
  }

  getBroadcastAddress() async {
    String? ip = await getIntranetIp();
    if (ip == null) {
      return null;
    }
    var broadcastIp = ip.substring(0, ip.lastIndexOf('.') + 1) + "255";
    return InternetAddress(broadcastIp);
  }
}
