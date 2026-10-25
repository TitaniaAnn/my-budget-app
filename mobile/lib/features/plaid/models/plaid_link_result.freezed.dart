// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plaid_link_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaidExchangeResult {

 String get plaidItemId; PlaidInstitutionRef get institution; List<PlaidInsertedAccount> get insertedAccounts; List<PlaidSkippedAccount> get skippedAccounts;
/// Create a copy of PlaidExchangeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaidExchangeResultCopyWith<PlaidExchangeResult> get copyWith => _$PlaidExchangeResultCopyWithImpl<PlaidExchangeResult>(this as PlaidExchangeResult, _$identity);

  /// Serializes this PlaidExchangeResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaidExchangeResult&&(identical(other.plaidItemId, plaidItemId) || other.plaidItemId == plaidItemId)&&(identical(other.institution, institution) || other.institution == institution)&&const DeepCollectionEquality().equals(other.insertedAccounts, insertedAccounts)&&const DeepCollectionEquality().equals(other.skippedAccounts, skippedAccounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plaidItemId,institution,const DeepCollectionEquality().hash(insertedAccounts),const DeepCollectionEquality().hash(skippedAccounts));

@override
String toString() {
  return 'PlaidExchangeResult(plaidItemId: $plaidItemId, institution: $institution, insertedAccounts: $insertedAccounts, skippedAccounts: $skippedAccounts)';
}


}

/// @nodoc
abstract mixin class $PlaidExchangeResultCopyWith<$Res>  {
  factory $PlaidExchangeResultCopyWith(PlaidExchangeResult value, $Res Function(PlaidExchangeResult) _then) = _$PlaidExchangeResultCopyWithImpl;
@useResult
$Res call({
 String plaidItemId, PlaidInstitutionRef institution, List<PlaidInsertedAccount> insertedAccounts, List<PlaidSkippedAccount> skippedAccounts
});


$PlaidInstitutionRefCopyWith<$Res> get institution;

}
/// @nodoc
class _$PlaidExchangeResultCopyWithImpl<$Res>
    implements $PlaidExchangeResultCopyWith<$Res> {
  _$PlaidExchangeResultCopyWithImpl(this._self, this._then);

  final PlaidExchangeResult _self;
  final $Res Function(PlaidExchangeResult) _then;

/// Create a copy of PlaidExchangeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plaidItemId = null,Object? institution = null,Object? insertedAccounts = null,Object? skippedAccounts = null,}) {
  return _then(_self.copyWith(
plaidItemId: null == plaidItemId ? _self.plaidItemId : plaidItemId // ignore: cast_nullable_to_non_nullable
as String,institution: null == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as PlaidInstitutionRef,insertedAccounts: null == insertedAccounts ? _self.insertedAccounts : insertedAccounts // ignore: cast_nullable_to_non_nullable
as List<PlaidInsertedAccount>,skippedAccounts: null == skippedAccounts ? _self.skippedAccounts : skippedAccounts // ignore: cast_nullable_to_non_nullable
as List<PlaidSkippedAccount>,
  ));
}
/// Create a copy of PlaidExchangeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaidInstitutionRefCopyWith<$Res> get institution {
  
  return $PlaidInstitutionRefCopyWith<$Res>(_self.institution, (value) {
    return _then(_self.copyWith(institution: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaidExchangeResult].
extension PlaidExchangeResultPatterns on PlaidExchangeResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaidExchangeResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaidExchangeResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaidExchangeResult value)  $default,){
final _that = this;
switch (_that) {
case _PlaidExchangeResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaidExchangeResult value)?  $default,){
final _that = this;
switch (_that) {
case _PlaidExchangeResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plaidItemId,  PlaidInstitutionRef institution,  List<PlaidInsertedAccount> insertedAccounts,  List<PlaidSkippedAccount> skippedAccounts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaidExchangeResult() when $default != null:
return $default(_that.plaidItemId,_that.institution,_that.insertedAccounts,_that.skippedAccounts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plaidItemId,  PlaidInstitutionRef institution,  List<PlaidInsertedAccount> insertedAccounts,  List<PlaidSkippedAccount> skippedAccounts)  $default,) {final _that = this;
switch (_that) {
case _PlaidExchangeResult():
return $default(_that.plaidItemId,_that.institution,_that.insertedAccounts,_that.skippedAccounts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plaidItemId,  PlaidInstitutionRef institution,  List<PlaidInsertedAccount> insertedAccounts,  List<PlaidSkippedAccount> skippedAccounts)?  $default,) {final _that = this;
switch (_that) {
case _PlaidExchangeResult() when $default != null:
return $default(_that.plaidItemId,_that.institution,_that.insertedAccounts,_that.skippedAccounts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaidExchangeResult implements PlaidExchangeResult {
  const _PlaidExchangeResult({required this.plaidItemId, required this.institution, final  List<PlaidInsertedAccount> insertedAccounts = const [], final  List<PlaidSkippedAccount> skippedAccounts = const []}): _insertedAccounts = insertedAccounts,_skippedAccounts = skippedAccounts;
  factory _PlaidExchangeResult.fromJson(Map<String, dynamic> json) => _$PlaidExchangeResultFromJson(json);

@override final  String plaidItemId;
@override final  PlaidInstitutionRef institution;
 final  List<PlaidInsertedAccount> _insertedAccounts;
@override@JsonKey() List<PlaidInsertedAccount> get insertedAccounts {
  if (_insertedAccounts is EqualUnmodifiableListView) return _insertedAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_insertedAccounts);
}

 final  List<PlaidSkippedAccount> _skippedAccounts;
@override@JsonKey() List<PlaidSkippedAccount> get skippedAccounts {
  if (_skippedAccounts is EqualUnmodifiableListView) return _skippedAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skippedAccounts);
}


/// Create a copy of PlaidExchangeResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaidExchangeResultCopyWith<_PlaidExchangeResult> get copyWith => __$PlaidExchangeResultCopyWithImpl<_PlaidExchangeResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaidExchangeResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaidExchangeResult&&(identical(other.plaidItemId, plaidItemId) || other.plaidItemId == plaidItemId)&&(identical(other.institution, institution) || other.institution == institution)&&const DeepCollectionEquality().equals(other._insertedAccounts, _insertedAccounts)&&const DeepCollectionEquality().equals(other._skippedAccounts, _skippedAccounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plaidItemId,institution,const DeepCollectionEquality().hash(_insertedAccounts),const DeepCollectionEquality().hash(_skippedAccounts));

@override
String toString() {
  return 'PlaidExchangeResult(plaidItemId: $plaidItemId, institution: $institution, insertedAccounts: $insertedAccounts, skippedAccounts: $skippedAccounts)';
}


}

/// @nodoc
abstract mixin class _$PlaidExchangeResultCopyWith<$Res> implements $PlaidExchangeResultCopyWith<$Res> {
  factory _$PlaidExchangeResultCopyWith(_PlaidExchangeResult value, $Res Function(_PlaidExchangeResult) _then) = __$PlaidExchangeResultCopyWithImpl;
@override @useResult
$Res call({
 String plaidItemId, PlaidInstitutionRef institution, List<PlaidInsertedAccount> insertedAccounts, List<PlaidSkippedAccount> skippedAccounts
});


@override $PlaidInstitutionRefCopyWith<$Res> get institution;

}
/// @nodoc
class __$PlaidExchangeResultCopyWithImpl<$Res>
    implements _$PlaidExchangeResultCopyWith<$Res> {
  __$PlaidExchangeResultCopyWithImpl(this._self, this._then);

  final _PlaidExchangeResult _self;
  final $Res Function(_PlaidExchangeResult) _then;

/// Create a copy of PlaidExchangeResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plaidItemId = null,Object? institution = null,Object? insertedAccounts = null,Object? skippedAccounts = null,}) {
  return _then(_PlaidExchangeResult(
plaidItemId: null == plaidItemId ? _self.plaidItemId : plaidItemId // ignore: cast_nullable_to_non_nullable
as String,institution: null == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as PlaidInstitutionRef,insertedAccounts: null == insertedAccounts ? _self._insertedAccounts : insertedAccounts // ignore: cast_nullable_to_non_nullable
as List<PlaidInsertedAccount>,skippedAccounts: null == skippedAccounts ? _self._skippedAccounts : skippedAccounts // ignore: cast_nullable_to_non_nullable
as List<PlaidSkippedAccount>,
  ));
}

/// Create a copy of PlaidExchangeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaidInstitutionRefCopyWith<$Res> get institution {
  
  return $PlaidInstitutionRefCopyWith<$Res>(_self.institution, (value) {
    return _then(_self.copyWith(institution: value));
  });
}
}


/// @nodoc
mixin _$PlaidInstitutionRef {

 String get id; String get name;
/// Create a copy of PlaidInstitutionRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaidInstitutionRefCopyWith<PlaidInstitutionRef> get copyWith => _$PlaidInstitutionRefCopyWithImpl<PlaidInstitutionRef>(this as PlaidInstitutionRef, _$identity);

  /// Serializes this PlaidInstitutionRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaidInstitutionRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'PlaidInstitutionRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $PlaidInstitutionRefCopyWith<$Res>  {
  factory $PlaidInstitutionRefCopyWith(PlaidInstitutionRef value, $Res Function(PlaidInstitutionRef) _then) = _$PlaidInstitutionRefCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$PlaidInstitutionRefCopyWithImpl<$Res>
    implements $PlaidInstitutionRefCopyWith<$Res> {
  _$PlaidInstitutionRefCopyWithImpl(this._self, this._then);

  final PlaidInstitutionRef _self;
  final $Res Function(PlaidInstitutionRef) _then;

/// Create a copy of PlaidInstitutionRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaidInstitutionRef].
extension PlaidInstitutionRefPatterns on PlaidInstitutionRef {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaidInstitutionRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaidInstitutionRef() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaidInstitutionRef value)  $default,){
final _that = this;
switch (_that) {
case _PlaidInstitutionRef():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaidInstitutionRef value)?  $default,){
final _that = this;
switch (_that) {
case _PlaidInstitutionRef() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaidInstitutionRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _PlaidInstitutionRef():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _PlaidInstitutionRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaidInstitutionRef implements PlaidInstitutionRef {
  const _PlaidInstitutionRef({required this.id, required this.name});
  factory _PlaidInstitutionRef.fromJson(Map<String, dynamic> json) => _$PlaidInstitutionRefFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of PlaidInstitutionRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaidInstitutionRefCopyWith<_PlaidInstitutionRef> get copyWith => __$PlaidInstitutionRefCopyWithImpl<_PlaidInstitutionRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaidInstitutionRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaidInstitutionRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'PlaidInstitutionRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PlaidInstitutionRefCopyWith<$Res> implements $PlaidInstitutionRefCopyWith<$Res> {
  factory _$PlaidInstitutionRefCopyWith(_PlaidInstitutionRef value, $Res Function(_PlaidInstitutionRef) _then) = __$PlaidInstitutionRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$PlaidInstitutionRefCopyWithImpl<$Res>
    implements _$PlaidInstitutionRefCopyWith<$Res> {
  __$PlaidInstitutionRefCopyWithImpl(this._self, this._then);

  final _PlaidInstitutionRef _self;
  final $Res Function(_PlaidInstitutionRef) _then;

/// Create a copy of PlaidInstitutionRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_PlaidInstitutionRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlaidInsertedAccount {

 String get accountId; String get plaidAccountId; String get accountType; String get name;
/// Create a copy of PlaidInsertedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaidInsertedAccountCopyWith<PlaidInsertedAccount> get copyWith => _$PlaidInsertedAccountCopyWithImpl<PlaidInsertedAccount>(this as PlaidInsertedAccount, _$identity);

  /// Serializes this PlaidInsertedAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaidInsertedAccount&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.plaidAccountId, plaidAccountId) || other.plaidAccountId == plaidAccountId)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,plaidAccountId,accountType,name);

@override
String toString() {
  return 'PlaidInsertedAccount(accountId: $accountId, plaidAccountId: $plaidAccountId, accountType: $accountType, name: $name)';
}


}

/// @nodoc
abstract mixin class $PlaidInsertedAccountCopyWith<$Res>  {
  factory $PlaidInsertedAccountCopyWith(PlaidInsertedAccount value, $Res Function(PlaidInsertedAccount) _then) = _$PlaidInsertedAccountCopyWithImpl;
@useResult
$Res call({
 String accountId, String plaidAccountId, String accountType, String name
});




}
/// @nodoc
class _$PlaidInsertedAccountCopyWithImpl<$Res>
    implements $PlaidInsertedAccountCopyWith<$Res> {
  _$PlaidInsertedAccountCopyWithImpl(this._self, this._then);

  final PlaidInsertedAccount _self;
  final $Res Function(PlaidInsertedAccount) _then;

/// Create a copy of PlaidInsertedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? plaidAccountId = null,Object? accountType = null,Object? name = null,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,plaidAccountId: null == plaidAccountId ? _self.plaidAccountId : plaidAccountId // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaidInsertedAccount].
extension PlaidInsertedAccountPatterns on PlaidInsertedAccount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaidInsertedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaidInsertedAccount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaidInsertedAccount value)  $default,){
final _that = this;
switch (_that) {
case _PlaidInsertedAccount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaidInsertedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _PlaidInsertedAccount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String plaidAccountId,  String accountType,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaidInsertedAccount() when $default != null:
return $default(_that.accountId,_that.plaidAccountId,_that.accountType,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String plaidAccountId,  String accountType,  String name)  $default,) {final _that = this;
switch (_that) {
case _PlaidInsertedAccount():
return $default(_that.accountId,_that.plaidAccountId,_that.accountType,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String plaidAccountId,  String accountType,  String name)?  $default,) {final _that = this;
switch (_that) {
case _PlaidInsertedAccount() when $default != null:
return $default(_that.accountId,_that.plaidAccountId,_that.accountType,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaidInsertedAccount implements PlaidInsertedAccount {
  const _PlaidInsertedAccount({required this.accountId, required this.plaidAccountId, required this.accountType, required this.name});
  factory _PlaidInsertedAccount.fromJson(Map<String, dynamic> json) => _$PlaidInsertedAccountFromJson(json);

@override final  String accountId;
@override final  String plaidAccountId;
@override final  String accountType;
@override final  String name;

/// Create a copy of PlaidInsertedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaidInsertedAccountCopyWith<_PlaidInsertedAccount> get copyWith => __$PlaidInsertedAccountCopyWithImpl<_PlaidInsertedAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaidInsertedAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaidInsertedAccount&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.plaidAccountId, plaidAccountId) || other.plaidAccountId == plaidAccountId)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,plaidAccountId,accountType,name);

@override
String toString() {
  return 'PlaidInsertedAccount(accountId: $accountId, plaidAccountId: $plaidAccountId, accountType: $accountType, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PlaidInsertedAccountCopyWith<$Res> implements $PlaidInsertedAccountCopyWith<$Res> {
  factory _$PlaidInsertedAccountCopyWith(_PlaidInsertedAccount value, $Res Function(_PlaidInsertedAccount) _then) = __$PlaidInsertedAccountCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String plaidAccountId, String accountType, String name
});




}
/// @nodoc
class __$PlaidInsertedAccountCopyWithImpl<$Res>
    implements _$PlaidInsertedAccountCopyWith<$Res> {
  __$PlaidInsertedAccountCopyWithImpl(this._self, this._then);

  final _PlaidInsertedAccount _self;
  final $Res Function(_PlaidInsertedAccount) _then;

/// Create a copy of PlaidInsertedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? plaidAccountId = null,Object? accountType = null,Object? name = null,}) {
  return _then(_PlaidInsertedAccount(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,plaidAccountId: null == plaidAccountId ? _self.plaidAccountId : plaidAccountId // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlaidSkippedAccount {

 String get plaidAccountId; String get name; String get plaidType; String get plaidSubtype; String get reason;
/// Create a copy of PlaidSkippedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaidSkippedAccountCopyWith<PlaidSkippedAccount> get copyWith => _$PlaidSkippedAccountCopyWithImpl<PlaidSkippedAccount>(this as PlaidSkippedAccount, _$identity);

  /// Serializes this PlaidSkippedAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaidSkippedAccount&&(identical(other.plaidAccountId, plaidAccountId) || other.plaidAccountId == plaidAccountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plaidType, plaidType) || other.plaidType == plaidType)&&(identical(other.plaidSubtype, plaidSubtype) || other.plaidSubtype == plaidSubtype)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plaidAccountId,name,plaidType,plaidSubtype,reason);

@override
String toString() {
  return 'PlaidSkippedAccount(plaidAccountId: $plaidAccountId, name: $name, plaidType: $plaidType, plaidSubtype: $plaidSubtype, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $PlaidSkippedAccountCopyWith<$Res>  {
  factory $PlaidSkippedAccountCopyWith(PlaidSkippedAccount value, $Res Function(PlaidSkippedAccount) _then) = _$PlaidSkippedAccountCopyWithImpl;
@useResult
$Res call({
 String plaidAccountId, String name, String plaidType, String plaidSubtype, String reason
});




}
/// @nodoc
class _$PlaidSkippedAccountCopyWithImpl<$Res>
    implements $PlaidSkippedAccountCopyWith<$Res> {
  _$PlaidSkippedAccountCopyWithImpl(this._self, this._then);

  final PlaidSkippedAccount _self;
  final $Res Function(PlaidSkippedAccount) _then;

/// Create a copy of PlaidSkippedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plaidAccountId = null,Object? name = null,Object? plaidType = null,Object? plaidSubtype = null,Object? reason = null,}) {
  return _then(_self.copyWith(
plaidAccountId: null == plaidAccountId ? _self.plaidAccountId : plaidAccountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plaidType: null == plaidType ? _self.plaidType : plaidType // ignore: cast_nullable_to_non_nullable
as String,plaidSubtype: null == plaidSubtype ? _self.plaidSubtype : plaidSubtype // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaidSkippedAccount].
extension PlaidSkippedAccountPatterns on PlaidSkippedAccount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaidSkippedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaidSkippedAccount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaidSkippedAccount value)  $default,){
final _that = this;
switch (_that) {
case _PlaidSkippedAccount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaidSkippedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _PlaidSkippedAccount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plaidAccountId,  String name,  String plaidType,  String plaidSubtype,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaidSkippedAccount() when $default != null:
return $default(_that.plaidAccountId,_that.name,_that.plaidType,_that.plaidSubtype,_that.reason);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plaidAccountId,  String name,  String plaidType,  String plaidSubtype,  String reason)  $default,) {final _that = this;
switch (_that) {
case _PlaidSkippedAccount():
return $default(_that.plaidAccountId,_that.name,_that.plaidType,_that.plaidSubtype,_that.reason);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plaidAccountId,  String name,  String plaidType,  String plaidSubtype,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _PlaidSkippedAccount() when $default != null:
return $default(_that.plaidAccountId,_that.name,_that.plaidType,_that.plaidSubtype,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaidSkippedAccount implements PlaidSkippedAccount {
  const _PlaidSkippedAccount({required this.plaidAccountId, required this.name, required this.plaidType, required this.plaidSubtype, required this.reason});
  factory _PlaidSkippedAccount.fromJson(Map<String, dynamic> json) => _$PlaidSkippedAccountFromJson(json);

@override final  String plaidAccountId;
@override final  String name;
@override final  String plaidType;
@override final  String plaidSubtype;
@override final  String reason;

/// Create a copy of PlaidSkippedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaidSkippedAccountCopyWith<_PlaidSkippedAccount> get copyWith => __$PlaidSkippedAccountCopyWithImpl<_PlaidSkippedAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaidSkippedAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaidSkippedAccount&&(identical(other.plaidAccountId, plaidAccountId) || other.plaidAccountId == plaidAccountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.plaidType, plaidType) || other.plaidType == plaidType)&&(identical(other.plaidSubtype, plaidSubtype) || other.plaidSubtype == plaidSubtype)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plaidAccountId,name,plaidType,plaidSubtype,reason);

@override
String toString() {
  return 'PlaidSkippedAccount(plaidAccountId: $plaidAccountId, name: $name, plaidType: $plaidType, plaidSubtype: $plaidSubtype, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$PlaidSkippedAccountCopyWith<$Res> implements $PlaidSkippedAccountCopyWith<$Res> {
  factory _$PlaidSkippedAccountCopyWith(_PlaidSkippedAccount value, $Res Function(_PlaidSkippedAccount) _then) = __$PlaidSkippedAccountCopyWithImpl;
@override @useResult
$Res call({
 String plaidAccountId, String name, String plaidType, String plaidSubtype, String reason
});




}
/// @nodoc
class __$PlaidSkippedAccountCopyWithImpl<$Res>
    implements _$PlaidSkippedAccountCopyWith<$Res> {
  __$PlaidSkippedAccountCopyWithImpl(this._self, this._then);

  final _PlaidSkippedAccount _self;
  final $Res Function(_PlaidSkippedAccount) _then;

/// Create a copy of PlaidSkippedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plaidAccountId = null,Object? name = null,Object? plaidType = null,Object? plaidSubtype = null,Object? reason = null,}) {
  return _then(_PlaidSkippedAccount(
plaidAccountId: null == plaidAccountId ? _self.plaidAccountId : plaidAccountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,plaidType: null == plaidType ? _self.plaidType : plaidType // ignore: cast_nullable_to_non_nullable
as String,plaidSubtype: null == plaidSubtype ? _self.plaidSubtype : plaidSubtype // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlaidSyncResult {

 int get added; int get modified; int get removed; int get merged; List<String> get accountsSynced; List<String> get failedAccountIds; bool get requiresReauth; bool get partialFailure; String? get errorCode;
/// Create a copy of PlaidSyncResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaidSyncResultCopyWith<PlaidSyncResult> get copyWith => _$PlaidSyncResultCopyWithImpl<PlaidSyncResult>(this as PlaidSyncResult, _$identity);

  /// Serializes this PlaidSyncResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaidSyncResult&&(identical(other.added, added) || other.added == added)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.merged, merged) || other.merged == merged)&&const DeepCollectionEquality().equals(other.accountsSynced, accountsSynced)&&const DeepCollectionEquality().equals(other.failedAccountIds, failedAccountIds)&&(identical(other.requiresReauth, requiresReauth) || other.requiresReauth == requiresReauth)&&(identical(other.partialFailure, partialFailure) || other.partialFailure == partialFailure)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,added,modified,removed,merged,const DeepCollectionEquality().hash(accountsSynced),const DeepCollectionEquality().hash(failedAccountIds),requiresReauth,partialFailure,errorCode);

@override
String toString() {
  return 'PlaidSyncResult(added: $added, modified: $modified, removed: $removed, merged: $merged, accountsSynced: $accountsSynced, failedAccountIds: $failedAccountIds, requiresReauth: $requiresReauth, partialFailure: $partialFailure, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class $PlaidSyncResultCopyWith<$Res>  {
  factory $PlaidSyncResultCopyWith(PlaidSyncResult value, $Res Function(PlaidSyncResult) _then) = _$PlaidSyncResultCopyWithImpl;
@useResult
$Res call({
 int added, int modified, int removed, int merged, List<String> accountsSynced, List<String> failedAccountIds, bool requiresReauth, bool partialFailure, String? errorCode
});




}
/// @nodoc
class _$PlaidSyncResultCopyWithImpl<$Res>
    implements $PlaidSyncResultCopyWith<$Res> {
  _$PlaidSyncResultCopyWithImpl(this._self, this._then);

  final PlaidSyncResult _self;
  final $Res Function(PlaidSyncResult) _then;

/// Create a copy of PlaidSyncResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? added = null,Object? modified = null,Object? removed = null,Object? merged = null,Object? accountsSynced = null,Object? failedAccountIds = null,Object? requiresReauth = null,Object? partialFailure = null,Object? errorCode = freezed,}) {
  return _then(_self.copyWith(
added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,merged: null == merged ? _self.merged : merged // ignore: cast_nullable_to_non_nullable
as int,accountsSynced: null == accountsSynced ? _self.accountsSynced : accountsSynced // ignore: cast_nullable_to_non_nullable
as List<String>,failedAccountIds: null == failedAccountIds ? _self.failedAccountIds : failedAccountIds // ignore: cast_nullable_to_non_nullable
as List<String>,requiresReauth: null == requiresReauth ? _self.requiresReauth : requiresReauth // ignore: cast_nullable_to_non_nullable
as bool,partialFailure: null == partialFailure ? _self.partialFailure : partialFailure // ignore: cast_nullable_to_non_nullable
as bool,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaidSyncResult].
extension PlaidSyncResultPatterns on PlaidSyncResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaidSyncResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaidSyncResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaidSyncResult value)  $default,){
final _that = this;
switch (_that) {
case _PlaidSyncResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaidSyncResult value)?  $default,){
final _that = this;
switch (_that) {
case _PlaidSyncResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int added,  int modified,  int removed,  int merged,  List<String> accountsSynced,  List<String> failedAccountIds,  bool requiresReauth,  bool partialFailure,  String? errorCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaidSyncResult() when $default != null:
return $default(_that.added,_that.modified,_that.removed,_that.merged,_that.accountsSynced,_that.failedAccountIds,_that.requiresReauth,_that.partialFailure,_that.errorCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int added,  int modified,  int removed,  int merged,  List<String> accountsSynced,  List<String> failedAccountIds,  bool requiresReauth,  bool partialFailure,  String? errorCode)  $default,) {final _that = this;
switch (_that) {
case _PlaidSyncResult():
return $default(_that.added,_that.modified,_that.removed,_that.merged,_that.accountsSynced,_that.failedAccountIds,_that.requiresReauth,_that.partialFailure,_that.errorCode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int added,  int modified,  int removed,  int merged,  List<String> accountsSynced,  List<String> failedAccountIds,  bool requiresReauth,  bool partialFailure,  String? errorCode)?  $default,) {final _that = this;
switch (_that) {
case _PlaidSyncResult() when $default != null:
return $default(_that.added,_that.modified,_that.removed,_that.merged,_that.accountsSynced,_that.failedAccountIds,_that.requiresReauth,_that.partialFailure,_that.errorCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaidSyncResult implements PlaidSyncResult {
  const _PlaidSyncResult({this.added = 0, this.modified = 0, this.removed = 0, this.merged = 0, final  List<String> accountsSynced = const [], final  List<String> failedAccountIds = const [], this.requiresReauth = false, this.partialFailure = false, this.errorCode}): _accountsSynced = accountsSynced,_failedAccountIds = failedAccountIds;
  factory _PlaidSyncResult.fromJson(Map<String, dynamic> json) => _$PlaidSyncResultFromJson(json);

@override@JsonKey() final  int added;
@override@JsonKey() final  int modified;
@override@JsonKey() final  int removed;
@override@JsonKey() final  int merged;
 final  List<String> _accountsSynced;
@override@JsonKey() List<String> get accountsSynced {
  if (_accountsSynced is EqualUnmodifiableListView) return _accountsSynced;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accountsSynced);
}

 final  List<String> _failedAccountIds;
@override@JsonKey() List<String> get failedAccountIds {
  if (_failedAccountIds is EqualUnmodifiableListView) return _failedAccountIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failedAccountIds);
}

@override@JsonKey() final  bool requiresReauth;
@override@JsonKey() final  bool partialFailure;
@override final  String? errorCode;

/// Create a copy of PlaidSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaidSyncResultCopyWith<_PlaidSyncResult> get copyWith => __$PlaidSyncResultCopyWithImpl<_PlaidSyncResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaidSyncResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaidSyncResult&&(identical(other.added, added) || other.added == added)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.merged, merged) || other.merged == merged)&&const DeepCollectionEquality().equals(other._accountsSynced, _accountsSynced)&&const DeepCollectionEquality().equals(other._failedAccountIds, _failedAccountIds)&&(identical(other.requiresReauth, requiresReauth) || other.requiresReauth == requiresReauth)&&(identical(other.partialFailure, partialFailure) || other.partialFailure == partialFailure)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,added,modified,removed,merged,const DeepCollectionEquality().hash(_accountsSynced),const DeepCollectionEquality().hash(_failedAccountIds),requiresReauth,partialFailure,errorCode);

@override
String toString() {
  return 'PlaidSyncResult(added: $added, modified: $modified, removed: $removed, merged: $merged, accountsSynced: $accountsSynced, failedAccountIds: $failedAccountIds, requiresReauth: $requiresReauth, partialFailure: $partialFailure, errorCode: $errorCode)';
}


}

/// @nodoc
abstract mixin class _$PlaidSyncResultCopyWith<$Res> implements $PlaidSyncResultCopyWith<$Res> {
  factory _$PlaidSyncResultCopyWith(_PlaidSyncResult value, $Res Function(_PlaidSyncResult) _then) = __$PlaidSyncResultCopyWithImpl;
@override @useResult
$Res call({
 int added, int modified, int removed, int merged, List<String> accountsSynced, List<String> failedAccountIds, bool requiresReauth, bool partialFailure, String? errorCode
});




}
/// @nodoc
class __$PlaidSyncResultCopyWithImpl<$Res>
    implements _$PlaidSyncResultCopyWith<$Res> {
  __$PlaidSyncResultCopyWithImpl(this._self, this._then);

  final _PlaidSyncResult _self;
  final $Res Function(_PlaidSyncResult) _then;

/// Create a copy of PlaidSyncResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? added = null,Object? modified = null,Object? removed = null,Object? merged = null,Object? accountsSynced = null,Object? failedAccountIds = null,Object? requiresReauth = null,Object? partialFailure = null,Object? errorCode = freezed,}) {
  return _then(_PlaidSyncResult(
added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,merged: null == merged ? _self.merged : merged // ignore: cast_nullable_to_non_nullable
as int,accountsSynced: null == accountsSynced ? _self._accountsSynced : accountsSynced // ignore: cast_nullable_to_non_nullable
as List<String>,failedAccountIds: null == failedAccountIds ? _self._failedAccountIds : failedAccountIds // ignore: cast_nullable_to_non_nullable
as List<String>,requiresReauth: null == requiresReauth ? _self.requiresReauth : requiresReauth // ignore: cast_nullable_to_non_nullable
as bool,partialFailure: null == partialFailure ? _self.partialFailure : partialFailure // ignore: cast_nullable_to_non_nullable
as bool,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
