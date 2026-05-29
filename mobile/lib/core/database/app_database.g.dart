// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsCacheTable extends AccountsCache
    with TableInfo<$AccountsCacheTable, AccountsCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFourMeta = const VerificationMeta(
    'lastFour',
  );
  @override
  late final GeneratedColumn<String> lastFour = GeneratedColumn<String>(
    'last_four',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startingBalanceMeta = const VerificationMeta(
    'startingBalance',
  );
  @override
  late final GeneratedColumn<int> startingBalance = GeneratedColumn<int>(
    'starting_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<int> currentBalance = GeneratedColumn<int>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interestRateMeta = const VerificationMeta(
    'interestRate',
  );
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    ownerUserId,
    name,
    accountType,
    institution,
    lastFour,
    currency,
    startingBalance,
    currentBalance,
    creditLimit,
    isActive,
    color,
    interestRate,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountsCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUserIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    }
    if (data.containsKey('last_four')) {
      context.handle(
        _lastFourMeta,
        lastFour.isAcceptableOrUnknown(data['last_four']!, _lastFourMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('starting_balance')) {
      context.handle(
        _startingBalanceMeta,
        startingBalance.isAcceptableOrUnknown(
          data['starting_balance']!,
          _startingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentBalanceMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
        _interestRateMeta,
        interestRate.isAcceptableOrUnknown(
          data['interest_rate']!,
          _interestRateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountsCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      ),
      lastFour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_four'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      startingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_balance'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_balance'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AccountsCacheTable createAlias(String alias) {
    return $AccountsCacheTable(attachedDatabase, alias);
  }
}

class AccountsCacheRow extends DataClass
    implements Insertable<AccountsCacheRow> {
  final String id;
  final String householdId;
  final String ownerUserId;
  final String name;

  /// Stores the dbValue of [AccountType] (e.g. 'checking',
  /// 'credit_card'). The Dart-side AccountType.values lookup is in
  /// the repository's row→Account mapper.
  final String accountType;
  final String? institution;
  final String? lastFour;
  final String currency;
  final int startingBalance;
  final int currentBalance;
  final int? creditLimit;
  final bool isActive;
  final String? color;
  final double? interestRate;

  /// Server-side timestamps. Drift stores DateTime as Unix epoch
  /// seconds in UTC by default, which round-trips cleanly with
  /// Postgres TIMESTAMPTZ via `.toUtc()`.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Drift-only: when we last pulled this row from the server.
  /// Phase 2 surfaces this as "last updated X minutes ago" on the
  /// accounts screen; Phase 4+ uses it for stale-eviction.
  final DateTime cachedAt;
  const AccountsCacheRow({
    required this.id,
    required this.householdId,
    required this.ownerUserId,
    required this.name,
    required this.accountType,
    this.institution,
    this.lastFour,
    required this.currency,
    required this.startingBalance,
    required this.currentBalance,
    this.creditLimit,
    required this.isActive,
    this.color,
    this.interestRate,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['owner_user_id'] = Variable<String>(ownerUserId);
    map['name'] = Variable<String>(name);
    map['account_type'] = Variable<String>(accountType);
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    if (!nullToAbsent || lastFour != null) {
      map['last_four'] = Variable<String>(lastFour);
    }
    map['currency'] = Variable<String>(currency);
    map['starting_balance'] = Variable<int>(startingBalance);
    map['current_balance'] = Variable<int>(currentBalance);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || interestRate != null) {
      map['interest_rate'] = Variable<double>(interestRate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AccountsCacheCompanion toCompanion(bool nullToAbsent) {
    return AccountsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      ownerUserId: Value(ownerUserId),
      name: Value(name),
      accountType: Value(accountType),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      lastFour: lastFour == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFour),
      currency: Value(currency),
      startingBalance: Value(startingBalance),
      currentBalance: Value(currentBalance),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      isActive: Value(isActive),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      interestRate: interestRate == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory AccountsCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsCacheRow(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      ownerUserId: serializer.fromJson<String>(json['ownerUserId']),
      name: serializer.fromJson<String>(json['name']),
      accountType: serializer.fromJson<String>(json['accountType']),
      institution: serializer.fromJson<String?>(json['institution']),
      lastFour: serializer.fromJson<String?>(json['lastFour']),
      currency: serializer.fromJson<String>(json['currency']),
      startingBalance: serializer.fromJson<int>(json['startingBalance']),
      currentBalance: serializer.fromJson<int>(json['currentBalance']),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      color: serializer.fromJson<String?>(json['color']),
      interestRate: serializer.fromJson<double?>(json['interestRate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'ownerUserId': serializer.toJson<String>(ownerUserId),
      'name': serializer.toJson<String>(name),
      'accountType': serializer.toJson<String>(accountType),
      'institution': serializer.toJson<String?>(institution),
      'lastFour': serializer.toJson<String?>(lastFour),
      'currency': serializer.toJson<String>(currency),
      'startingBalance': serializer.toJson<int>(startingBalance),
      'currentBalance': serializer.toJson<int>(currentBalance),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'isActive': serializer.toJson<bool>(isActive),
      'color': serializer.toJson<String?>(color),
      'interestRate': serializer.toJson<double?>(interestRate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  AccountsCacheRow copyWith({
    String? id,
    String? householdId,
    String? ownerUserId,
    String? name,
    String? accountType,
    Value<String?> institution = const Value.absent(),
    Value<String?> lastFour = const Value.absent(),
    String? currency,
    int? startingBalance,
    int? currentBalance,
    Value<int?> creditLimit = const Value.absent(),
    bool? isActive,
    Value<String?> color = const Value.absent(),
    Value<double?> interestRate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => AccountsCacheRow(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    ownerUserId: ownerUserId ?? this.ownerUserId,
    name: name ?? this.name,
    accountType: accountType ?? this.accountType,
    institution: institution.present ? institution.value : this.institution,
    lastFour: lastFour.present ? lastFour.value : this.lastFour,
    currency: currency ?? this.currency,
    startingBalance: startingBalance ?? this.startingBalance,
    currentBalance: currentBalance ?? this.currentBalance,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    isActive: isActive ?? this.isActive,
    color: color.present ? color.value : this.color,
    interestRate: interestRate.present ? interestRate.value : this.interestRate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  AccountsCacheRow copyWithCompanion(AccountsCacheCompanion data) {
    return AccountsCacheRow(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      name: data.name.present ? data.name.value : this.name,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      lastFour: data.lastFour.present ? data.lastFour.value : this.lastFour,
      currency: data.currency.present ? data.currency.value : this.currency,
      startingBalance: data.startingBalance.present
          ? data.startingBalance.value
          : this.startingBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      color: data.color.present ? data.color.value : this.color,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCacheRow(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('institution: $institution, ')
          ..write('lastFour: $lastFour, ')
          ..write('currency: $currency, ')
          ..write('startingBalance: $startingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('isActive: $isActive, ')
          ..write('color: $color, ')
          ..write('interestRate: $interestRate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    ownerUserId,
    name,
    accountType,
    institution,
    lastFour,
    currency,
    startingBalance,
    currentBalance,
    creditLimit,
    isActive,
    color,
    interestRate,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsCacheRow &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.ownerUserId == this.ownerUserId &&
          other.name == this.name &&
          other.accountType == this.accountType &&
          other.institution == this.institution &&
          other.lastFour == this.lastFour &&
          other.currency == this.currency &&
          other.startingBalance == this.startingBalance &&
          other.currentBalance == this.currentBalance &&
          other.creditLimit == this.creditLimit &&
          other.isActive == this.isActive &&
          other.color == this.color &&
          other.interestRate == this.interestRate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class AccountsCacheCompanion extends UpdateCompanion<AccountsCacheRow> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> ownerUserId;
  final Value<String> name;
  final Value<String> accountType;
  final Value<String?> institution;
  final Value<String?> lastFour;
  final Value<String> currency;
  final Value<int> startingBalance;
  final Value<int> currentBalance;
  final Value<int?> creditLimit;
  final Value<bool> isActive;
  final Value<String?> color;
  final Value<double?> interestRate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AccountsCacheCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.name = const Value.absent(),
    this.accountType = const Value.absent(),
    this.institution = const Value.absent(),
    this.lastFour = const Value.absent(),
    this.currency = const Value.absent(),
    this.startingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.color = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCacheCompanion.insert({
    required String id,
    required String householdId,
    required String ownerUserId,
    required String name,
    required String accountType,
    this.institution = const Value.absent(),
    this.lastFour = const Value.absent(),
    required String currency,
    this.startingBalance = const Value.absent(),
    required int currentBalance,
    this.creditLimit = const Value.absent(),
    required bool isActive,
    this.color = const Value.absent(),
    this.interestRate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       ownerUserId = Value(ownerUserId),
       name = Value(name),
       accountType = Value(accountType),
       currency = Value(currency),
       currentBalance = Value(currentBalance),
       isActive = Value(isActive),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<AccountsCacheRow> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? ownerUserId,
    Expression<String>? name,
    Expression<String>? accountType,
    Expression<String>? institution,
    Expression<String>? lastFour,
    Expression<String>? currency,
    Expression<int>? startingBalance,
    Expression<int>? currentBalance,
    Expression<int>? creditLimit,
    Expression<bool>? isActive,
    Expression<String>? color,
    Expression<double>? interestRate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (name != null) 'name': name,
      if (accountType != null) 'account_type': accountType,
      if (institution != null) 'institution': institution,
      if (lastFour != null) 'last_four': lastFour,
      if (currency != null) 'currency': currency,
      if (startingBalance != null) 'starting_balance': startingBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (isActive != null) 'is_active': isActive,
      if (color != null) 'color': color,
      if (interestRate != null) 'interest_rate': interestRate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? ownerUserId,
    Value<String>? name,
    Value<String>? accountType,
    Value<String?>? institution,
    Value<String?>? lastFour,
    Value<String>? currency,
    Value<int>? startingBalance,
    Value<int>? currentBalance,
    Value<int?>? creditLimit,
    Value<bool>? isActive,
    Value<String?>? color,
    Value<double?>? interestRate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return AccountsCacheCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      institution: institution ?? this.institution,
      lastFour: lastFour ?? this.lastFour,
      currency: currency ?? this.currency,
      startingBalance: startingBalance ?? this.startingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      interestRate: interestRate ?? this.interestRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (lastFour.present) {
      map['last_four'] = Variable<String>(lastFour.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (startingBalance.present) {
      map['starting_balance'] = Variable<int>(startingBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<int>(currentBalance.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCacheCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('institution: $institution, ')
          ..write('lastFour: $lastFour, ')
          ..write('currency: $currency, ')
          ..write('startingBalance: $startingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('isActive: $isActive, ')
          ..write('color: $color, ')
          ..write('interestRate: $interestRate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesCacheTable extends CategoriesCache
    with TableInfo<$CategoriesCacheTable, CategoriesCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isIncomeMeta = const VerificationMeta(
    'isIncome',
  );
  @override
  late final GeneratedColumn<bool> isIncome = GeneratedColumn<bool>(
    'is_income',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_income" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    name,
    parentId,
    icon,
    color,
    isIncome,
    sortOrder,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoriesCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_income')) {
      context.handle(
        _isIncomeMeta,
        isIncome.isAcceptableOrUnknown(data['is_income']!, _isIncomeMeta),
      );
    } else if (isInserting) {
      context.missing(_isIncomeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      isIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_income'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CategoriesCacheTable createAlias(String alias) {
    return $CategoriesCacheTable(attachedDatabase, alias);
  }
}

class CategoriesCacheRow extends DataClass
    implements Insertable<CategoriesCacheRow> {
  final String id;
  final String? householdId;
  final String name;
  final String? parentId;
  final String? icon;
  final String? color;
  final bool isIncome;
  final int sortOrder;
  final DateTime cachedAt;
  const CategoriesCacheRow({
    required this.id,
    this.householdId,
    required this.name,
    this.parentId,
    this.icon,
    this.color,
    required this.isIncome,
    required this.sortOrder,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['is_income'] = Variable<bool>(isIncome);
    map['sort_order'] = Variable<int>(sortOrder);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CategoriesCacheCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCacheCompanion(
      id: Value(id),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isIncome: Value(isIncome),
      sortOrder: Value(sortOrder),
      cachedAt: Value(cachedAt),
    );
  }

  factory CategoriesCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesCacheRow(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      isIncome: serializer.fromJson<bool>(json['isIncome']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String?>(householdId),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'isIncome': serializer.toJson<bool>(isIncome),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CategoriesCacheRow copyWith({
    String? id,
    Value<String?> householdId = const Value.absent(),
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    bool? isIncome,
    int? sortOrder,
    DateTime? cachedAt,
  }) => CategoriesCacheRow(
    id: id ?? this.id,
    householdId: householdId.present ? householdId.value : this.householdId,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    isIncome: isIncome ?? this.isIncome,
    sortOrder: sortOrder ?? this.sortOrder,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CategoriesCacheRow copyWithCompanion(CategoriesCacheCompanion data) {
    return CategoriesCacheRow(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isIncome: data.isIncome.present ? data.isIncome.value : this.isIncome,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCacheRow(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isIncome: $isIncome, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    name,
    parentId,
    icon,
    color,
    isIncome,
    sortOrder,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesCacheRow &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isIncome == this.isIncome &&
          other.sortOrder == this.sortOrder &&
          other.cachedAt == this.cachedAt);
}

class CategoriesCacheCompanion extends UpdateCompanion<CategoriesCacheRow> {
  final Value<String> id;
  final Value<String?> householdId;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<bool> isIncome;
  final Value<int> sortOrder;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CategoriesCacheCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isIncome = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCacheCompanion.insert({
    required String id,
    this.householdId = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    required bool isIncome,
    required int sortOrder,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isIncome = Value(isIncome),
       sortOrder = Value(sortOrder),
       cachedAt = Value(cachedAt);
  static Insertable<CategoriesCacheRow> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<bool>? isIncome,
    Expression<int>? sortOrder,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isIncome != null) 'is_income': isIncome,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCacheCompanion copyWith({
    Value<String>? id,
    Value<String?>? householdId,
    Value<String>? name,
    Value<String?>? parentId,
    Value<String?>? icon,
    Value<String?>? color,
    Value<bool>? isIncome,
    Value<int>? sortOrder,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCacheCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncome: isIncome ?? this.isIncome,
      sortOrder: sortOrder ?? this.sortOrder,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isIncome.present) {
      map['is_income'] = Variable<bool>(isIncome.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCacheCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isIncome: $isIncome, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsCacheTable extends TransactionsCache
    with TableInfo<$TransactionsCacheTable, TransactionsCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _postedDateMeta = const VerificationMeta(
    'postedDate',
  );
  @override
  late final GeneratedColumn<DateTime> postedDate = GeneratedColumn<DateTime>(
    'posted_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredByMeta = const VerificationMeta(
    'enteredBy',
  );
  @override
  late final GeneratedColumn<String> enteredBy = GeneratedColumn<String>(
    'entered_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rateIdMeta = const VerificationMeta('rateId');
  @override
  late final GeneratedColumn<String> rateId = GeneratedColumn<String>(
    'rate_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mlModelConfidenceMeta = const VerificationMeta(
    'mlModelConfidence',
  );
  @override
  late final GeneratedColumn<int> mlModelConfidence = GeneratedColumn<int>(
    'ml_model_confidence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    accountId,
    amount,
    currency,
    description,
    merchant,
    categoryId,
    transactionDate,
    postedDate,
    pending,
    source,
    enteredBy,
    receiptId,
    rateId,
    notes,
    externalId,
    transferId,
    mlModelConfidence,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionsCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('posted_date')) {
      context.handle(
        _postedDateMeta,
        postedDate.isAcceptableOrUnknown(data['posted_date']!, _postedDateMeta),
      );
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    } else if (isInserting) {
      context.missing(_pendingMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('entered_by')) {
      context.handle(
        _enteredByMeta,
        enteredBy.isAcceptableOrUnknown(data['entered_by']!, _enteredByMeta),
      );
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    }
    if (data.containsKey('rate_id')) {
      context.handle(
        _rateIdMeta,
        rateId.isAcceptableOrUnknown(data['rate_id']!, _rateIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    }
    if (data.containsKey('ml_model_confidence')) {
      context.handle(
        _mlModelConfidenceMeta,
        mlModelConfidence.isAcceptableOrUnknown(
          data['ml_model_confidence']!,
          _mlModelConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionsCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      postedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}posted_date'],
      ),
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      enteredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_by'],
      ),
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      ),
      rateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      ),
      mlModelConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ml_model_confidence'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $TransactionsCacheTable createAlias(String alias) {
    return $TransactionsCacheTable(attachedDatabase, alias);
  }
}

class TransactionsCacheRow extends DataClass
    implements Insertable<TransactionsCacheRow> {
  final String id;
  final String householdId;
  final String accountId;

  /// Signed cents. Negative = expense, positive = income.
  final int amount;
  final String currency;
  final String description;
  final String? merchant;
  final String? categoryId;

  /// Stored as a UTC DateTime even though the server column is
  /// DATE. Drift's dateTime() round-trips fine — the time
  /// component is always 00:00 UTC.
  final DateTime transactionDate;
  final DateTime? postedDate;
  final bool pending;

  /// Stores the raw enum string ('manual', 'import', 'plaid',
  /// 'recurring') verbatim. Repository maps to/from Transaction.
  final String source;
  final String? enteredBy;
  final String? receiptId;
  final String? rateId;
  final String? notes;
  final String? externalId;
  final String? transferId;
  final int? mlModelConfidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime cachedAt;
  const TransactionsCacheRow({
    required this.id,
    required this.householdId,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.description,
    this.merchant,
    this.categoryId,
    required this.transactionDate,
    this.postedDate,
    required this.pending,
    required this.source,
    this.enteredBy,
    this.receiptId,
    this.rateId,
    this.notes,
    this.externalId,
    this.transferId,
    this.mlModelConfidence,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['account_id'] = Variable<String>(accountId);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || postedDate != null) {
      map['posted_date'] = Variable<DateTime>(postedDate);
    }
    map['pending'] = Variable<bool>(pending);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || enteredBy != null) {
      map['entered_by'] = Variable<String>(enteredBy);
    }
    if (!nullToAbsent || receiptId != null) {
      map['receipt_id'] = Variable<String>(receiptId);
    }
    if (!nullToAbsent || rateId != null) {
      map['rate_id'] = Variable<String>(rateId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || transferId != null) {
      map['transfer_id'] = Variable<String>(transferId);
    }
    if (!nullToAbsent || mlModelConfidence != null) {
      map['ml_model_confidence'] = Variable<int>(mlModelConfidence);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  TransactionsCacheCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      accountId: Value(accountId),
      amount: Value(amount),
      currency: Value(currency),
      description: Value(description),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      transactionDate: Value(transactionDate),
      postedDate: postedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(postedDate),
      pending: Value(pending),
      source: Value(source),
      enteredBy: enteredBy == null && nullToAbsent
          ? const Value.absent()
          : Value(enteredBy),
      receiptId: receiptId == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptId),
      rateId: rateId == null && nullToAbsent
          ? const Value.absent()
          : Value(rateId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      transferId: transferId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferId),
      mlModelConfidence: mlModelConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(mlModelConfidence),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory TransactionsCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsCacheRow(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      description: serializer.fromJson<String>(json['description']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      postedDate: serializer.fromJson<DateTime?>(json['postedDate']),
      pending: serializer.fromJson<bool>(json['pending']),
      source: serializer.fromJson<String>(json['source']),
      enteredBy: serializer.fromJson<String?>(json['enteredBy']),
      receiptId: serializer.fromJson<String?>(json['receiptId']),
      rateId: serializer.fromJson<String?>(json['rateId']),
      notes: serializer.fromJson<String?>(json['notes']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      transferId: serializer.fromJson<String?>(json['transferId']),
      mlModelConfidence: serializer.fromJson<int?>(json['mlModelConfidence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'accountId': serializer.toJson<String>(accountId),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'description': serializer.toJson<String>(description),
      'merchant': serializer.toJson<String?>(merchant),
      'categoryId': serializer.toJson<String?>(categoryId),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'postedDate': serializer.toJson<DateTime?>(postedDate),
      'pending': serializer.toJson<bool>(pending),
      'source': serializer.toJson<String>(source),
      'enteredBy': serializer.toJson<String?>(enteredBy),
      'receiptId': serializer.toJson<String?>(receiptId),
      'rateId': serializer.toJson<String?>(rateId),
      'notes': serializer.toJson<String?>(notes),
      'externalId': serializer.toJson<String?>(externalId),
      'transferId': serializer.toJson<String?>(transferId),
      'mlModelConfidence': serializer.toJson<int?>(mlModelConfidence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  TransactionsCacheRow copyWith({
    String? id,
    String? householdId,
    String? accountId,
    int? amount,
    String? currency,
    String? description,
    Value<String?> merchant = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    DateTime? transactionDate,
    Value<DateTime?> postedDate = const Value.absent(),
    bool? pending,
    String? source,
    Value<String?> enteredBy = const Value.absent(),
    Value<String?> receiptId = const Value.absent(),
    Value<String?> rateId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<String?> transferId = const Value.absent(),
    Value<int?> mlModelConfidence = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => TransactionsCacheRow(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    accountId: accountId ?? this.accountId,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    description: description ?? this.description,
    merchant: merchant.present ? merchant.value : this.merchant,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    transactionDate: transactionDate ?? this.transactionDate,
    postedDate: postedDate.present ? postedDate.value : this.postedDate,
    pending: pending ?? this.pending,
    source: source ?? this.source,
    enteredBy: enteredBy.present ? enteredBy.value : this.enteredBy,
    receiptId: receiptId.present ? receiptId.value : this.receiptId,
    rateId: rateId.present ? rateId.value : this.rateId,
    notes: notes.present ? notes.value : this.notes,
    externalId: externalId.present ? externalId.value : this.externalId,
    transferId: transferId.present ? transferId.value : this.transferId,
    mlModelConfidence: mlModelConfidence.present
        ? mlModelConfidence.value
        : this.mlModelConfidence,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  TransactionsCacheRow copyWithCompanion(TransactionsCacheCompanion data) {
    return TransactionsCacheRow(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      description: data.description.present
          ? data.description.value
          : this.description,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      postedDate: data.postedDate.present
          ? data.postedDate.value
          : this.postedDate,
      pending: data.pending.present ? data.pending.value : this.pending,
      source: data.source.present ? data.source.value : this.source,
      enteredBy: data.enteredBy.present ? data.enteredBy.value : this.enteredBy,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      rateId: data.rateId.present ? data.rateId.value : this.rateId,
      notes: data.notes.present ? data.notes.value : this.notes,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      mlModelConfidence: data.mlModelConfidence.present
          ? data.mlModelConfidence.value
          : this.mlModelConfidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCacheRow(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('merchant: $merchant, ')
          ..write('categoryId: $categoryId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('postedDate: $postedDate, ')
          ..write('pending: $pending, ')
          ..write('source: $source, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('receiptId: $receiptId, ')
          ..write('rateId: $rateId, ')
          ..write('notes: $notes, ')
          ..write('externalId: $externalId, ')
          ..write('transferId: $transferId, ')
          ..write('mlModelConfidence: $mlModelConfidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    householdId,
    accountId,
    amount,
    currency,
    description,
    merchant,
    categoryId,
    transactionDate,
    postedDate,
    pending,
    source,
    enteredBy,
    receiptId,
    rateId,
    notes,
    externalId,
    transferId,
    mlModelConfidence,
    createdAt,
    updatedAt,
    cachedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsCacheRow &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.description == this.description &&
          other.merchant == this.merchant &&
          other.categoryId == this.categoryId &&
          other.transactionDate == this.transactionDate &&
          other.postedDate == this.postedDate &&
          other.pending == this.pending &&
          other.source == this.source &&
          other.enteredBy == this.enteredBy &&
          other.receiptId == this.receiptId &&
          other.rateId == this.rateId &&
          other.notes == this.notes &&
          other.externalId == this.externalId &&
          other.transferId == this.transferId &&
          other.mlModelConfidence == this.mlModelConfidence &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class TransactionsCacheCompanion extends UpdateCompanion<TransactionsCacheRow> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> accountId;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String> description;
  final Value<String?> merchant;
  final Value<String?> categoryId;
  final Value<DateTime> transactionDate;
  final Value<DateTime?> postedDate;
  final Value<bool> pending;
  final Value<String> source;
  final Value<String?> enteredBy;
  final Value<String?> receiptId;
  final Value<String?> rateId;
  final Value<String?> notes;
  final Value<String?> externalId;
  final Value<String?> transferId;
  final Value<int?> mlModelConfidence;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const TransactionsCacheCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.merchant = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.postedDate = const Value.absent(),
    this.pending = const Value.absent(),
    this.source = const Value.absent(),
    this.enteredBy = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.rateId = const Value.absent(),
    this.notes = const Value.absent(),
    this.externalId = const Value.absent(),
    this.transferId = const Value.absent(),
    this.mlModelConfidence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCacheCompanion.insert({
    required String id,
    required String householdId,
    required String accountId,
    required int amount,
    required String currency,
    required String description,
    this.merchant = const Value.absent(),
    this.categoryId = const Value.absent(),
    required DateTime transactionDate,
    this.postedDate = const Value.absent(),
    required bool pending,
    required String source,
    this.enteredBy = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.rateId = const Value.absent(),
    this.notes = const Value.absent(),
    this.externalId = const Value.absent(),
    this.transferId = const Value.absent(),
    this.mlModelConfidence = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       accountId = Value(accountId),
       amount = Value(amount),
       currency = Value(currency),
       description = Value(description),
       transactionDate = Value(transactionDate),
       pending = Value(pending),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<TransactionsCacheRow> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? accountId,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? description,
    Expression<String>? merchant,
    Expression<String>? categoryId,
    Expression<DateTime>? transactionDate,
    Expression<DateTime>? postedDate,
    Expression<bool>? pending,
    Expression<String>? source,
    Expression<String>? enteredBy,
    Expression<String>? receiptId,
    Expression<String>? rateId,
    Expression<String>? notes,
    Expression<String>? externalId,
    Expression<String>? transferId,
    Expression<int>? mlModelConfidence,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (merchant != null) 'merchant': merchant,
      if (categoryId != null) 'category_id': categoryId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (postedDate != null) 'posted_date': postedDate,
      if (pending != null) 'pending': pending,
      if (source != null) 'source': source,
      if (enteredBy != null) 'entered_by': enteredBy,
      if (receiptId != null) 'receipt_id': receiptId,
      if (rateId != null) 'rate_id': rateId,
      if (notes != null) 'notes': notes,
      if (externalId != null) 'external_id': externalId,
      if (transferId != null) 'transfer_id': transferId,
      if (mlModelConfidence != null) 'ml_model_confidence': mlModelConfidence,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? accountId,
    Value<int>? amount,
    Value<String>? currency,
    Value<String>? description,
    Value<String?>? merchant,
    Value<String?>? categoryId,
    Value<DateTime>? transactionDate,
    Value<DateTime?>? postedDate,
    Value<bool>? pending,
    Value<String>? source,
    Value<String?>? enteredBy,
    Value<String?>? receiptId,
    Value<String?>? rateId,
    Value<String?>? notes,
    Value<String?>? externalId,
    Value<String?>? transferId,
    Value<int?>? mlModelConfidence,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCacheCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
      categoryId: categoryId ?? this.categoryId,
      transactionDate: transactionDate ?? this.transactionDate,
      postedDate: postedDate ?? this.postedDate,
      pending: pending ?? this.pending,
      source: source ?? this.source,
      enteredBy: enteredBy ?? this.enteredBy,
      receiptId: receiptId ?? this.receiptId,
      rateId: rateId ?? this.rateId,
      notes: notes ?? this.notes,
      externalId: externalId ?? this.externalId,
      transferId: transferId ?? this.transferId,
      mlModelConfidence: mlModelConfidence ?? this.mlModelConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (postedDate.present) {
      map['posted_date'] = Variable<DateTime>(postedDate.value);
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (enteredBy.present) {
      map['entered_by'] = Variable<String>(enteredBy.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (rateId.present) {
      map['rate_id'] = Variable<String>(rateId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (mlModelConfidence.present) {
      map['ml_model_confidence'] = Variable<int>(mlModelConfidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCacheCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('merchant: $merchant, ')
          ..write('categoryId: $categoryId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('postedDate: $postedDate, ')
          ..write('pending: $pending, ')
          ..write('source: $source, ')
          ..write('enteredBy: $enteredBy, ')
          ..write('receiptId: $receiptId, ')
          ..write('rateId: $rateId, ')
          ..write('notes: $notes, ')
          ..write('externalId: $externalId, ')
          ..write('transferId: $transferId, ')
          ..write('mlModelConfidence: $mlModelConfidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsCacheTable extends BudgetsCache
    with TableInfo<$BudgetsCacheTable, BudgetsCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    categoryId,
    amount,
    currency,
    period,
    startDate,
    endDate,
    createdBy,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetsCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetsCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetsCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $BudgetsCacheTable createAlias(String alias) {
    return $BudgetsCacheTable(attachedDatabase, alias);
  }
}

class BudgetsCacheRow extends DataClass implements Insertable<BudgetsCacheRow> {
  final String id;
  final String householdId;
  final String categoryId;
  final int amount;
  final String currency;

  /// Stores the BudgetPeriod dbValue verbatim ('weekly',
  /// 'monthly', etc.). Repository maps to/from the enum.
  final String period;
  final DateTime startDate;
  final DateTime? endDate;
  final String createdBy;
  final DateTime cachedAt;
  const BudgetsCacheRow({
    required this.id,
    required this.householdId,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.period,
    required this.startDate,
    this.endDate,
    required this.createdBy,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['category_id'] = Variable<String>(categoryId);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    map['period'] = Variable<String>(period);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  BudgetsCacheCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      categoryId: Value(categoryId),
      amount: Value(amount),
      currency: Value(currency),
      period: Value(period),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      createdBy: Value(createdBy),
      cachedAt: Value(cachedAt),
    );
  }

  factory BudgetsCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetsCacheRow(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      period: serializer.fromJson<String>(json['period']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'categoryId': serializer.toJson<String>(categoryId),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'period': serializer.toJson<String>(period),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'createdBy': serializer.toJson<String>(createdBy),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  BudgetsCacheRow copyWith({
    String? id,
    String? householdId,
    String? categoryId,
    int? amount,
    String? currency,
    String? period,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    String? createdBy,
    DateTime? cachedAt,
  }) => BudgetsCacheRow(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    categoryId: categoryId ?? this.categoryId,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    period: period ?? this.period,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    createdBy: createdBy ?? this.createdBy,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  BudgetsCacheRow copyWithCompanion(BudgetsCacheCompanion data) {
    return BudgetsCacheRow(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      period: data.period.present ? data.period.value : this.period,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCacheRow(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdBy: $createdBy, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    categoryId,
    amount,
    currency,
    period,
    startDate,
    endDate,
    createdBy,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetsCacheRow &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.period == this.period &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdBy == this.createdBy &&
          other.cachedAt == this.cachedAt);
}

class BudgetsCacheCompanion extends UpdateCompanion<BudgetsCacheRow> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> categoryId;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String> period;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String> createdBy;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const BudgetsCacheCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.period = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCacheCompanion.insert({
    required String id,
    required String householdId,
    required String categoryId,
    required int amount,
    this.currency = const Value.absent(),
    required String period,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    required String createdBy,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       categoryId = Value(categoryId),
       amount = Value(amount),
       period = Value(period),
       startDate = Value(startDate),
       createdBy = Value(createdBy),
       cachedAt = Value(cachedAt);
  static Insertable<BudgetsCacheRow> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? categoryId,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? period,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? createdBy,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (period != null) 'period': period,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdBy != null) 'created_by': createdBy,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? categoryId,
    Value<int>? amount,
    Value<String>? currency,
    Value<String>? period,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<String>? createdBy,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return BudgetsCacheCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCacheCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('period: $period, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdBy: $createdBy, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FxRatesCacheTable extends FxRatesCache
    with TableInfo<$FxRatesCacheTable, FxRatesCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FxRatesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromCurrencyMeta = const VerificationMeta(
    'fromCurrency',
  );
  @override
  late final GeneratedColumn<String> fromCurrency = GeneratedColumn<String>(
    'from_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toCurrencyMeta = const VerificationMeta(
    'toCurrency',
  );
  @override
  late final GeneratedColumn<String> toCurrency = GeneratedColumn<String>(
    'to_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _asOfDateMeta = const VerificationMeta(
    'asOfDate',
  );
  @override
  late final GeneratedColumn<DateTime> asOfDate = GeneratedColumn<DateTime>(
    'as_of_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    householdId,
    fromCurrency,
    toCurrency,
    asOfDate,
    rate,
    createdBy,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fx_rates_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<FxRatesCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('from_currency')) {
      context.handle(
        _fromCurrencyMeta,
        fromCurrency.isAcceptableOrUnknown(
          data['from_currency']!,
          _fromCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCurrencyMeta);
    }
    if (data.containsKey('to_currency')) {
      context.handle(
        _toCurrencyMeta,
        toCurrency.isAcceptableOrUnknown(data['to_currency']!, _toCurrencyMeta),
      );
    } else if (isInserting) {
      context.missing(_toCurrencyMeta);
    }
    if (data.containsKey('as_of_date')) {
      context.handle(
        _asOfDateMeta,
        asOfDate.isAcceptableOrUnknown(data['as_of_date']!, _asOfDateMeta),
      );
    } else if (isInserting) {
      context.missing(_asOfDateMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    householdId,
    fromCurrency,
    toCurrency,
    asOfDate,
  };
  @override
  FxRatesCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FxRatesCacheRow(
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      fromCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_currency'],
      )!,
      toCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_currency'],
      )!,
      asOfDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}as_of_date'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $FxRatesCacheTable createAlias(String alias) {
    return $FxRatesCacheTable(attachedDatabase, alias);
  }
}

class FxRatesCacheRow extends DataClass implements Insertable<FxRatesCacheRow> {
  final String householdId;
  final String fromCurrency;
  final String toCurrency;
  final DateTime asOfDate;

  /// Drift's `real()` is a double. The server stores
  /// NUMERIC(18,8); the JSON-wire-coerce in FxRate.fromJson
  /// already handles the string-to-double bridge.
  final double rate;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime cachedAt;
  const FxRatesCacheRow({
    required this.householdId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.asOfDate,
    required this.rate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['household_id'] = Variable<String>(householdId);
    map['from_currency'] = Variable<String>(fromCurrency);
    map['to_currency'] = Variable<String>(toCurrency);
    map['as_of_date'] = Variable<DateTime>(asOfDate);
    map['rate'] = Variable<double>(rate);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  FxRatesCacheCompanion toCompanion(bool nullToAbsent) {
    return FxRatesCacheCompanion(
      householdId: Value(householdId),
      fromCurrency: Value(fromCurrency),
      toCurrency: Value(toCurrency),
      asOfDate: Value(asOfDate),
      rate: Value(rate),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory FxRatesCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FxRatesCacheRow(
      householdId: serializer.fromJson<String>(json['householdId']),
      fromCurrency: serializer.fromJson<String>(json['fromCurrency']),
      toCurrency: serializer.fromJson<String>(json['toCurrency']),
      asOfDate: serializer.fromJson<DateTime>(json['asOfDate']),
      rate: serializer.fromJson<double>(json['rate']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'householdId': serializer.toJson<String>(householdId),
      'fromCurrency': serializer.toJson<String>(fromCurrency),
      'toCurrency': serializer.toJson<String>(toCurrency),
      'asOfDate': serializer.toJson<DateTime>(asOfDate),
      'rate': serializer.toJson<double>(rate),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  FxRatesCacheRow copyWith({
    String? householdId,
    String? fromCurrency,
    String? toCurrency,
    DateTime? asOfDate,
    double? rate,
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) => FxRatesCacheRow(
    householdId: householdId ?? this.householdId,
    fromCurrency: fromCurrency ?? this.fromCurrency,
    toCurrency: toCurrency ?? this.toCurrency,
    asOfDate: asOfDate ?? this.asOfDate,
    rate: rate ?? this.rate,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  FxRatesCacheRow copyWithCompanion(FxRatesCacheCompanion data) {
    return FxRatesCacheRow(
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      fromCurrency: data.fromCurrency.present
          ? data.fromCurrency.value
          : this.fromCurrency,
      toCurrency: data.toCurrency.present
          ? data.toCurrency.value
          : this.toCurrency,
      asOfDate: data.asOfDate.present ? data.asOfDate.value : this.asOfDate,
      rate: data.rate.present ? data.rate.value : this.rate,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FxRatesCacheRow(')
          ..write('householdId: $householdId, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('rate: $rate, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    householdId,
    fromCurrency,
    toCurrency,
    asOfDate,
    rate,
    createdBy,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxRatesCacheRow &&
          other.householdId == this.householdId &&
          other.fromCurrency == this.fromCurrency &&
          other.toCurrency == this.toCurrency &&
          other.asOfDate == this.asOfDate &&
          other.rate == this.rate &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class FxRatesCacheCompanion extends UpdateCompanion<FxRatesCacheRow> {
  final Value<String> householdId;
  final Value<String> fromCurrency;
  final Value<String> toCurrency;
  final Value<DateTime> asOfDate;
  final Value<double> rate;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const FxRatesCacheCompanion({
    this.householdId = const Value.absent(),
    this.fromCurrency = const Value.absent(),
    this.toCurrency = const Value.absent(),
    this.asOfDate = const Value.absent(),
    this.rate = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FxRatesCacheCompanion.insert({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    required DateTime asOfDate,
    required double rate,
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       fromCurrency = Value(fromCurrency),
       toCurrency = Value(toCurrency),
       asOfDate = Value(asOfDate),
       rate = Value(rate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<FxRatesCacheRow> custom({
    Expression<String>? householdId,
    Expression<String>? fromCurrency,
    Expression<String>? toCurrency,
    Expression<DateTime>? asOfDate,
    Expression<double>? rate,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (householdId != null) 'household_id': householdId,
      if (fromCurrency != null) 'from_currency': fromCurrency,
      if (toCurrency != null) 'to_currency': toCurrency,
      if (asOfDate != null) 'as_of_date': asOfDate,
      if (rate != null) 'rate': rate,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FxRatesCacheCompanion copyWith({
    Value<String>? householdId,
    Value<String>? fromCurrency,
    Value<String>? toCurrency,
    Value<DateTime>? asOfDate,
    Value<double>? rate,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return FxRatesCacheCompanion(
      householdId: householdId ?? this.householdId,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      asOfDate: asOfDate ?? this.asOfDate,
      rate: rate ?? this.rate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (fromCurrency.present) {
      map['from_currency'] = Variable<String>(fromCurrency.value);
    }
    if (toCurrency.present) {
      map['to_currency'] = Variable<String>(toCurrency.value);
    }
    if (asOfDate.present) {
      map['as_of_date'] = Variable<DateTime>(asOfDate.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FxRatesCacheCompanion(')
          ..write('householdId: $householdId, ')
          ..write('fromCurrency: $fromCurrency, ')
          ..write('toCurrency: $toCurrency, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('rate: $rate, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsCacheTable accountsCache = $AccountsCacheTable(this);
  late final $CategoriesCacheTable categoriesCache = $CategoriesCacheTable(
    this,
  );
  late final $TransactionsCacheTable transactionsCache =
      $TransactionsCacheTable(this);
  late final $BudgetsCacheTable budgetsCache = $BudgetsCacheTable(this);
  late final $FxRatesCacheTable fxRatesCache = $FxRatesCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accountsCache,
    categoriesCache,
    transactionsCache,
    budgetsCache,
    fxRatesCache,
  ];
}

typedef $$AccountsCacheTableCreateCompanionBuilder =
    AccountsCacheCompanion Function({
      required String id,
      required String householdId,
      required String ownerUserId,
      required String name,
      required String accountType,
      Value<String?> institution,
      Value<String?> lastFour,
      required String currency,
      Value<int> startingBalance,
      required int currentBalance,
      Value<int?> creditLimit,
      required bool isActive,
      Value<String?> color,
      Value<double?> interestRate,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$AccountsCacheTableUpdateCompanionBuilder =
    AccountsCacheCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> ownerUserId,
      Value<String> name,
      Value<String> accountType,
      Value<String?> institution,
      Value<String?> lastFour,
      Value<String> currency,
      Value<int> startingBalance,
      Value<int> currentBalance,
      Value<int?> creditLimit,
      Value<bool> isActive,
      Value<String?> color,
      Value<double?> interestRate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$AccountsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsCacheTable> {
  $$AccountsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFour => $composableBuilder(
    column: $table.lastFour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingBalance => $composableBuilder(
    column: $table.startingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsCacheTable> {
  $$AccountsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFour => $composableBuilder(
    column: $table.lastFour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingBalance => $composableBuilder(
    column: $table.startingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsCacheTable> {
  $$AccountsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFour =>
      $composableBuilder(column: $table.lastFour, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get startingBalance => $composableBuilder(
    column: $table.startingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AccountsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsCacheTable,
          AccountsCacheRow,
          $$AccountsCacheTableFilterComposer,
          $$AccountsCacheTableOrderingComposer,
          $$AccountsCacheTableAnnotationComposer,
          $$AccountsCacheTableCreateCompanionBuilder,
          $$AccountsCacheTableUpdateCompanionBuilder,
          (
            AccountsCacheRow,
            BaseReferences<
              _$AppDatabase,
              $AccountsCacheTable,
              AccountsCacheRow
            >,
          ),
          AccountsCacheRow,
          PrefetchHooks Function()
        > {
  $$AccountsCacheTableTableManager(_$AppDatabase db, $AccountsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> ownerUserId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<String?> lastFour = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> startingBalance = const Value.absent(),
                Value<int> currentBalance = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCacheCompanion(
                id: id,
                householdId: householdId,
                ownerUserId: ownerUserId,
                name: name,
                accountType: accountType,
                institution: institution,
                lastFour: lastFour,
                currency: currency,
                startingBalance: startingBalance,
                currentBalance: currentBalance,
                creditLimit: creditLimit,
                isActive: isActive,
                color: color,
                interestRate: interestRate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String ownerUserId,
                required String name,
                required String accountType,
                Value<String?> institution = const Value.absent(),
                Value<String?> lastFour = const Value.absent(),
                required String currency,
                Value<int> startingBalance = const Value.absent(),
                required int currentBalance,
                Value<int?> creditLimit = const Value.absent(),
                required bool isActive,
                Value<String?> color = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCacheCompanion.insert(
                id: id,
                householdId: householdId,
                ownerUserId: ownerUserId,
                name: name,
                accountType: accountType,
                institution: institution,
                lastFour: lastFour,
                currency: currency,
                startingBalance: startingBalance,
                currentBalance: currentBalance,
                creditLimit: creditLimit,
                isActive: isActive,
                color: color,
                interestRate: interestRate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsCacheTable,
      AccountsCacheRow,
      $$AccountsCacheTableFilterComposer,
      $$AccountsCacheTableOrderingComposer,
      $$AccountsCacheTableAnnotationComposer,
      $$AccountsCacheTableCreateCompanionBuilder,
      $$AccountsCacheTableUpdateCompanionBuilder,
      (
        AccountsCacheRow,
        BaseReferences<_$AppDatabase, $AccountsCacheTable, AccountsCacheRow>,
      ),
      AccountsCacheRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesCacheTableCreateCompanionBuilder =
    CategoriesCacheCompanion Function({
      required String id,
      Value<String?> householdId,
      required String name,
      Value<String?> parentId,
      Value<String?> icon,
      Value<String?> color,
      required bool isIncome,
      required int sortOrder,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CategoriesCacheTableUpdateCompanionBuilder =
    CategoriesCacheCompanion Function({
      Value<String> id,
      Value<String?> householdId,
      Value<String> name,
      Value<String?> parentId,
      Value<String?> icon,
      Value<String?> color,
      Value<bool> isIncome,
      Value<int> sortOrder,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CategoriesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesCacheTable> {
  $$CategoriesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIncome => $composableBuilder(
    column: $table.isIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesCacheTable> {
  $$CategoriesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIncome => $composableBuilder(
    column: $table.isIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesCacheTable> {
  $$CategoriesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isIncome =>
      $composableBuilder(column: $table.isIncome, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CategoriesCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesCacheTable,
          CategoriesCacheRow,
          $$CategoriesCacheTableFilterComposer,
          $$CategoriesCacheTableOrderingComposer,
          $$CategoriesCacheTableAnnotationComposer,
          $$CategoriesCacheTableCreateCompanionBuilder,
          $$CategoriesCacheTableUpdateCompanionBuilder,
          (
            CategoriesCacheRow,
            BaseReferences<
              _$AppDatabase,
              $CategoriesCacheTable,
              CategoriesCacheRow
            >,
          ),
          CategoriesCacheRow,
          PrefetchHooks Function()
        > {
  $$CategoriesCacheTableTableManager(
    _$AppDatabase db,
    $CategoriesCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<bool> isIncome = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCacheCompanion(
                id: id,
                householdId: householdId,
                name: name,
                parentId: parentId,
                icon: icon,
                color: color,
                isIncome: isIncome,
                sortOrder: sortOrder,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> householdId = const Value.absent(),
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                required bool isIncome,
                required int sortOrder,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCacheCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
                parentId: parentId,
                icon: icon,
                color: color,
                isIncome: isIncome,
                sortOrder: sortOrder,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesCacheTable,
      CategoriesCacheRow,
      $$CategoriesCacheTableFilterComposer,
      $$CategoriesCacheTableOrderingComposer,
      $$CategoriesCacheTableAnnotationComposer,
      $$CategoriesCacheTableCreateCompanionBuilder,
      $$CategoriesCacheTableUpdateCompanionBuilder,
      (
        CategoriesCacheRow,
        BaseReferences<
          _$AppDatabase,
          $CategoriesCacheTable,
          CategoriesCacheRow
        >,
      ),
      CategoriesCacheRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsCacheTableCreateCompanionBuilder =
    TransactionsCacheCompanion Function({
      required String id,
      required String householdId,
      required String accountId,
      required int amount,
      required String currency,
      required String description,
      Value<String?> merchant,
      Value<String?> categoryId,
      required DateTime transactionDate,
      Value<DateTime?> postedDate,
      required bool pending,
      required String source,
      Value<String?> enteredBy,
      Value<String?> receiptId,
      Value<String?> rateId,
      Value<String?> notes,
      Value<String?> externalId,
      Value<String?> transferId,
      Value<int?> mlModelConfidence,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$TransactionsCacheTableUpdateCompanionBuilder =
    TransactionsCacheCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> accountId,
      Value<int> amount,
      Value<String> currency,
      Value<String> description,
      Value<String?> merchant,
      Value<String?> categoryId,
      Value<DateTime> transactionDate,
      Value<DateTime?> postedDate,
      Value<bool> pending,
      Value<String> source,
      Value<String?> enteredBy,
      Value<String?> receiptId,
      Value<String?> rateId,
      Value<String?> notes,
      Value<String?> externalId,
      Value<String?> transferId,
      Value<int?> mlModelConfidence,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$TransactionsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsCacheTable> {
  $$TransactionsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postedDate => $composableBuilder(
    column: $table.postedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rateId => $composableBuilder(
    column: $table.rateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mlModelConfidence => $composableBuilder(
    column: $table.mlModelConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsCacheTable> {
  $$TransactionsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postedDate => $composableBuilder(
    column: $table.postedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pending => $composableBuilder(
    column: $table.pending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredBy => $composableBuilder(
    column: $table.enteredBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateId => $composableBuilder(
    column: $table.rateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mlModelConfidence => $composableBuilder(
    column: $table.mlModelConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsCacheTable> {
  $$TransactionsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get postedDate => $composableBuilder(
    column: $table.postedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pending =>
      $composableBuilder(column: $table.pending, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get enteredBy =>
      $composableBuilder(column: $table.enteredBy, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get rateId =>
      $composableBuilder(column: $table.rateId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mlModelConfidence => $composableBuilder(
    column: $table.mlModelConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$TransactionsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsCacheTable,
          TransactionsCacheRow,
          $$TransactionsCacheTableFilterComposer,
          $$TransactionsCacheTableOrderingComposer,
          $$TransactionsCacheTableAnnotationComposer,
          $$TransactionsCacheTableCreateCompanionBuilder,
          $$TransactionsCacheTableUpdateCompanionBuilder,
          (
            TransactionsCacheRow,
            BaseReferences<
              _$AppDatabase,
              $TransactionsCacheTable,
              TransactionsCacheRow
            >,
          ),
          TransactionsCacheRow,
          PrefetchHooks Function()
        > {
  $$TransactionsCacheTableTableManager(
    _$AppDatabase db,
    $TransactionsCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<DateTime?> postedDate = const Value.absent(),
                Value<bool> pending = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> enteredBy = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                Value<String?> rateId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> transferId = const Value.absent(),
                Value<int?> mlModelConfidence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCacheCompanion(
                id: id,
                householdId: householdId,
                accountId: accountId,
                amount: amount,
                currency: currency,
                description: description,
                merchant: merchant,
                categoryId: categoryId,
                transactionDate: transactionDate,
                postedDate: postedDate,
                pending: pending,
                source: source,
                enteredBy: enteredBy,
                receiptId: receiptId,
                rateId: rateId,
                notes: notes,
                externalId: externalId,
                transferId: transferId,
                mlModelConfidence: mlModelConfidence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String accountId,
                required int amount,
                required String currency,
                required String description,
                Value<String?> merchant = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required DateTime transactionDate,
                Value<DateTime?> postedDate = const Value.absent(),
                required bool pending,
                required String source,
                Value<String?> enteredBy = const Value.absent(),
                Value<String?> receiptId = const Value.absent(),
                Value<String?> rateId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> transferId = const Value.absent(),
                Value<int?> mlModelConfidence = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCacheCompanion.insert(
                id: id,
                householdId: householdId,
                accountId: accountId,
                amount: amount,
                currency: currency,
                description: description,
                merchant: merchant,
                categoryId: categoryId,
                transactionDate: transactionDate,
                postedDate: postedDate,
                pending: pending,
                source: source,
                enteredBy: enteredBy,
                receiptId: receiptId,
                rateId: rateId,
                notes: notes,
                externalId: externalId,
                transferId: transferId,
                mlModelConfidence: mlModelConfidence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsCacheTable,
      TransactionsCacheRow,
      $$TransactionsCacheTableFilterComposer,
      $$TransactionsCacheTableOrderingComposer,
      $$TransactionsCacheTableAnnotationComposer,
      $$TransactionsCacheTableCreateCompanionBuilder,
      $$TransactionsCacheTableUpdateCompanionBuilder,
      (
        TransactionsCacheRow,
        BaseReferences<
          _$AppDatabase,
          $TransactionsCacheTable,
          TransactionsCacheRow
        >,
      ),
      TransactionsCacheRow,
      PrefetchHooks Function()
    >;
typedef $$BudgetsCacheTableCreateCompanionBuilder =
    BudgetsCacheCompanion Function({
      required String id,
      required String householdId,
      required String categoryId,
      required int amount,
      Value<String> currency,
      required String period,
      required DateTime startDate,
      Value<DateTime?> endDate,
      required String createdBy,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$BudgetsCacheTableUpdateCompanionBuilder =
    BudgetsCacheCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> categoryId,
      Value<int> amount,
      Value<String> currency,
      Value<String> period,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<String> createdBy,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$BudgetsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsCacheTable> {
  $$BudgetsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsCacheTable> {
  $$BudgetsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsCacheTable> {
  $$BudgetsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$BudgetsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsCacheTable,
          BudgetsCacheRow,
          $$BudgetsCacheTableFilterComposer,
          $$BudgetsCacheTableOrderingComposer,
          $$BudgetsCacheTableAnnotationComposer,
          $$BudgetsCacheTableCreateCompanionBuilder,
          $$BudgetsCacheTableUpdateCompanionBuilder,
          (
            BudgetsCacheRow,
            BaseReferences<_$AppDatabase, $BudgetsCacheTable, BudgetsCacheRow>,
          ),
          BudgetsCacheRow,
          PrefetchHooks Function()
        > {
  $$BudgetsCacheTableTableManager(_$AppDatabase db, $BudgetsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCacheCompanion(
                id: id,
                householdId: householdId,
                categoryId: categoryId,
                amount: amount,
                currency: currency,
                period: period,
                startDate: startDate,
                endDate: endDate,
                createdBy: createdBy,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String categoryId,
                required int amount,
                Value<String> currency = const Value.absent(),
                required String period,
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                required String createdBy,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCacheCompanion.insert(
                id: id,
                householdId: householdId,
                categoryId: categoryId,
                amount: amount,
                currency: currency,
                period: period,
                startDate: startDate,
                endDate: endDate,
                createdBy: createdBy,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsCacheTable,
      BudgetsCacheRow,
      $$BudgetsCacheTableFilterComposer,
      $$BudgetsCacheTableOrderingComposer,
      $$BudgetsCacheTableAnnotationComposer,
      $$BudgetsCacheTableCreateCompanionBuilder,
      $$BudgetsCacheTableUpdateCompanionBuilder,
      (
        BudgetsCacheRow,
        BaseReferences<_$AppDatabase, $BudgetsCacheTable, BudgetsCacheRow>,
      ),
      BudgetsCacheRow,
      PrefetchHooks Function()
    >;
typedef $$FxRatesCacheTableCreateCompanionBuilder =
    FxRatesCacheCompanion Function({
      required String householdId,
      required String fromCurrency,
      required String toCurrency,
      required DateTime asOfDate,
      required double rate,
      Value<String?> createdBy,
      required DateTime createdAt,
      required DateTime updatedAt,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$FxRatesCacheTableUpdateCompanionBuilder =
    FxRatesCacheCompanion Function({
      Value<String> householdId,
      Value<String> fromCurrency,
      Value<String> toCurrency,
      Value<DateTime> asOfDate,
      Value<double> rate,
      Value<String?> createdBy,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$FxRatesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $FxRatesCacheTable> {
  $$FxRatesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromCurrency => $composableBuilder(
    column: $table.fromCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toCurrency => $composableBuilder(
    column: $table.toCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get asOfDate => $composableBuilder(
    column: $table.asOfDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FxRatesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $FxRatesCacheTable> {
  $$FxRatesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromCurrency => $composableBuilder(
    column: $table.fromCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toCurrency => $composableBuilder(
    column: $table.toCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get asOfDate => $composableBuilder(
    column: $table.asOfDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FxRatesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $FxRatesCacheTable> {
  $$FxRatesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromCurrency => $composableBuilder(
    column: $table.fromCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toCurrency => $composableBuilder(
    column: $table.toCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get asOfDate =>
      $composableBuilder(column: $table.asOfDate, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$FxRatesCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FxRatesCacheTable,
          FxRatesCacheRow,
          $$FxRatesCacheTableFilterComposer,
          $$FxRatesCacheTableOrderingComposer,
          $$FxRatesCacheTableAnnotationComposer,
          $$FxRatesCacheTableCreateCompanionBuilder,
          $$FxRatesCacheTableUpdateCompanionBuilder,
          (
            FxRatesCacheRow,
            BaseReferences<_$AppDatabase, $FxRatesCacheTable, FxRatesCacheRow>,
          ),
          FxRatesCacheRow,
          PrefetchHooks Function()
        > {
  $$FxRatesCacheTableTableManager(_$AppDatabase db, $FxRatesCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FxRatesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FxRatesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FxRatesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> householdId = const Value.absent(),
                Value<String> fromCurrency = const Value.absent(),
                Value<String> toCurrency = const Value.absent(),
                Value<DateTime> asOfDate = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FxRatesCacheCompanion(
                householdId: householdId,
                fromCurrency: fromCurrency,
                toCurrency: toCurrency,
                asOfDate: asOfDate,
                rate: rate,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String householdId,
                required String fromCurrency,
                required String toCurrency,
                required DateTime asOfDate,
                required double rate,
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => FxRatesCacheCompanion.insert(
                householdId: householdId,
                fromCurrency: fromCurrency,
                toCurrency: toCurrency,
                asOfDate: asOfDate,
                rate: rate,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FxRatesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FxRatesCacheTable,
      FxRatesCacheRow,
      $$FxRatesCacheTableFilterComposer,
      $$FxRatesCacheTableOrderingComposer,
      $$FxRatesCacheTableAnnotationComposer,
      $$FxRatesCacheTableCreateCompanionBuilder,
      $$FxRatesCacheTableUpdateCompanionBuilder,
      (
        FxRatesCacheRow,
        BaseReferences<_$AppDatabase, $FxRatesCacheTable, FxRatesCacheRow>,
      ),
      FxRatesCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsCacheTableTableManager get accountsCache =>
      $$AccountsCacheTableTableManager(_db, _db.accountsCache);
  $$CategoriesCacheTableTableManager get categoriesCache =>
      $$CategoriesCacheTableTableManager(_db, _db.categoriesCache);
  $$TransactionsCacheTableTableManager get transactionsCache =>
      $$TransactionsCacheTableTableManager(_db, _db.transactionsCache);
  $$BudgetsCacheTableTableManager get budgetsCache =>
      $$BudgetsCacheTableTableManager(_db, _db.budgetsCache);
  $$FxRatesCacheTableTableManager get fxRatesCache =>
      $$FxRatesCacheTableTableManager(_db, _db.fxRatesCache);
}
