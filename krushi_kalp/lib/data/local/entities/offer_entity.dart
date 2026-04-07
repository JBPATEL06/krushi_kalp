import 'package:isar/isar.dart';
import 'package:krushi_kalp/domain/models/offer.dart';

part 'offer_entity.g.dart';

@collection
class OfferEntity {
  @Index(unique: true, replace: true)
  Id id = Isar.autoIncrement;

  int? offerId;
  String? code;
  String? title;
  String? description;
  String? discountType;
  double? discountValue;
  DateTime? startDate;
  DateTime? endDate;
  bool? isActive;
  String? targetType;
  List<String>? targetIds; // Isar doesn't support List<dynamic>, so we map to strings
  double? minOrderValue;
  double? maxDiscount;
  bool? isReal;
  bool? isSale;
  int? usageLimit;
  int? minQuantity;

  // Convert from Domain Model
  static OfferEntity fromOffer(Offer offer) {
    return OfferEntity()
      ..id = offer.id
      ..offerId = offer.id
      ..code = offer.code
      ..title = offer.title
      ..description = offer.description
      ..discountType = offer.discountType
      ..discountValue = offer.discountValue
      ..startDate = offer.startDate
      ..endDate = offer.endDate
      ..isActive = offer.isActive
      ..targetType = offer.targetType
      ..targetIds = offer.targetIds.map((e) => e.toString()).toList()
      ..minOrderValue = offer.minOrderValue
      ..maxDiscount = offer.maxDiscount
      ..isReal = offer.isReal
      ..isSale = offer.isSale
      ..usageLimit = offer.usageLimit
      ..minQuantity = offer.minQuantity;
  }

  // Convert to Domain Model
  Offer toOffer() {
    return Offer(
      id: offerId ?? 0,
      code: code,
      title: title ?? '',
      description: description ?? '',
      discountType: discountType ?? 'percentage',
      discountValue: discountValue ?? 0.0,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive ?? true,
      targetType: targetType ?? 'all',
      targetIds: targetIds ?? [], // Pass back as dynamic
      minOrderValue: minOrderValue,
      maxDiscount: maxDiscount,
      isReal: isReal ?? true,
      isSale: isSale ?? false,
      usageLimit: usageLimit ?? 0,
      minQuantity: minQuantity ?? 1,
    );
  }
}
