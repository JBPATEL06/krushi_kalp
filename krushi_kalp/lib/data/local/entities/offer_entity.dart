import 'package:isar/isar.dart';
import 'package:krushi_kalp/domain/models/offer.dart';

part 'offer_entity.g.dart';

@collection
class OfferEntity {
  @Index(unique: true, replace: true)
  Id id = Isar.autoIncrement;

  late int offerId;
  String? code;
  late String title;
  late String description;
  late String discountType;
  late double discountValue;
  DateTime? startDate;
  DateTime? endDate;
  late bool isActive;
  late String targetType;
  late List<String>
      targetIds; // Isar doesn't support List<dynamic>, so we map to strings
  double? minOrderValue;
  double? maxDiscount;
  late bool isReal;
  late bool isSale;
  late int usageLimit;
  late int minQuantity;

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
      id: offerId,
      code: code,
      title: title,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      targetType: targetType,
      targetIds: targetIds, // Pass back as dynamic
      minOrderValue: minOrderValue,
      maxDiscount: maxDiscount,
      isReal: isReal,
      isSale: isSale,
      usageLimit: usageLimit,
      minQuantity: minQuantity,
    );
  }
}
