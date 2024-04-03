// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProtoDataHelloImpl _$$ProtoDataHelloImplFromJson(Map<String, dynamic> json) =>
    _$ProtoDataHelloImpl(
      fingerPrint: json['fingerPrint'] as int,
      supportBle: json['supportBle'] as bool,
      supportWlan: json['supportWlan'] as bool,
      supportWlanP2p: json['supportWlanP2p'] as bool,
      ipAddr: json['ipAddr'] as String?,
    );

Map<String, dynamic> _$$ProtoDataHelloImplToJson(
        _$ProtoDataHelloImpl instance) =>
    <String, dynamic>{
      'fingerPrint': instance.fingerPrint,
      'supportBle': instance.supportBle,
      'supportWlan': instance.supportWlan,
      'supportWlanP2p': instance.supportWlanP2p,
      'ipAddr': instance.ipAddr,
    };

_$ProtoDataRespImpl _$$ProtoDataRespImplFromJson(Map<String, dynamic> json) =>
    _$ProtoDataRespImpl(
      state: json['state'] as String,
    );

Map<String, dynamic> _$$ProtoDataRespImplToJson(_$ProtoDataRespImpl instance) =>
    <String, dynamic>{
      'state': instance.state,
    };
