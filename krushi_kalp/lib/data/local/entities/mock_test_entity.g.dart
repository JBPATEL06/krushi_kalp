// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_test_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMockTestEntityCollection on Isar {
  IsarCollection<MockTestEntity> get mockTestEntitys => this.collection();
}

const MockTestEntitySchema = CollectionSchema(
  name: r'MockTestEntity',
  id: -8979820732419359827,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'contentUrl': PropertySchema(
      id: 1,
      name: r'contentUrl',
      type: IsarType.string,
    ),
    r'coverImagePath': PropertySchema(
      id: 2,
      name: r'coverImagePath',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'discount': PropertySchema(
      id: 5,
      name: r'discount',
      type: IsarType.string,
    ),
    r'durationMinutes': PropertySchema(
      id: 6,
      name: r'durationMinutes',
      type: IsarType.long,
    ),
    r'filePath': PropertySchema(
      id: 7,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'language': PropertySchema(
      id: 8,
      name: r'language',
      type: IsarType.string,
    ),
    r'mrp': PropertySchema(
      id: 9,
      name: r'mrp',
      type: IsarType.double,
    ),
    r'negativeMarking': PropertySchema(
      id: 10,
      name: r'negativeMarking',
      type: IsarType.bool,
    ),
    r'negativeMarksPerQ': PropertySchema(
      id: 11,
      name: r'negativeMarksPerQ',
      type: IsarType.double,
    ),
    r'price': PropertySchema(
      id: 12,
      name: r'price',
      type: IsarType.double,
    ),
    r'signedUrl': PropertySchema(
      id: 13,
      name: r'signedUrl',
      type: IsarType.string,
    ),
    r'testId': PropertySchema(
      id: 14,
      name: r'testId',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 15,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalMarks': PropertySchema(
      id: 16,
      name: r'totalMarks',
      type: IsarType.long,
    ),
    r'totalQuestions': PropertySchema(
      id: 17,
      name: r'totalQuestions',
      type: IsarType.long,
    )
  },
  estimateSize: _mockTestEntityEstimateSize,
  serialize: _mockTestEntitySerialize,
  deserialize: _mockTestEntityDeserialize,
  deserializeProp: _mockTestEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _mockTestEntityGetId,
  getLinks: _mockTestEntityGetLinks,
  attach: _mockTestEntityAttach,
  version: '3.1.0+1',
);

int _mockTestEntityEstimateSize(
  MockTestEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  {
    final value = object.contentUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.coverImagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.description.length * 3;
  {
    final value = object.discount;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.filePath.length * 3;
  bytesCount += 3 + object.language.length * 3;
  {
    final value = object.signedUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _mockTestEntitySerialize(
  MockTestEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.contentUrl);
  writer.writeString(offsets[2], object.coverImagePath);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeString(offsets[4], object.description);
  writer.writeString(offsets[5], object.discount);
  writer.writeLong(offsets[6], object.durationMinutes);
  writer.writeString(offsets[7], object.filePath);
  writer.writeString(offsets[8], object.language);
  writer.writeDouble(offsets[9], object.mrp);
  writer.writeBool(offsets[10], object.negativeMarking);
  writer.writeDouble(offsets[11], object.negativeMarksPerQ);
  writer.writeDouble(offsets[12], object.price);
  writer.writeString(offsets[13], object.signedUrl);
  writer.writeLong(offsets[14], object.testId);
  writer.writeString(offsets[15], object.title);
  writer.writeLong(offsets[16], object.totalMarks);
  writer.writeLong(offsets[17], object.totalQuestions);
}

MockTestEntity _mockTestEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MockTestEntity();
  object.category = reader.readString(offsets[0]);
  object.contentUrl = reader.readStringOrNull(offsets[1]);
  object.coverImagePath = reader.readStringOrNull(offsets[2]);
  object.createdAt = reader.readDateTime(offsets[3]);
  object.description = reader.readString(offsets[4]);
  object.discount = reader.readStringOrNull(offsets[5]);
  object.durationMinutes = reader.readLongOrNull(offsets[6]);
  object.filePath = reader.readString(offsets[7]);
  object.id = id;
  object.language = reader.readString(offsets[8]);
  object.mrp = reader.readDoubleOrNull(offsets[9]);
  object.negativeMarking = reader.readBool(offsets[10]);
  object.negativeMarksPerQ = reader.readDouble(offsets[11]);
  object.price = reader.readDouble(offsets[12]);
  object.signedUrl = reader.readStringOrNull(offsets[13]);
  object.testId = reader.readLong(offsets[14]);
  object.title = reader.readString(offsets[15]);
  object.totalMarks = reader.readLong(offsets[16]);
  object.totalQuestions = reader.readLong(offsets[17]);
  return object;
}

P _mockTestEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mockTestEntityGetId(MockTestEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mockTestEntityGetLinks(MockTestEntity object) {
  return [];
}

void _mockTestEntityAttach(
    IsarCollection<dynamic> col, Id id, MockTestEntity object) {
  object.id = id;
}

extension MockTestEntityQueryWhereSort
    on QueryBuilder<MockTestEntity, MockTestEntity, QWhere> {
  QueryBuilder<MockTestEntity, MockTestEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MockTestEntityQueryWhere
    on QueryBuilder<MockTestEntity, MockTestEntity, QWhereClause> {
  QueryBuilder<MockTestEntity, MockTestEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterWhereClause> idBetween(
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

extension MockTestEntityQueryFilter
    on QueryBuilder<MockTestEntity, MockTestEntity, QFilterCondition> {
  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contentUrl',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contentUrl',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contentUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contentUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contentUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contentUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contentUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contentUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contentUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      contentUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contentUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'coverImagePath',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'coverImagePath',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coverImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coverImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coverImagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coverImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coverImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coverImagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coverImagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      coverImagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coverImagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'discount',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'discount',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'discount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'discount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'discount',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'discount',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discount',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      discountIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'discount',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      durationMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationMinutes',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      durationMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationMinutes',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      durationMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      durationMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      durationMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      durationMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'language',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'language',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'language',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      languageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'language',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      mrpIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mrp',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      mrpIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mrp',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      mrpEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mrp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      mrpGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mrp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      mrpLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mrp',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      mrpBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mrp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      negativeMarkingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'negativeMarking',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      negativeMarksPerQEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'negativeMarksPerQ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      negativeMarksPerQGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'negativeMarksPerQ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      negativeMarksPerQLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'negativeMarksPerQ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      negativeMarksPerQBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'negativeMarksPerQ',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'signedUrl',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'signedUrl',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'signedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'signedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'signedUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'signedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'signedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'signedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'signedUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signedUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      signedUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'signedUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      testIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'testId',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      testIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'testId',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      testIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'testId',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      testIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'testId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleEqualTo(
    String value, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleLessThan(
    String value, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleStartsWith(
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleEndsWith(
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

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalMarksEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalMarks',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalMarksGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalMarks',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalMarksLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalMarks',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalMarksBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalMarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalQuestionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalQuestions',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalQuestionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalQuestions',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalQuestionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalQuestions',
        value: value,
      ));
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterFilterCondition>
      totalQuestionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalQuestions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MockTestEntityQueryObject
    on QueryBuilder<MockTestEntity, MockTestEntity, QFilterCondition> {}

extension MockTestEntityQueryLinks
    on QueryBuilder<MockTestEntity, MockTestEntity, QFilterCondition> {}

extension MockTestEntityQuerySortBy
    on QueryBuilder<MockTestEntity, MockTestEntity, QSortBy> {
  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByContentUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentUrl', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByContentUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentUrl', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByCoverImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverImagePath', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByCoverImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverImagePath', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByMrp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mrp', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByMrpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mrp', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByNegativeMarking() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarking', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByNegativeMarkingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarking', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByNegativeMarksPerQ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarksPerQ', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByNegativeMarksPerQDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarksPerQ', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortBySignedUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedUrl', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortBySignedUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedUrl', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByTestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'testId', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByTestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'testId', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByTotalMarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMarks', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByTotalMarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMarks', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByTotalQuestions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      sortByTotalQuestionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.desc);
    });
  }
}

extension MockTestEntityQuerySortThenBy
    on QueryBuilder<MockTestEntity, MockTestEntity, QSortThenBy> {
  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByContentUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentUrl', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByContentUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentUrl', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByCoverImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverImagePath', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByCoverImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverImagePath', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discount', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByDurationMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMinutes', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByMrp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mrp', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByMrpDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mrp', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByNegativeMarking() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarking', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByNegativeMarkingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarking', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByNegativeMarksPerQ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarksPerQ', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByNegativeMarksPerQDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'negativeMarksPerQ', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenBySignedUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedUrl', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenBySignedUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signedUrl', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByTestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'testId', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByTestIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'testId', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByTotalMarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMarks', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByTotalMarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMarks', Sort.desc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByTotalQuestions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.asc);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QAfterSortBy>
      thenByTotalQuestionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalQuestions', Sort.desc);
    });
  }
}

extension MockTestEntityQueryWhereDistinct
    on QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> {
  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByContentUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByCoverImagePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverImagePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByDiscount(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discount', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByDurationMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMinutes');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByLanguage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'language', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByMrp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mrp');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByNegativeMarking() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'negativeMarking');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByNegativeMarksPerQ() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'negativeMarksPerQ');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctBySignedUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signedUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByTestId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'testId');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByTotalMarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalMarks');
    });
  }

  QueryBuilder<MockTestEntity, MockTestEntity, QDistinct>
      distinctByTotalQuestions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalQuestions');
    });
  }
}

extension MockTestEntityQueryProperty
    on QueryBuilder<MockTestEntity, MockTestEntity, QQueryProperty> {
  QueryBuilder<MockTestEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MockTestEntity, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<MockTestEntity, String?, QQueryOperations> contentUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentUrl');
    });
  }

  QueryBuilder<MockTestEntity, String?, QQueryOperations>
      coverImagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverImagePath');
    });
  }

  QueryBuilder<MockTestEntity, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MockTestEntity, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<MockTestEntity, String?, QQueryOperations> discountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discount');
    });
  }

  QueryBuilder<MockTestEntity, int?, QQueryOperations>
      durationMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMinutes');
    });
  }

  QueryBuilder<MockTestEntity, String, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<MockTestEntity, String, QQueryOperations> languageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'language');
    });
  }

  QueryBuilder<MockTestEntity, double?, QQueryOperations> mrpProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mrp');
    });
  }

  QueryBuilder<MockTestEntity, bool, QQueryOperations>
      negativeMarkingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'negativeMarking');
    });
  }

  QueryBuilder<MockTestEntity, double, QQueryOperations>
      negativeMarksPerQProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'negativeMarksPerQ');
    });
  }

  QueryBuilder<MockTestEntity, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<MockTestEntity, String?, QQueryOperations> signedUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signedUrl');
    });
  }

  QueryBuilder<MockTestEntity, int, QQueryOperations> testIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'testId');
    });
  }

  QueryBuilder<MockTestEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<MockTestEntity, int, QQueryOperations> totalMarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalMarks');
    });
  }

  QueryBuilder<MockTestEntity, int, QQueryOperations> totalQuestionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalQuestions');
    });
  }
}
