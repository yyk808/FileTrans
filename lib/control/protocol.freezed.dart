// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'protocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ProtoDataHello _$ProtoDataHelloFromJson(Map<String, dynamic> json) {
  return _ProtoDataHello.fromJson(json);
}

/// @nodoc
mixin _$ProtoDataHello {
  int get fingerPrint => throw _privateConstructorUsedError;
  bool get supportBle => throw _privateConstructorUsedError;
  bool get supportWlan => throw _privateConstructorUsedError;
  bool get supportWlanP2p => throw _privateConstructorUsedError;
  String? get ipAddr => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProtoDataHelloCopyWith<ProtoDataHello> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProtoDataHelloCopyWith<$Res> {
  factory $ProtoDataHelloCopyWith(
          ProtoDataHello value, $Res Function(ProtoDataHello) then) =
      _$ProtoDataHelloCopyWithImpl<$Res, ProtoDataHello>;
  @useResult
  $Res call(
      {int fingerPrint,
      bool supportBle,
      bool supportWlan,
      bool supportWlanP2p,
      String? ipAddr});
}

/// @nodoc
class _$ProtoDataHelloCopyWithImpl<$Res, $Val extends ProtoDataHello>
    implements $ProtoDataHelloCopyWith<$Res> {
  _$ProtoDataHelloCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fingerPrint = null,
    Object? supportBle = null,
    Object? supportWlan = null,
    Object? supportWlanP2p = null,
    Object? ipAddr = freezed,
  }) {
    return _then(_value.copyWith(
      fingerPrint: null == fingerPrint
          ? _value.fingerPrint
          : fingerPrint // ignore: cast_nullable_to_non_nullable
              as int,
      supportBle: null == supportBle
          ? _value.supportBle
          : supportBle // ignore: cast_nullable_to_non_nullable
              as bool,
      supportWlan: null == supportWlan
          ? _value.supportWlan
          : supportWlan // ignore: cast_nullable_to_non_nullable
              as bool,
      supportWlanP2p: null == supportWlanP2p
          ? _value.supportWlanP2p
          : supportWlanP2p // ignore: cast_nullable_to_non_nullable
              as bool,
      ipAddr: freezed == ipAddr
          ? _value.ipAddr
          : ipAddr // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProtoDataHelloImplCopyWith<$Res>
    implements $ProtoDataHelloCopyWith<$Res> {
  factory _$$ProtoDataHelloImplCopyWith(_$ProtoDataHelloImpl value,
          $Res Function(_$ProtoDataHelloImpl) then) =
      __$$ProtoDataHelloImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int fingerPrint,
      bool supportBle,
      bool supportWlan,
      bool supportWlanP2p,
      String? ipAddr});
}

/// @nodoc
class __$$ProtoDataHelloImplCopyWithImpl<$Res>
    extends _$ProtoDataHelloCopyWithImpl<$Res, _$ProtoDataHelloImpl>
    implements _$$ProtoDataHelloImplCopyWith<$Res> {
  __$$ProtoDataHelloImplCopyWithImpl(
      _$ProtoDataHelloImpl _value, $Res Function(_$ProtoDataHelloImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fingerPrint = null,
    Object? supportBle = null,
    Object? supportWlan = null,
    Object? supportWlanP2p = null,
    Object? ipAddr = freezed,
  }) {
    return _then(_$ProtoDataHelloImpl(
      fingerPrint: null == fingerPrint
          ? _value.fingerPrint
          : fingerPrint // ignore: cast_nullable_to_non_nullable
              as int,
      supportBle: null == supportBle
          ? _value.supportBle
          : supportBle // ignore: cast_nullable_to_non_nullable
              as bool,
      supportWlan: null == supportWlan
          ? _value.supportWlan
          : supportWlan // ignore: cast_nullable_to_non_nullable
              as bool,
      supportWlanP2p: null == supportWlanP2p
          ? _value.supportWlanP2p
          : supportWlanP2p // ignore: cast_nullable_to_non_nullable
              as bool,
      ipAddr: freezed == ipAddr
          ? _value.ipAddr
          : ipAddr // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProtoDataHelloImpl implements _ProtoDataHello {
  const _$ProtoDataHelloImpl(
      {required this.fingerPrint,
      required this.supportBle,
      required this.supportWlan,
      required this.supportWlanP2p,
      required this.ipAddr});

  factory _$ProtoDataHelloImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProtoDataHelloImplFromJson(json);

  @override
  final int fingerPrint;
  @override
  final bool supportBle;
  @override
  final bool supportWlan;
  @override
  final bool supportWlanP2p;
  @override
  final String? ipAddr;

  @override
  String toString() {
    return 'ProtoDataHello(fingerPrint: $fingerPrint, supportBle: $supportBle, supportWlan: $supportWlan, supportWlanP2p: $supportWlanP2p, ipAddr: $ipAddr)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProtoDataHelloImpl &&
            (identical(other.fingerPrint, fingerPrint) ||
                other.fingerPrint == fingerPrint) &&
            (identical(other.supportBle, supportBle) ||
                other.supportBle == supportBle) &&
            (identical(other.supportWlan, supportWlan) ||
                other.supportWlan == supportWlan) &&
            (identical(other.supportWlanP2p, supportWlanP2p) ||
                other.supportWlanP2p == supportWlanP2p) &&
            (identical(other.ipAddr, ipAddr) || other.ipAddr == ipAddr));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, fingerPrint, supportBle,
      supportWlan, supportWlanP2p, ipAddr);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProtoDataHelloImplCopyWith<_$ProtoDataHelloImpl> get copyWith =>
      __$$ProtoDataHelloImplCopyWithImpl<_$ProtoDataHelloImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProtoDataHelloImplToJson(
      this,
    );
  }
}

abstract class _ProtoDataHello implements ProtoDataHello {
  const factory _ProtoDataHello(
      {required final int fingerPrint,
      required final bool supportBle,
      required final bool supportWlan,
      required final bool supportWlanP2p,
      required final String? ipAddr}) = _$ProtoDataHelloImpl;

  factory _ProtoDataHello.fromJson(Map<String, dynamic> json) =
      _$ProtoDataHelloImpl.fromJson;

  @override
  int get fingerPrint;
  @override
  bool get supportBle;
  @override
  bool get supportWlan;
  @override
  bool get supportWlanP2p;
  @override
  String? get ipAddr;
  @override
  @JsonKey(ignore: true)
  _$$ProtoDataHelloImplCopyWith<_$ProtoDataHelloImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProtoDataResp _$ProtoDataRespFromJson(Map<String, dynamic> json) {
  return _ProtoDataResp.fromJson(json);
}

/// @nodoc
mixin _$ProtoDataResp {
  String get state => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProtoDataRespCopyWith<ProtoDataResp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProtoDataRespCopyWith<$Res> {
  factory $ProtoDataRespCopyWith(
          ProtoDataResp value, $Res Function(ProtoDataResp) then) =
      _$ProtoDataRespCopyWithImpl<$Res, ProtoDataResp>;
  @useResult
  $Res call({String state});
}

/// @nodoc
class _$ProtoDataRespCopyWithImpl<$Res, $Val extends ProtoDataResp>
    implements $ProtoDataRespCopyWith<$Res> {
  _$ProtoDataRespCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
  }) {
    return _then(_value.copyWith(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProtoDataRespImplCopyWith<$Res>
    implements $ProtoDataRespCopyWith<$Res> {
  factory _$$ProtoDataRespImplCopyWith(
          _$ProtoDataRespImpl value, $Res Function(_$ProtoDataRespImpl) then) =
      __$$ProtoDataRespImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String state});
}

/// @nodoc
class __$$ProtoDataRespImplCopyWithImpl<$Res>
    extends _$ProtoDataRespCopyWithImpl<$Res, _$ProtoDataRespImpl>
    implements _$$ProtoDataRespImplCopyWith<$Res> {
  __$$ProtoDataRespImplCopyWithImpl(
      _$ProtoDataRespImpl _value, $Res Function(_$ProtoDataRespImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
  }) {
    return _then(_$ProtoDataRespImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProtoDataRespImpl implements _ProtoDataResp {
  const _$ProtoDataRespImpl({required this.state});

  factory _$ProtoDataRespImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProtoDataRespImplFromJson(json);

  @override
  final String state;

  @override
  String toString() {
    return 'ProtoDataResp(state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProtoDataRespImpl &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, state);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProtoDataRespImplCopyWith<_$ProtoDataRespImpl> get copyWith =>
      __$$ProtoDataRespImplCopyWithImpl<_$ProtoDataRespImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProtoDataRespImplToJson(
      this,
    );
  }
}

abstract class _ProtoDataResp implements ProtoDataResp {
  const factory _ProtoDataResp({required final String state}) =
      _$ProtoDataRespImpl;

  factory _ProtoDataResp.fromJson(Map<String, dynamic> json) =
      _$ProtoDataRespImpl.fromJson;

  @override
  String get state;
  @override
  @JsonKey(ignore: true)
  _$$ProtoDataRespImplCopyWith<_$ProtoDataRespImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
