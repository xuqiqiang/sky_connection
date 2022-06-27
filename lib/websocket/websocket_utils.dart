import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';

import '../utils/utils.dart';

const deviceTypePC = 0;
const deviceTypeAndroid = 1;
const deviceTypeIos = 2;

const wsMsgConnected = 1001;
const wsMsgMediaUpdate = 2001;
const wsMsgStartStreaming = 3001;
const wsMsgStopStreaming = 3002;

const wsPortFlyScreen = 9890;
const wsPortStream = 9891;
const wsPortControl = 9892;
const wsPortVRServer = 9893;

/// {apiKey: apiSecret}
Map<String, String> authKeys = {
  'fly930ea5d5a258f4f': 'ibuaiVcKdpRxkhJA',
};

enum WSConnectionType {
  flyScreen,
  stream,
  control,
  vrServer,
}

String? decBase64(String? enc) {
  if (enc == null) return null;
  return const Utf8Decoder().convert(base64Decode(base64.normalize(enc
      .replaceAll('%0A', '')
      .replaceAll('↵', '')
      .replaceAll('\n', '')
      .replaceAll(' ', '+'))));
}

String encBase64(String str) {
  return base64.normalize(base64Encode(utf8.encode(str)));
}

int getPort(WSConnectionType type) {
  if (type == WSConnectionType.flyScreen) {
    return wsPortFlyScreen;
  } else if (type == WSConnectionType.stream) {
    return wsPortStream;
  } else if (type == WSConnectionType.control) {
    return wsPortControl;
  } else if (type == WSConnectionType.vrServer) {
    return wsPortVRServer;
  }
  return -1;
}

String? headerValue(HttpRequest request, String name) {
  dynamic values = request.headers[name];
  if (values == null || values.length != 1) return null;
  return values!.first;
}

String toMd5(String data) {
  var content = const Utf8Encoder().convert(data);
  var digest = md5.convert(content);
  return hex.encode(digest.bytes);
}

String generateRandomString(int length) {
  final _random = Random();
  const _availableChars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final randomString = List.generate(length,
          (index) => _availableChars[_random.nextInt(_availableChars.length)])
      .join();

  return randomString;
}

Map<String, String> createAuthHeaders() {
  Map<String, String> headers = {};
  String apiKey = authKeys.keys.first;
  String nonce = generateRandomString(10);
  String timeStamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  String sign =
      toMd5('nonce=$nonce&timeStamp=$timeStamp&apiSecret=${authKeys[apiKey]}');

  headers['ApiKey'] = apiKey;
  headers['Nonce'] = nonce;
  headers['TimeStamp'] = timeStamp;
  headers['Sign'] = sign;
  return headers;
}

bool checkAuth(HttpRequest request) {
  String? apiKey = headerValue(request, 'ApiKey');
  String? nonce = headerValue(request, 'Nonce');
  String? timeStamp = headerValue(request, 'TimeStamp');
  String? sign = headerValue(request, 'Sign');
  if (apiKey == null || nonce == null || timeStamp == null || sign == null) {
    return false;
  }
  log('checkAuth $apiKey $nonce $timeStamp $sign');
  String? apiSecret = authKeys[apiKey];
  if (apiSecret == null) return false;
  String authSign =
      toMd5('nonce=$nonce&timeStamp=$timeStamp&apiSecret=$apiSecret');
  log('checkAuth authSign $authSign');
  return sign == authSign;
}

/// armv7a访问4g以上大文件会出错
void sendResponseFile(HttpRequest request, File? file,
    {String? mimeType}) async {
  if (file == null) {
    request.response.statusCode = 404;
    request.response.write('File not exist!');
    request.response.close();
    return;
  }
  if (mimeType == null) {
    mimeType = lookupMimeType(file.path);
    mimeType ??= "*/*";
  }
  log('sendResponseFile mimeType:$mimeType');

  int length = await file.length();
  String? range = request.headers.value("range");
  if (range != null) {
    log('sendResponseFile range:$range');
    request.response.statusCode = 206;
    List<String> parts = range.split("=");
    parts = parts[1].split("-");

    int start = 0;
    if (parts[0].isNotEmpty) {
      start = int.parse(parts[0]);
    }

    int end = length - 1;
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      end = int.parse(parts[1]);
    }
    int byteLength = end - start + 1;
    log('range:$range start:$start '
        'end:$end '
        'byteLength: $byteLength');
    initResponseHeaders(request, mimeType, byteLength);
    request.response.headers
        .add(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$length');
    await request.response.addStream(file.openRead(start, end + 1));
  } else {
    initResponseHeaders(request, mimeType, length);
    await request.response.addStream(file.openRead());
  }
  request.response.close();
}

void setAllowOriginHeader(HttpRequest request) {
  request.response.headers.add(HttpHeaders.accessControlAllowOriginHeader, '*');
  request.response.headers.add(HttpHeaders.accessControlAllowMethodsHeader,
      'POST, GET, DELETE, PUT, OPTIONS');
  request.response.headers.add(HttpHeaders.accessControlAllowHeadersHeader,
      'Origin, X-Requested-With, Content-Type, Accept');
}

void initResponseHeaders(HttpRequest request, String mimeType, int length) {
  request.response.headers.add(HttpHeaders.contentTypeHeader, mimeType);
  request.response.headers.add(HttpHeaders.acceptRangesHeader, 'bytes');
  if (request.headers.value(HttpHeaders.connectionHeader) != 'close') {
    request.response.headers.add(HttpHeaders.connectionHeader, 'Keep-Alive');
  } else {
    request.response.headers.removeAll(HttpHeaders.connectionHeader);
  }
  request.response.headers
      .add(HttpHeaders.contentLengthHeader, length.toString());
}
