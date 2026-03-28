// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OfferState {
  List<Offer> get activeOffers => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String get errorMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OfferStateCopyWith<OfferState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfferStateCopyWith<$Res> {
  factory $OfferStateCopyWith(
          OfferState value, $Res Function(OfferState) then) =
      _$OfferStateCopyWithImpl<$Res, OfferState>;
  @useResult
  $Res call({List<Offer> activeOffers, bool isLoading, String errorMessage});
}

/// @nodoc
class _$OfferStateCopyWithImpl<$Res, $Val extends OfferState>
    implements $OfferStateCopyWith<$Res> {
  _$OfferStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeOffers = null,
    Object? isLoading = null,
    Object? errorMessage = null,
  }) {
    return _then(_value.copyWith(
      activeOffers: null == activeOffers
          ? _value.activeOffers
          : activeOffers // ignore: cast_nullable_to_non_nullable
              as List<Offer>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OfferStateImplCopyWith<$Res>
    implements $OfferStateCopyWith<$Res> {
  factory _$$OfferStateImplCopyWith(
          _$OfferStateImpl value, $Res Function(_$OfferStateImpl) then) =
      __$$OfferStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Offer> activeOffers, bool isLoading, String errorMessage});
}

/// @nodoc
class __$$OfferStateImplCopyWithImpl<$Res>
    extends _$OfferStateCopyWithImpl<$Res, _$OfferStateImpl>
    implements _$$OfferStateImplCopyWith<$Res> {
  __$$OfferStateImplCopyWithImpl(
      _$OfferStateImpl _value, $Res Function(_$OfferStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeOffers = null,
    Object? isLoading = null,
    Object? errorMessage = null,
  }) {
    return _then(_$OfferStateImpl(
      activeOffers: null == activeOffers
          ? _value._activeOffers
          : activeOffers // ignore: cast_nullable_to_non_nullable
              as List<Offer>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$OfferStateImpl implements _OfferState {
  const _$OfferStateImpl(
      {final List<Offer> activeOffers = const [],
      this.isLoading = false,
      this.errorMessage = ''})
      : _activeOffers = activeOffers;

  final List<Offer> _activeOffers;
  @override
  @JsonKey()
  List<Offer> get activeOffers {
    if (_activeOffers is EqualUnmodifiableListView) return _activeOffers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeOffers);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String errorMessage;

  @override
  String toString() {
    return 'OfferState(activeOffers: $activeOffers, isLoading: $isLoading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfferStateImpl &&
            const DeepCollectionEquality()
                .equals(other._activeOffers, _activeOffers) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_activeOffers),
      isLoading,
      errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OfferStateImplCopyWith<_$OfferStateImpl> get copyWith =>
      __$$OfferStateImplCopyWithImpl<_$OfferStateImpl>(this, _$identity);
}

abstract class _OfferState implements OfferState {
  const factory _OfferState(
      {final List<Offer> activeOffers,
      final bool isLoading,
      final String errorMessage}) = _$OfferStateImpl;

  @override
  List<Offer> get activeOffers;
  @override
  bool get isLoading;
  @override
  String get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$OfferStateImplCopyWith<_$OfferStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
