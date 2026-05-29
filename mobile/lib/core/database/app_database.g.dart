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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsCacheTable accountsCache = $AccountsCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [accountsCache];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsCacheTableTableManager get accountsCache =>
      $$AccountsCacheTableTableManager(_db, _db.accountsCache);
}
