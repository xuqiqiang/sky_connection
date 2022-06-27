import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import '../utils/utils.dart';

part 'beans.g.dart';

/// WebSocket消息
///
/// [code] 消息码
/// [data] 负载信息
@JsonSerializable()
class WSMessage {
  WSMessage({required this.code, this.data});

  int code;
  String? data;

  factory WSMessage.fromJson(Map<String, dynamic> srcJson) =>
      _$WSMessageFromJson(srcJson);

  Map<String, dynamic> toJson() => filter(_$WSMessageToJson(this));

  @override
  String toString() => '{code: $code, data: $data}';
}

/// 服务端信息
///
/// [type] 类型，0:电脑 1: 安卓 2: 苹果
/// [name] 设备名称
@JsonSerializable()
class ServerInfo {
  ServerInfo({required this.type, required this.name, this.extra});

  int type;
  String name;
  String? extra;

  factory ServerInfo.fromJson(Map<String, dynamic> srcJson) =>
      _$ServerInfoFromJson(srcJson);

  Map<String, dynamic> toJson() => filter(_$ServerInfoToJson(this));

  @override
  String toString() => '{type: $type, name: $name}';
}

/// 客户端信息
///
/// [model] 设备型号
/// [sn] 序列号
class ClientInfo {
  String model;
  String sn;
  String? extra;

  ClientInfo({required this.model, required this.sn, this.extra});

  String get name => 'Skyworth VR $model'
      ' ${sn.substring(0, min(sn.length, 8))}';

  @override
  String toString() => name;
}
