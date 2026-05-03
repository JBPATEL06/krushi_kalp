// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOfferEntityCollection on Isar {
  IsarCollection<OfferEntity> get offerEntitys => this.collection();
}

const OfferEntitySchema = CollectionSchema(
  name: r'OfferEntity',
  id: 3403297649535041640,
  properties: {
    r'code': PropertySchema(
      id: 0,
      name: r'code',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'discountType': PropertySchema(
      id: 2,
      name: r'discountType',
      type: IsarType.string,
    ),
    r'discountValue': PropertySchema(
      id: 3,
      name: r'discountValue',
      type: IsarType.double,
    ),
    r'endDate': PropertySchema(
      id: 4,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(
      id: 5,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isReal': PropertySchema(
      id: 6,
      name: r'isReal',
      type: IsarType.bool,
    ),
    r'isSale': PropertySchema(
      id: 7,
      name: r'isSale',
      type: IsarType.bool,
    ),
    r'maxDiscount': PropertySchema(
      id: 8,
      name: r'maxDiscount',
      type: IsarType.double,
    ),
    r'minOrderValue': PropertySchema(
      id: 9,
      name: r'minOrderValue',
      type: IsarType.double,
    ),
    r'minQuantity': PropertySchema(
      id: 10,
      name: r'minQuantity',
      type: IsarType.long,
    ),
    r'offerId': PropertySchema(
      id: 11,
      name: r'offerId',
      type: IsarType.long,
    ),
    r'startDate': PropertySchema(
      id: 12,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'targetIds': PropertySchema(
      id: 13,
      name: r'targetIds',
      type: IsarType.stringList,
    ),
    r'targetType': PropertySchema(
      id: 14,
      name: r'targetType',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 15,
      name: r'title',
      type: IsarType.string,
    ),
    r'usageLimit': PropertySchema(
      id: 16,
      name: r'usageLimit',
      type: IsarType.long,
    )
  },
  estimateSize: _offerEntityEstimateSize,
  serialize: _offerEntitySerialize,
  deserialize: _offerEntityDeserialize,
  deserializeProp: _offerEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _offerEntityGetId,
  getLinks: _offerEntityGetLinks,
  attach: _offerEntityAttach,
  version: '3.3.2',
);

int _offerEntityEstimateSize(
  OfferEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.code;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.discountType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.targetIds;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final value = object.targetType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _offerEntitySerialize(
  OfferEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.code);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.discountType);
  writer.writeDouble(offsets[3], object.discountValue);
  writer.writeDateTime(offsets[4], object.endDate);
  writer.writeBool(offsets[5], object.isActive);
  writer.writeBool(offsets[6], object.isReal);
  writer.writeBool(offsets[7], object.isSale);
  writer.writeDouble(offsets[8], object.maxDiscount);
  writer.writeDouble(offsets[9], object.minOrderValue);
  writer.writeLong(offsets[10], object.minQuantity);
  writer.writeLong(offsets[11], object.offerId);
  writer.writeDateTime(offsets[12], object.startDate);
  writer.writeStringList(offsets[13], object.targetIds);
  writer.writeString(offsets[14], object.targetType);
  writer.writeString(offsets[15], object.title);
  writer.writeLong(offsets[16], object.usageLimit);
}

OfferEntity _offerEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OfferEntity();
  object.code = reader.readStringOrNull(offsets[0]);
  object.description = reader.readStringOrNull(offsets[1]);
  object.discountType = reader.readStringOrNull(offsets[2]);
  object.discountValue = reader.readDoubleOrNull(offsets[3]);
  object.endDate = reader.readDateTimeOrNull(offsets[4]);
  object.id = id;
  object.isActive = reader.readBoolOrNull(offsets[5]);
  object.isReal = reader.readBoolOrNull(offsets[6]);
  object.isSale = reader.readBoolOrNull(offsets[7]);
  object.maxDiscount = reader.readDoubleOrNull(offsets[8]);
  object.minOrderValue = reader.readDoubleOrNull(offsets[9]);
  object.minQuantity = reader.readLongOrNull(offsets[10]);
  object.offerId = reader.readLongOrNull(offsets[11]);
  object.startDate = reader.readDateTimeOrNull(offsets[12]);
  object.targetIds = reader.readStringList(offsets[13]);
  object.targetType = reader.readStringOrNull(offsets[14]);
  object.title = reader.readStringOrNull(offsets[15]);
  object.usageLimit = reader.readLongOrNull(offsets[16]);
  return object;
}

P _offerEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readStringList(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _offerEntityGetId(OfferEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _offerEntityGetLinks(OfferEntity object) {
  return [];
}

void _offerEntityAttach(
    IsarCollection<dynamic> col, Id id, OfferEntity object) {
  object.id = id;
}

extension OfferEntityQueryWhereSort
    on QueryBuilder<OfferEntity, OfferEntity, QWhere> {
  QueryBuilder<OfferEntity, OfferEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OfferEntityQueryWhere
    on QueryBuilder<OfferEntity, OfferEntity, QWhereClause> {
  QueryBuilder<OfferEntity, OfferEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OfferEntityQueryFilter
    on QueryBuilder<OfferEntity, OfferEntity, QFilterCondition> {
  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'code',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      codeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'code',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountType',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountType',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'discountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'discountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'discountType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'discountType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'discountType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discountValue',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discountValue',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountValueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountValueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountValueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      discountValueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> endDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      isActiveIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isActive',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      isActiveIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isActive',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> isActiveEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> isRealIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isReal',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      isRealIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isReal',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> isRealEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isReal',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> isSaleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isSale',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      isSaleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isSale',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> isSaleEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSale',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      maxDiscountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'maxDiscount',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      maxDiscountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'maxDiscount',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      maxDiscountEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      maxDiscountGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      maxDiscountLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxDiscount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      maxDiscountBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxDiscount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minOrderValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'minOrderValue',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minOrderValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'minOrderValue',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minOrderValueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minOrderValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minOrderValueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minOrderValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minOrderValueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minOrderValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minOrderValueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minOrderValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minQuantityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'minQuantity',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minQuantityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'minQuantity',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minQuantityEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minQuantityGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minQuantityLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minQuantity',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      minQuantityBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      offerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'offerId',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      offerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'offerId',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> offerIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'offerId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      offerIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'offerId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> offerIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'offerId',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> offerIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'offerId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      startDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      startDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      startDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetIds',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetIds',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetIds',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetIds',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'targetIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'targetType',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'targetType',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'targetType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'targetType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'targetType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'targetType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      targetTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'targetType',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      usageLimitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'usageLimit',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      usageLimitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'usageLimit',
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      usageLimitEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usageLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      usageLimitGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usageLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      usageLimitLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usageLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterFilterCondition>
      usageLimitBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usageLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OfferEntityQueryObject
    on QueryBuilder<OfferEntity, OfferEntity, QFilterCondition> {}

extension OfferEntityQueryLinks
    on QueryBuilder<OfferEntity, OfferEntity, QFilterCondition> {}

extension OfferEntityQuerySortBy
    on QueryBuilder<OfferEntity, OfferEntity, QSortBy> {
  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByDiscountType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountType', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy>
      sortByDiscountTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountType', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByDiscountValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountValue', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy>
      sortByDiscountValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountValue', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByIsReal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReal', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByIsRealDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReal', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByIsSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSale', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByIsSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSale', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByMaxDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxDiscount', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByMaxDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxDiscount', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByMinOrderValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOrderValue', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy>
      sortByMinOrderValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOrderValue', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByMinQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minQuantity', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByMinQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minQuantity', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByTargetType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetType', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByTargetTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetType', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByUsageLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageLimit', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> sortByUsageLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageLimit', Sort.desc);
    });
  }
}

extension OfferEntityQuerySortThenBy
    on QueryBuilder<OfferEntity, OfferEntity, QSortThenBy> {
  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByDiscountType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountType', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy>
      thenByDiscountTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountType', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByDiscountValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountValue', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy>
      thenByDiscountValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountValue', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIsReal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReal', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIsRealDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReal', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIsSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSale', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByIsSaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSale', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByMaxDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxDiscount', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByMaxDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxDiscount', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByMinOrderValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOrderValue', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy>
      thenByMinOrderValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minOrderValue', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByMinQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minQuantity', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByMinQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minQuantity', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByOfferIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offerId', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByTargetType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetType', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByTargetTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetType', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByUsageLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageLimit', Sort.asc);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QAfterSortBy> thenByUsageLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageLimit', Sort.desc);
    });
  }
}

extension OfferEntityQueryWhereDistinct
    on QueryBuilder<OfferEntity, OfferEntity, QDistinct> {
  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByDiscountType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByDiscountValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountValue');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByIsReal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isReal');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByIsSale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSale');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByMaxDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxDiscount');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByMinOrderValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minOrderValue');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByMinQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minQuantity');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByOfferId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offerId');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByTargetIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetIds');
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByTargetType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfferEntity, OfferEntity, QDistinct> distinctByUsageLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usageLimit');
    });
  }
}

extension OfferEntityQueryProperty
    on QueryBuilder<OfferEntity, OfferEntity, QQueryProperty> {
  QueryBuilder<OfferEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OfferEntity, String?, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<OfferEntity, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<OfferEntity, String?, QQueryOperations> discountTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountType');
    });
  }

  QueryBuilder<OfferEntity, double?, QQueryOperations> discountValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountValue');
    });
  }

  QueryBuilder<OfferEntity, DateTime?, QQueryOperations> endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<OfferEntity, bool?, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<OfferEntity, bool?, QQueryOperations> isRealProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isReal');
    });
  }

  QueryBuilder<OfferEntity, bool?, QQueryOperations> isSaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSale');
    });
  }

  QueryBuilder<OfferEntity, double?, QQueryOperations> maxDiscountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxDiscount');
    });
  }

  QueryBuilder<OfferEntity, double?, QQueryOperations> minOrderValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minOrderValue');
    });
  }

  QueryBuilder<OfferEntity, int?, QQueryOperations> minQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minQuantity');
    });
  }

  QueryBuilder<OfferEntity, int?, QQueryOperations> offerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offerId');
    });
  }

  QueryBuilder<OfferEntity, DateTime?, QQueryOperations> startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<OfferEntity, List<String>?, QQueryOperations>
      targetIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetIds');
    });
  }

  QueryBuilder<OfferEntity, String?, QQueryOperations> targetTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetType');
    });
  }

  QueryBuilder<OfferEntity, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<OfferEntity, int?, QQueryOperations> usageLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usageLimit');
    });
  }
}
