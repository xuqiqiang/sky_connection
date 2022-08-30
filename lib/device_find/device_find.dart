import '../utils/utils.dart';
import 'device_find_broadcast.dart';
import 'device_find_ssdp.dart';
import 'device_find_utils.dart';
export 'device_find_utils.dart';

typedef OnFindListener = Function(String address, int flag, String data);
typedef OnStateListener = Function(int state);

abstract class DeviceFind {
  Future<void> init();

  void startServer(int flag);

  void stopServer();

  void setServerExtra(String data);

  void startClient(int flag, OnFindListener listener);

  void stopClient();

  void release();
}

class DeviceFindFactory extends DeviceFind {
  static const _TAG = "DeviceFindFactory";

  List<DeviceFind> mDeviceFindList = [];

  DeviceFindFactory(
      {OnStateListener? onState, type = DEVICE_FOUND_BROADCAST_SSDP, bool? showLog}) {
    switch (type) {
      case DEVICE_FOUND_BROADCAST:
        mDeviceFindList.add(BroadcastDeviceFind(stateListener: onState, showLog: showLog));
        break;
      case DEVICE_FOUND_SSDP:
        mDeviceFindList.add(SSDPDeviceFind(stateListener: onState, showLog: showLog));
        break;
      case DEVICE_FOUND_BROADCAST_SSDP:
        mDeviceFindList.add(BroadcastDeviceFind(stateListener: onState, showLog: showLog));
        mDeviceFindList.add(SSDPDeviceFind(stateListener: onState, showLog: showLog));
        break;
    }
  }

  @override
  Future<void> init() async {
    log('init start', tag: _TAG);
    await Future.wait(mDeviceFindList.map((e) => e.init()));
    log('init end', tag: _TAG);
  }

  @override
  void release() {
    log('release', tag: _TAG);
    for (var element in mDeviceFindList) {
      element.release();
    }
  }

  @override
  void startClient(int flag, OnFindListener listener) {
    log('startClient', tag: _TAG);
    for (var element in mDeviceFindList) {
      element.startClient(flag, listener);
    }
  }

  @override
  void startServer(int flag) {
    log('startServer', tag: _TAG);
    for (var element in mDeviceFindList) {
      element.startServer(flag);
    }
  }

  @override
  void stopClient() {
    log('stopClient', tag: _TAG);
    for (var element in mDeviceFindList) {
      element.stopClient();
    }
  }

  @override
  void stopServer() {
    log('stopServer', tag: _TAG);
    for (var element in mDeviceFindList) {
      element.stopServer();
    }
  }

  @override
  void setServerExtra(String data) {
    log('setServerExtra, data =' + data, tag: _TAG);
    for (var element in mDeviceFindList) {
      element.setServerExtra(data);
    }
  }
}
