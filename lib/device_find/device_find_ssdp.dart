import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/utils.dart';
import 'device_find.dart';
import 'device_find_utils.dart';

const SSDP_MULTICAST_ADDR = "239.255.255.250";
const SSDP_PORT = 1900;

abstract class SSDPBase {
  static const _TAG = 'SSDPBase';
  late RawDatagramSocket _mSocket;
  late bool? _showLog;
  OnStateListener? _mStateListener;

  //服务端只能有一个值，客户端可能有多个值
  late Set<String> _mTargetSet;

  late Timer mTimer;

  SSDPBase(RawDatagramSocket socket, int flag,
      {OnStateListener? stateListener, bool? showLog}) {
    _mSocket = socket;
    _mTargetSet = parse2Targets(flag);
    _mStateListener = stateListener;
    _showLog = showLog;
  }

  void start() {
    onStart();
  }

  void stop() {
    mTimer.cancel();
    onStop();
  }

  void onStart();

  void onStop();

  void onReceive(Datagram datagram);

  void send(String data) {
    if (_showLog == true) {
      log('_send\n $data', tag: _TAG);
    }
    try {
      InternetAddress group = InternetAddress(SSDP_MULTICAST_ADDR);
      _mSocket.send(const Utf8Encoder().convert(data), group, SSDP_PORT);
    } catch (e) {
      _mStateListener?.call(STATE_SSDP_SEND_ERROR);
    }
  }
}

class SSDPClient extends SSDPBase {
  static const _TAG = 'SSDPClient';

  //需要搜索的Target,可能多个
  late String _mTargets;
  OnFindListener? _mListener;

  SSDPClient(RawDatagramSocket socket, int flag,
      {OnStateListener? stateListener, bool? showLog})
      : super(socket, flag, stateListener: stateListener, showLog: showLog) {
    _mTargets = _mTargetSet.join("|");
  }

  @override
  void onReceive(Datagram datagram) {
    String message = String.fromCharCodes(datagram.data).trim();

    if (message.startsWith("NOTIFY * HTTP/1.1") ||
        message.startsWith("HTTP/1.1 200 OK")) {
      // var target = getValue(message, "ST");
      // var data = getValue(message, 'EXTRA');
      // if (target != null && _mTargets.contains(target)) {
      //   _mListener?.call(datagram.address.address, parse2Flag(target), data!);
      // }
      _parseClientRec(message, datagram.address.address);
    }
  }

  @override
  void onStart() {
    _startSearch();
  }

  @override
  void onStop() {}

  void setOnFindDeviceListener(OnFindListener listener) {
    _mListener = listener;
  }

  void _startSearch() {
    mTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      String msg = "M-SEARCH * HTTP/1.1\n"
              "Host: 239.255.255.250:1900\n"
              "Man: \"ssdp:discover\"\n"
              "ST: " +
          _mTargets +
          "\n"
              "MX: 3\n"
              "USER-AGENT: SSNWT SSDP Client\n";
      send(msg);
    });
  }

  void _parseClientRec(String message, String address) {
    var targetStr = getValue(message, 'ST');
    var dataStr = getValue(message, 'EXTRA');

    if (targetStr == null || targetStr.isEmpty) {
      return;
    }
    var targets = targetStr.split("|");
    var extras = dataStr?.split("|");

    for (var element in _mTargetSet) {
      for (int i = 0; i < targets.length; i++) {
        if (element.contains(targets[i])) {
          _mListener?.call(
              address, parse2Flag(targets[i]), extras == null ? "" : extras[i]);
        }
      }
    }
  }
}

class SSDPServer extends SSDPBase {
  static const _TAG = 'SSDPServer';
  late String mTarget;
  var _ServerExtra = "";

  SSDPServer(RawDatagramSocket socket, int flag,
      {OnStateListener? stateListener, bool? showLog})
      : super(socket, flag, stateListener: stateListener, showLog: showLog) {
    mTarget = _mTargetSet.first;
  }

  @override
  void onReceive(Datagram datagram) {
    String message = String.fromCharCodes(datagram.data).trim();
    if (message.startsWith("M-SEARCH * HTTP/1.1")) {
      var targets = getValue(message, "ST");
      if (targets != null && targets.contains(mTarget)) {
        //表示是对应客户端在搜索，因此需响应,单播
        _response(InternetAddress(datagram.address.address));
      }
    }
  }

  @override
  void onStart() {
    _startNotify();
  }

  @override
  void onStop() {}

  void setServerExtra(String data) {
    _ServerExtra = data;
  }

  void _startNotify() {
    mTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      String msg = "NOTIFY * HTTP/1.1\n"
              "HOST: 239.255.255.250:1900\n"
              "CACHE-CONTROL: max-age=60\n"
              "ST: " +
          mTarget +
          "\n"
              "NTS: ssdp:alive\n"
              "EXTRA:" +
          _ServerExtra +
          "\n;";
      send(msg);
    });
  }

  void _response(InternetAddress address) {
    String msg = "HTTP/1.1 200 OK \n"
            "CACHE-CONTROL: max-age=60\n"
            "ST: " +
        mTarget +
        "\n"
            "EXTRA:" +
        _ServerExtra +
        "\n;";
    //send(msg);
    try {
      _mSocket.send(const Utf8Encoder().convert(msg), address, SSDP_PORT);
    } catch (e) {
      _mStateListener?.call(STATE_SSDP_SEND_ERROR);
    }
  }
}

class SSDPDeviceFind extends DeviceFind {
  static const _TAG = 'SSDPDeviceFind';

  late RawDatagramSocket _mSocket;
  late NetworkInterface mNetworkInterface;
  late StreamSubscription _receiveSub;
  late bool? _showLog;
  OnStateListener? _mStateListener;
  bool _mIsSocketInit = false;

  SSDPClient? mSSDPClient;
  SSDPServer? mSSDPServer;

  SSDPDeviceFind({OnStateListener? stateListener, bool? showLog}) {
    _mStateListener = stateListener;
    _showLog = showLog;
  }

  @override
  Future<void> init() async {
    await _initSocket();
    if (!_mIsSocketInit) {
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _receive();
  }

  @override
  void startClient(int flag, OnFindListener listener) {
    log('startClient', tag: _TAG);
    if (!_mIsSocketInit) {
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    mSSDPClient = SSDPClient(_mSocket, flag,
        stateListener: _mStateListener, showLog: _showLog);
    mSSDPClient!.setOnFindDeviceListener(listener);
    mSSDPClient!.start();
  }

  @override
  void startServer(int flag) {
    log('startServer', tag: _TAG);
    if (!_mIsSocketInit) {
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    mSSDPServer = SSDPServer(_mSocket, flag,
        stateListener: _mStateListener, showLog: _showLog);
    mSSDPServer!.start();
  }

  @override
  void stopClient() {
    log('stopClient', tag: _TAG);
    if (!_mIsSocketInit) {
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    mSSDPClient?.stop();
  }

  @override
  void stopServer() {
    log('stopServer', tag: _TAG);
    if (!_mIsSocketInit) {
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    mSSDPServer?.stop();
  }

  @override
  void release() {
    log('release', tag: _TAG);
    if (!_mIsSocketInit) {
      log('_mIsSocketInit is false!', tag: _TAG);
      return;
    }
    _receiveSub.cancel();
    // _mSocket.leaveMulticast(
    //     InternetAddress(SSDP_MULTICAST_ADDR), mNetworkInterface);
    _mSocket.close();
    _mIsSocketInit = false;
  }

  void onReceive(Datagram datagram) {
    mSSDPClient?.onReceive(datagram);
    mSSDPServer?.onReceive(datagram);
  }

  @override
  void setServerExtra(String data) {
    log('setServerExtra', tag: _TAG);
    mSSDPServer?.setServerExtra(data);
  }

  Future<void> _initSocket() async {
    log('_initSocket', tag: _TAG);
    try {
      mNetworkInterface = await getDefaultNetworkInterface();
      _mSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, SSDP_PORT);
      _mSocket.joinMulticast(
          InternetAddress(SSDP_MULTICAST_ADDR), mNetworkInterface);
      _mIsSocketInit = true;
      _mStateListener?.call(STATE_SSDP_INIT_SOCKET_OK);
    } catch (e) {
      _mIsSocketInit = false;
      _mStateListener?.call(STATE_SSDP_INIT_SOCKET_ERROR);
      log('_initSocket $e', tag: _TAG);
    }
  }

  void _receive() {
    _receiveSub = _mSocket.listen((RawSocketEvent e) {
      Datagram? d = _mSocket.receive();
      if (d == null) return;
      if (_showLog == true) {
        log(
            'Received from ${d.address.address}:${d.port}'
            ' data:${String.fromCharCodes(d.data).trim()}',
            tag: _TAG);
      }
      onReceive(d);
    });
  }

  Future<NetworkInterface> getDefaultNetworkInterface() async {
    return NetworkInterface.list(
            includeLoopback: false,
            includeLinkLocal: false,
            type: InternetAddressType.IPv4)
        .then((value) => value.first);
  }
}
