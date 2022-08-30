import 'package:sky_device_info/beans.dart';
import 'package:sky_device_info/sky_device_info.dart';

bool get inDebugMode {
  bool _inDebugMode = false;
  assert(_inDebugMode = true);
  return _inDebugMode;
}

void log(Object? object, {String? tag}) {
  if (!inDebugMode) return;
  String text = tag != null ? '$tag $object' : '$object';
  // ignore: avoid_print
  print(text);
}

Map<String, dynamic> filter(Map<String, dynamic> map) {
  var newMap = <String, dynamic>{};
  map.forEach((key, value) {
    if (value != null) newMap[key] = value;
  });
  return newMap;
}

// Future<String?> getIntranetIp() async {
//   String? ip;
//   for (var interface in await NetworkInterface.list()) {
//     for (var addr in interface.addresses) {
//       if (addr.address.startsWith('192.') ||
//           addr.address.startsWith('10.') ||
//           addr.address.startsWith('172.')) ip = addr.address;
//     }
//   }
//   return ip;
// }

final _skyDeviceInfoPlugin = SkyDeviceInfo();

Future<String?> getIntranetIp() async {
  DeviceInfo? deviceInfo = await _skyDeviceInfoPlugin.loadDeviceInfo();
  if (deviceInfo != null) {
    NetworkInfo? networkInfo = _skyDeviceInfoPlugin.networkInfo;
    if (networkInfo != null && networkInfo.networkAdapters.isNotEmpty) {
      return networkInfo.networkAdapters.first.ipAddress;
    }
  }
  return null;
}
