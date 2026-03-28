import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/order_item.dart';

part 'cart_state.freezed.dart';

@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default([]) List<OrderItem> cartItems,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _CartState;
}
