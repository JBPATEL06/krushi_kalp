import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/offer.dart';

part 'offer_state.freezed.dart';

@freezed
abstract class OfferState with _$OfferState {
  const factory OfferState({
    @Default([]) List<Offer> activeOffers,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
  }) = _OfferState;
}
