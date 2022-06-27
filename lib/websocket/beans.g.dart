// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beans.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WSMessage _$WSMessageFromJson(Map<String, dynamic> json) => WSMessage(
      code: json['code'] as int,
      data: json['data'] as String?,
    );

Map<String, dynamic> _$WSMessageToJson(WSMessage instance) => <String, dynamic>{
      'code': instance.code,
      'data': instance.data,
    };

ServerInfo _$ServerInfoFromJson(Map<String, dynamic> json) => ServerInfo(
      type: json['type'] as int,
      name: json['name'] as String,
      extra: json['extra'] as String?,
    );

Map<String, dynamic> _$ServerInfoToJson(ServerInfo instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'extra': instance.extra,
    };
