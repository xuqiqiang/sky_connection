const DEVICE_FOUND_BROADCAST = 1; //使用广播方式
const DEVICE_FOUND_SSDP = 2; //使用ssdp方式
const DEVICE_FOUND_BROADCAST_SSDP = 3; //同时使用广播和ssdp方式

const SSNWT_FLY_SCREEN_CLIENT = "ssnwt:fly_screen:client"; //飞屏客户端
const SSNWT_FLY_SCREEN_SERVER = "ssnwt:fly_screen:server"; //飞屏服务端
const SSNWT_STREAM_CLIENT = "ssnwt:stream:client"; //串流客户端
const SSNWT_STREAM_SERVER = "ssnwt:stream:server"; //串流服务端
const SSNWT_CENTER_CONTROL_CLIENT = "ssnwt:centerControl:client"; //中控客户端
const SSNWT_CENTER_CONTROL_SERVER = "ssnwt:centerControl:server"; //中控服务端
const SSNWT_VR_SERVER_CLIENT = "ssnwt:vr_server:client"; //VR设备服务客户端
const SSNWT_VR_SERVER_SERVER = "ssnwt:vr_server:server"; //VR设备服务服务端

const SSNWT_FLAG_FLY_SCREEN_CLIENT = 1; //飞屏客户端标记
const SSNWT_FLAG_FLY_SCREEN_SERVER = 2; //飞屏服务器标记
const SSNWT_FLAG_STREAM_CLIENT = 4; //串流客户端标记
const SSNWT_FLAG_STREAM_SERVER = 8; //串流服务器标记
const SSNWT_FLAG_CENTER_CONTROL_CLIENT = 16; //中控客户端标记
const SSNWT_FLAG_CENTER_CONTROL_SERVER = 32; //中控服务器标记
const SSNWT_FLAG_VR_SERVER_CLIENT = 64; //VR设备服务客户端标记
const SSNWT_FLAG_VR_SERVER_SERVER = 128; //VR设备服务服务端标记

const STATE_BROADCAST_INIT_SOCKET_ERROR = 10;
const STATE_BROADCAST_SEND_ERROR = 11;
const STATE_BROADCAST_INIT_SOCKET_OK = 12;
const STATE_SSDP_INIT_SOCKET_ERROR = 20;
const STATE_SSDP_SEND_ERROR = 21;
const STATE_SSDP_INIT_SOCKET_OK = 22;

/// 将flag转换为字符串set
Set<String> parse2Targets(int flag) {
  Set<String> targets = {};
  if ((flag & SSNWT_FLAG_FLY_SCREEN_CLIENT) != 0) {
    targets.add(SSNWT_FLY_SCREEN_CLIENT);
  }
  if ((flag & SSNWT_FLAG_FLY_SCREEN_SERVER) != 0) {
    targets.add(SSNWT_FLY_SCREEN_SERVER);
  }
  if ((flag & SSNWT_FLAG_STREAM_CLIENT) != 0) {
    targets.add(SSNWT_STREAM_CLIENT);
  }
  if ((flag & SSNWT_FLAG_STREAM_SERVER) != 0) {
    targets.add(SSNWT_STREAM_SERVER);
  }
  if ((flag & SSNWT_FLAG_CENTER_CONTROL_CLIENT) != 0) {
    targets.add(SSNWT_CENTER_CONTROL_CLIENT);
  }
  if ((flag & SSNWT_FLAG_CENTER_CONTROL_SERVER) != 0) {
    targets.add(SSNWT_CENTER_CONTROL_SERVER);
  }

  if ((flag & SSNWT_FLAG_VR_SERVER_CLIENT) != 0) {
    targets.add(SSNWT_VR_SERVER_CLIENT);
  }
  if ((flag & SSNWT_FLAG_VR_SERVER_SERVER) != 0) {
    targets.add(SSNWT_VR_SERVER_SERVER);
  }
  return targets;
}

///将单个字符串转化为int 标记
int parse2Flag(String target) {
  target = target.trim();
  if (target.compareTo(SSNWT_FLY_SCREEN_CLIENT) == 0) {
    return SSNWT_FLAG_FLY_SCREEN_CLIENT;
  } else if (target.compareTo(SSNWT_FLY_SCREEN_SERVER) == 0) {
    return SSNWT_FLAG_FLY_SCREEN_SERVER;
  } else if (target.compareTo(SSNWT_STREAM_CLIENT) == 0) {
    return SSNWT_FLAG_STREAM_CLIENT;
  } else if (target.compareTo(SSNWT_STREAM_SERVER) == 0) {
    return SSNWT_FLAG_STREAM_SERVER;
  } else if (target.compareTo(SSNWT_CENTER_CONTROL_CLIENT) == 0) {
    return SSNWT_FLAG_CENTER_CONTROL_CLIENT;
  } else if (target.compareTo(SSNWT_CENTER_CONTROL_SERVER) == 0) {
    return SSNWT_FLAG_CENTER_CONTROL_SERVER;
  } else if (target.compareTo(SSNWT_VR_SERVER_CLIENT) == 0) {
    return SSNWT_FLAG_VR_SERVER_CLIENT;
  } else if (target.compareTo(SSNWT_VR_SERVER_SERVER) == 0) {
    return SSNWT_FLAG_VR_SERVER_SERVER;
  }
  return -1;
}

String? getValue(String source, String key) {
  key = '\n' + key;
  int index = source.indexOf(key);
  if (index < 0) {
    return null;
  } else {
    source = source.substring(index + 1 + key.length);
  }
  index = source.indexOf("\n");
  if (index == -1) return null;
  return source.substring(0, index).trim();
}
