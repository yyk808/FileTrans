import 'package:freezed_annotation/freezed_annotation.dart';

part 'protocol.freezed.dart';
part 'protocol.g.dart';


@freezed
class ProtoDataHello with _$ProtoDataHello {
  const factory ProtoDataHello({
    required int fingerPrint,
    required bool supportBle,
    required bool supportWlan,
    required bool supportWlanP2p,
    required String? ipAddr,
  }) = _ProtoDataHello;

  factory ProtoDataHello.fromJson(Map<String, Object?> json)
  => _$ProtoDataHelloFromJson(json);
}

@freezed
class ProtoDataResp with _$ProtoDataResp {
  const factory ProtoDataResp({
    required String state,
  }) = _ProtoDataResp;

  factory ProtoDataResp.fromJson(Map<String, Object?> json)
  => _$ProtoDataRespFromJson(json);
}