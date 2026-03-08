import 'dart:convert';

class Offer {
  final int id;
  final String? code; // Nullable
  final String title;
  final String description;
  final String discountType; // 'PERCENTAGE' or 'FLAT'
  final double discountValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String targetType; // 'ALL', 'USER', 'TEST', 'BUNDLE'
  final List<dynamic>
      targetIds; // List of strings (User UUIDs) or ints (Test IDs)
  final double? minOrderValue;
  final double? maxDiscount;
  final bool isReal;
  final bool isSale; // NEW
  final int usageLimit; // NEW
  final int minQuantity; // NEW

  Offer({
    required this.id,
    this.code, // Nullable
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.targetType,
    required this.targetIds,
    this.minOrderValue,
    this.maxDiscount,
    this.isReal = true,
    this.isSale = false, // NEW
    this.usageLimit = 1000,
    this.minQuantity = 1,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['offer_id'] ?? 0,
      code: json['code'], // Nullable
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] ?? 'FLAT',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      targetType: json['target_type'] ?? 'ALL',
      targetIds: json['target_ids'] is String
          ? (json['target_ids'].toString().startsWith('[')
              ? List<dynamic>.from(jsonDecode(json['target_ids'].toString()))
              : [])
          : (json['target_ids'] != null
              ? List<dynamic>.from(json['target_ids'])
              : []),
      minOrderValue: (json['min_order_value'] as num?)?.toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      isReal: json['is_real'] as bool? ?? true,
      isSale: json['is_sale'] as bool? ?? false, // NEW
      usageLimit: json['usage_limit'] ?? 1000,
      minQuantity: json['min_quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'target_type': targetType,
      'target_ids': targetIds,
      'min_order_value': minOrderValue,
      'max_discount': maxDiscount,
      'is_real': isReal,
      'is_sale': isSale, // NEW
      'usage_limit': usageLimit,
      'min_quantity': minQuantity,
    };
  }

  // Check if valid for a user and cart items
  bool isValid(
      {required String userId,
      required double cartTotal,
      required List<int> cartTestIds}) {
    final now = DateTime.now().toUtc(); // Use UTC

    // Debug logic for troubleshooting
    // 
    // 

    if (!isActive) return false;
    if (startDate != null && now.isBefore(startDate!.toUtc())) return false;
    if (endDate != null && now.isAfter(endDate!.toUtc())) return false;

    if (minOrderValue != null && cartTotal < minOrderValue!) return false;

    // Target Checks
    if (targetType == 'USER') {
      if (!targetIds.contains(userId)) return false;
    }
    if (targetType == 'TEST' || targetType == 'BUNDLE') {
      // Valid if intersection is not empty. Support both int and string comparisons
      final hasTargetItem = cartTestIds.any(
          (id) => targetIds.contains(id) || targetIds.contains(id.toString()));
      if (!hasTargetItem) return false;
    }

    return true;
  }

  // Calculate Discount Amount based on cart items
  double calculateDiscountAmount({
    required double totalAmount,
    required List<Map<String, dynamic>> cartItems,
  }) {
    if (!isReal) return 0.0; // Fake offers do not reduce cart total
    double eligibleAmount = 0.0;

    if (targetType == 'ALL' || targetType == 'USER') {
      eligibleAmount = totalAmount;
    } else if (targetType == 'TEST' || targetType == 'BUNDLE') {
      // Sum price of items that match targetIds
      for (var item in cartItems) {
        final testId = item['test_id'] as int?;
        if (testId != null) {
          // Support both int and string comparisons
          if (targetIds.contains(testId) ||
              targetIds.contains(testId.toString())) {
            eligibleAmount += (item['price'] as num).toDouble();
          }
        }
      }
    }

    if (eligibleAmount <= 0) return 0.0;

    double calculatedDiscount = 0.0;
    if (discountType == 'PERCENTAGE') {
      calculatedDiscount = eligibleAmount * (discountValue / 100);
      if (maxDiscount != null && calculatedDiscount > maxDiscount!) {
        calculatedDiscount = maxDiscount!;
      }
    } else {
      // Flat discount
      // Standard logic: Flat off on the order if condition met.
      // But if it's "Flat 100 off on Test A", it shouldn't exceed the price of Test A ideally?
      // For now, let's keep it simple: Flat discount is applied to the eligible amount, capped at eligible amount.
      calculatedDiscount = discountValue;
    }

    // specific safeguard: Discount cannot exceed the eligible amount itself
    if (calculatedDiscount > eligibleAmount) {
      calculatedDiscount = eligibleAmount;
    }

    return calculatedDiscount;
  }

  Offer copyWith({
    int? id,
    String? code,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? targetType,
    List<dynamic>? targetIds,
    double? minOrderValue,
    double? maxDiscount,
    bool? isReal,
    bool? isSale,
    int? usageLimit,
    int? minQuantity,
  }) {
    return Offer(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      targetType: targetType ?? this.targetType,
      targetIds: targetIds ?? this.targetIds,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      isReal: isReal ?? this.isReal,
      isSale: isSale ?? this.isSale,
      usageLimit: usageLimit ?? this.usageLimit,
      minQuantity: minQuantity ?? this.minQuantity,
    );
  }
}
