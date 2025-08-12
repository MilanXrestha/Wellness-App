// This is a generated file - do not edit.
//
// Generated from wellness_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// CategoryModel represents a category of wellness tips or quotes.
class CategoryModel extends $pb.GeneratedMessage {
  factory CategoryModel({
    $core.String? categoryId,
    $core.String? categoryName,
    $core.String? imageUrl,
    $core.Iterable<$core.String>? preferenceIds,
    $core.String? categoryDescription,
    $core.String? createdAt,
  }) {
    final result = create();
    if (categoryId != null) result.categoryId = categoryId;
    if (categoryName != null) result.categoryName = categoryName;
    if (imageUrl != null) result.imageUrl = imageUrl;
    if (preferenceIds != null) result.preferenceIds.addAll(preferenceIds);
    if (categoryDescription != null)
      result.categoryDescription = categoryDescription;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  CategoryModel._();

  factory CategoryModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CategoryModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CategoryModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'categoryId', protoName: 'categoryId')
    ..aOS(2, _omitFieldNames ? '' : 'categoryName', protoName: 'categoryName')
    ..aOS(3, _omitFieldNames ? '' : 'imageUrl', protoName: 'imageUrl')
    ..pPS(4, _omitFieldNames ? '' : 'preferenceIds', protoName: 'preferenceIds')
    ..aOS(5, _omitFieldNames ? '' : 'categoryDescription',
        protoName: 'categoryDescription')
    ..aOS(6, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryModel clone() => CategoryModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CategoryModel copyWith(void Function(CategoryModel) updates) =>
      super.copyWith((message) => updates(message as CategoryModel))
          as CategoryModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CategoryModel create() => CategoryModel._();
  @$core.override
  CategoryModel createEmptyInstance() => create();
  static $pb.PbList<CategoryModel> createRepeated() =>
      $pb.PbList<CategoryModel>();
  @$core.pragma('dart2js:noInline')
  static CategoryModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CategoryModel>(create);
  static CategoryModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get categoryId => $_getSZ(0);
  @$pb.TagNumber(1)
  set categoryId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategoryId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategoryId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get categoryName => $_getSZ(1);
  @$pb.TagNumber(2)
  set categoryName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCategoryName() => $_has(1);
  @$pb.TagNumber(2)
  void clearCategoryName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get imageUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set imageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasImageUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearImageUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get preferenceIds => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get categoryDescription => $_getSZ(4);
  @$pb.TagNumber(5)
  set categoryDescription($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCategoryDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearCategoryDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get createdAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set createdAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
}

/// FavoriteModel represents a user's favorited tip.
class FavoriteModel extends $pb.GeneratedMessage {
  factory FavoriteModel({
    $core.String? id,
    $core.String? userId,
    $core.String? tipId,
    $core.String? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (tipId != null) result.tipId = tipId;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  FavoriteModel._();

  factory FavoriteModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FavoriteModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FavoriteModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'tipId', protoName: 'tipId')
    ..aOS(4, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoriteModel clone() => FavoriteModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FavoriteModel copyWith(void Function(FavoriteModel) updates) =>
      super.copyWith((message) => updates(message as FavoriteModel))
          as FavoriteModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FavoriteModel create() => FavoriteModel._();
  @$core.override
  FavoriteModel createEmptyInstance() => create();
  static $pb.PbList<FavoriteModel> createRepeated() =>
      $pb.PbList<FavoriteModel>();
  @$core.pragma('dart2js:noInline')
  static FavoriteModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FavoriteModel>(create);
  static FavoriteModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get tipId => $_getSZ(2);
  @$pb.TagNumber(3)
  set tipId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTipId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTipId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get createdAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
}

/// NotificationModel represents a notification sent to a user.
class NotificationModel extends $pb.GeneratedMessage {
  factory NotificationModel({
    $core.String? id,
    $core.String? userId,
    $core.String? title,
    $core.String? body,
    $core.String? type,
    $core.bool? isRead,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? payload,
    $core.String? timestamp,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    if (type != null) result.type = type;
    if (isRead != null) result.isRead = isRead;
    if (payload != null) result.payload.addEntries(payload);
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  NotificationModel._();

  factory NotificationModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NotificationModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..aOS(5, _omitFieldNames ? '' : 'type')
    ..aOB(6, _omitFieldNames ? '' : 'isRead', protoName: 'isRead')
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'payload',
        entryClassName: 'NotificationModel.PayloadEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('wellness'))
    ..aOS(8, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationModel clone() => NotificationModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotificationModel copyWith(void Function(NotificationModel) updates) =>
      super.copyWith((message) => updates(message as NotificationModel))
          as NotificationModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotificationModel create() => NotificationModel._();
  @$core.override
  NotificationModel createEmptyInstance() => create();
  static $pb.PbList<NotificationModel> createRepeated() =>
      $pb.PbList<NotificationModel>();
  @$core.pragma('dart2js:noInline')
  static NotificationModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotificationModel>(create);
  static NotificationModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get body => $_getSZ(3);
  @$pb.TagNumber(4)
  set body($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBody() => $_has(3);
  @$pb.TagNumber(4)
  void clearBody() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get type => $_getSZ(4);
  @$pb.TagNumber(5)
  set type($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasType() => $_has(4);
  @$pb.TagNumber(5)
  void clearType() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isRead => $_getBF(5);
  @$pb.TagNumber(6)
  set isRead($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsRead() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsRead() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get payload => $_getMap(6);

  @$pb.TagNumber(8)
  $core.String get timestamp => $_getSZ(7);
  @$pb.TagNumber(8)
  set timestamp($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTimestamp() => $_has(7);
  @$pb.TagNumber(8)
  void clearTimestamp() => $_clearField(8);
}

/// PreferenceModel represents a user's preference or interest.
class PreferenceModel extends $pb.GeneratedMessage {
  factory PreferenceModel({
    $core.String? preferenceId,
    $core.String? preferenceName,
    $core.String? preferenceIcon,
    $core.String? preferenceDescription,
    $core.bool? isSvg,
  }) {
    final result = create();
    if (preferenceId != null) result.preferenceId = preferenceId;
    if (preferenceName != null) result.preferenceName = preferenceName;
    if (preferenceIcon != null) result.preferenceIcon = preferenceIcon;
    if (preferenceDescription != null)
      result.preferenceDescription = preferenceDescription;
    if (isSvg != null) result.isSvg = isSvg;
    return result;
  }

  PreferenceModel._();

  factory PreferenceModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PreferenceModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreferenceModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'preferenceId', protoName: 'preferenceId')
    ..aOS(2, _omitFieldNames ? '' : 'preferenceName',
        protoName: 'preferenceName')
    ..aOS(3, _omitFieldNames ? '' : 'preferenceIcon',
        protoName: 'preferenceIcon')
    ..aOS(4, _omitFieldNames ? '' : 'preferenceDescription',
        protoName: 'preferenceDescription')
    ..aOB(5, _omitFieldNames ? '' : 'isSvg', protoName: 'isSvg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreferenceModel clone() => PreferenceModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreferenceModel copyWith(void Function(PreferenceModel) updates) =>
      super.copyWith((message) => updates(message as PreferenceModel))
          as PreferenceModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PreferenceModel create() => PreferenceModel._();
  @$core.override
  PreferenceModel createEmptyInstance() => create();
  static $pb.PbList<PreferenceModel> createRepeated() =>
      $pb.PbList<PreferenceModel>();
  @$core.pragma('dart2js:noInline')
  static PreferenceModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreferenceModel>(create);
  static PreferenceModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get preferenceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set preferenceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreferenceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreferenceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get preferenceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set preferenceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPreferenceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreferenceName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get preferenceIcon => $_getSZ(2);
  @$pb.TagNumber(3)
  set preferenceIcon($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreferenceIcon() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreferenceIcon() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get preferenceDescription => $_getSZ(3);
  @$pb.TagNumber(4)
  set preferenceDescription($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPreferenceDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearPreferenceDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isSvg => $_getBF(4);
  @$pb.TagNumber(5)
  set isSvg($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsSvg() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsSvg() => $_clearField(5);
}

/// ReminderModel represents a scheduled reminder for a user.
class ReminderModel extends $pb.GeneratedMessage {
  factory ReminderModel({
    $core.String? id,
    $core.String? userId,
    $core.String? type,
    $core.String? categoryId,
    $core.String? frequency,
    $core.String? time,
    $core.int? dayOfWeek,
    $core.String? createdAt,
    $core.int? notificationId,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (type != null) result.type = type;
    if (categoryId != null) result.categoryId = categoryId;
    if (frequency != null) result.frequency = frequency;
    if (time != null) result.time = time;
    if (dayOfWeek != null) result.dayOfWeek = dayOfWeek;
    if (createdAt != null) result.createdAt = createdAt;
    if (notificationId != null) result.notificationId = notificationId;
    return result;
  }

  ReminderModel._();

  factory ReminderModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReminderModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReminderModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'categoryId', protoName: 'categoryId')
    ..aOS(5, _omitFieldNames ? '' : 'frequency')
    ..aOS(6, _omitFieldNames ? '' : 'time')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'dayOfWeek', $pb.PbFieldType.O3,
        protoName: 'dayOfWeek')
    ..aOS(8, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..a<$core.int>(
        9, _omitFieldNames ? '' : 'notificationId', $pb.PbFieldType.O3,
        protoName: 'notificationId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReminderModel clone() => ReminderModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReminderModel copyWith(void Function(ReminderModel) updates) =>
      super.copyWith((message) => updates(message as ReminderModel))
          as ReminderModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReminderModel create() => ReminderModel._();
  @$core.override
  ReminderModel createEmptyInstance() => create();
  static $pb.PbList<ReminderModel> createRepeated() =>
      $pb.PbList<ReminderModel>();
  @$core.pragma('dart2js:noInline')
  static ReminderModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReminderModel>(create);
  static ReminderModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get categoryId => $_getSZ(3);
  @$pb.TagNumber(4)
  set categoryId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCategoryId() => $_has(3);
  @$pb.TagNumber(4)
  void clearCategoryId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get frequency => $_getSZ(4);
  @$pb.TagNumber(5)
  set frequency($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFrequency() => $_has(4);
  @$pb.TagNumber(5)
  void clearFrequency() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get time => $_getSZ(5);
  @$pb.TagNumber(6)
  set time($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearTime() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get dayOfWeek => $_getIZ(6);
  @$pb.TagNumber(7)
  set dayOfWeek($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDayOfWeek() => $_has(6);
  @$pb.TagNumber(7)
  void clearDayOfWeek() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get createdAt => $_getSZ(7);
  @$pb.TagNumber(8)
  set createdAt($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCreatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearCreatedAt() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get notificationId => $_getIZ(8);
  @$pb.TagNumber(9)
  set notificationId($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasNotificationId() => $_has(8);
  @$pb.TagNumber(9)
  void clearNotificationId() => $_clearField(9);
}

/// SubscriptionModel represents a user's subscription details.
class SubscriptionModel extends $pb.GeneratedMessage {
  factory SubscriptionModel({
    $core.String? userId,
    $core.String? planId,
    $core.String? status,
    $core.String? startDate,
    $core.String? endDate,
    $core.String? createdAt,
    $core.String? updatedAt,
    $core.String? paymentMethod,
    $core.String? lastTransactionId,
    $core.bool? isAutoRenew,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (planId != null) result.planId = planId;
    if (status != null) result.status = status;
    if (startDate != null) result.startDate = startDate;
    if (endDate != null) result.endDate = endDate;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (paymentMethod != null) result.paymentMethod = paymentMethod;
    if (lastTransactionId != null) result.lastTransactionId = lastTransactionId;
    if (isAutoRenew != null) result.isAutoRenew = isAutoRenew;
    return result;
  }

  SubscriptionModel._();

  factory SubscriptionModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'planId', protoName: 'planId')
    ..aOS(3, _omitFieldNames ? '' : 'status')
    ..aOS(4, _omitFieldNames ? '' : 'startDate', protoName: 'startDate')
    ..aOS(5, _omitFieldNames ? '' : 'endDate', protoName: 'endDate')
    ..aOS(6, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aOS(7, _omitFieldNames ? '' : 'updatedAt', protoName: 'updatedAt')
    ..aOS(8, _omitFieldNames ? '' : 'paymentMethod', protoName: 'paymentMethod')
    ..aOS(9, _omitFieldNames ? '' : 'lastTransactionId',
        protoName: 'lastTransactionId')
    ..aOB(10, _omitFieldNames ? '' : 'isAutoRenew', protoName: 'isAutoRenew')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionModel clone() => SubscriptionModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionModel copyWith(void Function(SubscriptionModel) updates) =>
      super.copyWith((message) => updates(message as SubscriptionModel))
          as SubscriptionModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionModel create() => SubscriptionModel._();
  @$core.override
  SubscriptionModel createEmptyInstance() => create();
  static $pb.PbList<SubscriptionModel> createRepeated() =>
      $pb.PbList<SubscriptionModel>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionModel>(create);
  static SubscriptionModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get planId => $_getSZ(1);
  @$pb.TagNumber(2)
  set planId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlanId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlanId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get status => $_getSZ(2);
  @$pb.TagNumber(3)
  set status($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get startDate => $_getSZ(3);
  @$pb.TagNumber(4)
  set startDate($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStartDate() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartDate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get endDate => $_getSZ(4);
  @$pb.TagNumber(5)
  set endDate($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEndDate() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndDate() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get createdAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set createdAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get updatedAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set updatedAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdatedAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get paymentMethod => $_getSZ(7);
  @$pb.TagNumber(8)
  set paymentMethod($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPaymentMethod() => $_has(7);
  @$pb.TagNumber(8)
  void clearPaymentMethod() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get lastTransactionId => $_getSZ(8);
  @$pb.TagNumber(9)
  set lastTransactionId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastTransactionId() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastTransactionId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isAutoRenew => $_getBF(9);
  @$pb.TagNumber(10)
  set isAutoRenew($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsAutoRenew() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsAutoRenew() => $_clearField(10);
}

class TransactionModel extends $pb.GeneratedMessage {
  factory TransactionModel({
    $core.String? id,
    $core.String? userId,
    $core.String? subscriptionId,
    $core.String? paymentProviderTransactionId,
    $core.String? paymentProvider,
    $core.double? amount,
    $core.String? currency,
    $core.String? status,
    $core.String? planId,
    $core.String? createdAt,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (userId != null) result.userId = userId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (paymentProviderTransactionId != null)
      result.paymentProviderTransactionId = paymentProviderTransactionId;
    if (paymentProvider != null) result.paymentProvider = paymentProvider;
    if (amount != null) result.amount = amount;
    if (currency != null) result.currency = currency;
    if (status != null) result.status = status;
    if (planId != null) result.planId = planId;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  TransactionModel._();

  factory TransactionModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TransactionModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TransactionModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'subscriptionId',
        protoName: 'subscriptionId')
    ..aOS(4, _omitFieldNames ? '' : 'paymentProviderTransactionId',
        protoName: 'paymentProviderTransactionId')
    ..aOS(5, _omitFieldNames ? '' : 'paymentProvider',
        protoName: 'paymentProvider')
    ..a<$core.double>(6, _omitFieldNames ? '' : 'amount', $pb.PbFieldType.OD)
    ..aOS(7, _omitFieldNames ? '' : 'currency')
    ..aOS(8, _omitFieldNames ? '' : 'status')
    ..aOS(9, _omitFieldNames ? '' : 'planId', protoName: 'planId')
    ..aOS(10, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransactionModel clone() => TransactionModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TransactionModel copyWith(void Function(TransactionModel) updates) =>
      super.copyWith((message) => updates(message as TransactionModel))
          as TransactionModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransactionModel create() => TransactionModel._();
  @$core.override
  TransactionModel createEmptyInstance() => create();
  static $pb.PbList<TransactionModel> createRepeated() =>
      $pb.PbList<TransactionModel>();
  @$core.pragma('dart2js:noInline')
  static TransactionModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TransactionModel>(create);
  static TransactionModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get subscriptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set subscriptionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubscriptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubscriptionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get paymentProviderTransactionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set paymentProviderTransactionId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPaymentProviderTransactionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearPaymentProviderTransactionId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get paymentProvider => $_getSZ(4);
  @$pb.TagNumber(5)
  set paymentProvider($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPaymentProvider() => $_has(4);
  @$pb.TagNumber(5)
  void clearPaymentProvider() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get amount => $_getN(5);
  @$pb.TagNumber(6)
  set amount($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAmount() => $_has(5);
  @$pb.TagNumber(6)
  void clearAmount() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get currency => $_getSZ(6);
  @$pb.TagNumber(7)
  set currency($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCurrency() => $_has(6);
  @$pb.TagNumber(7)
  void clearCurrency() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get status => $_getSZ(7);
  @$pb.TagNumber(8)
  set status($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get planId => $_getSZ(8);
  @$pb.TagNumber(9)
  set planId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPlanId() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlanId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get createdAt => $_getSZ(9);
  @$pb.TagNumber(10)
  set createdAt($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCreatedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreatedAt() => $_clearField(10);
}

/// TipModel represents a wellness tip or quote.
class TipModel extends $pb.GeneratedMessage {
  factory TipModel({
    $core.String? tipsId,
    $core.String? tipsTitle,
    $core.String? tipsDescription,
    $core.String? tipsType,
    $core.String? tipsAuthor,
    $core.String? authorIcon,
    $core.Iterable<$core.String>? preferenceIds,
    $core.String? categoryId,
    $core.String? createdAt,
    $core.bool? isFeatured,
    $core.bool? isPremium,
  }) {
    final result = create();
    if (tipsId != null) result.tipsId = tipsId;
    if (tipsTitle != null) result.tipsTitle = tipsTitle;
    if (tipsDescription != null) result.tipsDescription = tipsDescription;
    if (tipsType != null) result.tipsType = tipsType;
    if (tipsAuthor != null) result.tipsAuthor = tipsAuthor;
    if (authorIcon != null) result.authorIcon = authorIcon;
    if (preferenceIds != null) result.preferenceIds.addAll(preferenceIds);
    if (categoryId != null) result.categoryId = categoryId;
    if (createdAt != null) result.createdAt = createdAt;
    if (isFeatured != null) result.isFeatured = isFeatured;
    if (isPremium != null) result.isPremium = isPremium;
    return result;
  }

  TipModel._();

  factory TipModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TipModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TipModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tipsId', protoName: 'tipsId')
    ..aOS(2, _omitFieldNames ? '' : 'tipsTitle', protoName: 'tipsTitle')
    ..aOS(3, _omitFieldNames ? '' : 'tipsDescription',
        protoName: 'tipsDescription')
    ..aOS(4, _omitFieldNames ? '' : 'tipsType', protoName: 'tipsType')
    ..aOS(5, _omitFieldNames ? '' : 'tipsAuthor', protoName: 'tipsAuthor')
    ..aOS(6, _omitFieldNames ? '' : 'authorIcon', protoName: 'authorIcon')
    ..pPS(7, _omitFieldNames ? '' : 'preferenceIds', protoName: 'preferenceIds')
    ..aOS(8, _omitFieldNames ? '' : 'categoryId', protoName: 'categoryId')
    ..aOS(9, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aOB(10, _omitFieldNames ? '' : 'isFeatured', protoName: 'isFeatured')
    ..aOB(11, _omitFieldNames ? '' : 'isPremium', protoName: 'isPremium')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TipModel clone() => TipModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TipModel copyWith(void Function(TipModel) updates) =>
      super.copyWith((message) => updates(message as TipModel)) as TipModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TipModel create() => TipModel._();
  @$core.override
  TipModel createEmptyInstance() => create();
  static $pb.PbList<TipModel> createRepeated() => $pb.PbList<TipModel>();
  @$core.pragma('dart2js:noInline')
  static TipModel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TipModel>(create);
  static TipModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tipsId => $_getSZ(0);
  @$pb.TagNumber(1)
  set tipsId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTipsId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTipsId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get tipsTitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set tipsTitle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTipsTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTipsTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get tipsDescription => $_getSZ(2);
  @$pb.TagNumber(3)
  set tipsDescription($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTipsDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearTipsDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get tipsType => $_getSZ(3);
  @$pb.TagNumber(4)
  set tipsType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTipsType() => $_has(3);
  @$pb.TagNumber(4)
  void clearTipsType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get tipsAuthor => $_getSZ(4);
  @$pb.TagNumber(5)
  set tipsAuthor($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTipsAuthor() => $_has(4);
  @$pb.TagNumber(5)
  void clearTipsAuthor() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get authorIcon => $_getSZ(5);
  @$pb.TagNumber(6)
  set authorIcon($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAuthorIcon() => $_has(5);
  @$pb.TagNumber(6)
  void clearAuthorIcon() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get preferenceIds => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get categoryId => $_getSZ(7);
  @$pb.TagNumber(8)
  set categoryId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCategoryId() => $_has(7);
  @$pb.TagNumber(8)
  void clearCategoryId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get createdAt => $_getSZ(8);
  @$pb.TagNumber(9)
  set createdAt($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAt() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isFeatured => $_getBF(9);
  @$pb.TagNumber(10)
  set isFeatured($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsFeatured() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsFeatured() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get isPremium => $_getBF(10);
  @$pb.TagNumber(11)
  set isPremium($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasIsPremium() => $_has(10);
  @$pb.TagNumber(11)
  void clearIsPremium() => $_clearField(11);
}

/// UserModel represents a user's profile information.
class UserModel extends $pb.GeneratedMessage {
  factory UserModel({
    $core.String? userId,
    $core.String? userEmail,
    $core.String? userName,
    $core.String? userRole,
    $core.bool? preferenceCompleted,
    $core.String? createdAt,
    $core.String? photoURL,
    $core.String? fcmToken,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (userEmail != null) result.userEmail = userEmail;
    if (userName != null) result.userName = userName;
    if (userRole != null) result.userRole = userRole;
    if (preferenceCompleted != null)
      result.preferenceCompleted = preferenceCompleted;
    if (createdAt != null) result.createdAt = createdAt;
    if (photoURL != null) result.photoURL = photoURL;
    if (fcmToken != null) result.fcmToken = fcmToken;
    return result;
  }

  UserModel._();

  factory UserModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'userEmail', protoName: 'userEmail')
    ..aOS(3, _omitFieldNames ? '' : 'userName', protoName: 'userName')
    ..aOS(4, _omitFieldNames ? '' : 'userRole', protoName: 'userRole')
    ..aOB(5, _omitFieldNames ? '' : 'preferenceCompleted',
        protoName: 'preferenceCompleted')
    ..aOS(6, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..aOS(7, _omitFieldNames ? '' : 'photoURL', protoName: 'photoURL')
    ..aOS(8, _omitFieldNames ? '' : 'fcmToken', protoName: 'fcmToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserModel clone() => UserModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserModel copyWith(void Function(UserModel) updates) =>
      super.copyWith((message) => updates(message as UserModel)) as UserModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserModel create() => UserModel._();
  @$core.override
  UserModel createEmptyInstance() => create();
  static $pb.PbList<UserModel> createRepeated() => $pb.PbList<UserModel>();
  @$core.pragma('dart2js:noInline')
  static UserModel getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserModel>(create);
  static UserModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userEmail => $_getSZ(1);
  @$pb.TagNumber(2)
  set userEmail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserEmail() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserEmail() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get userName => $_getSZ(2);
  @$pb.TagNumber(3)
  set userName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserName() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get userRole => $_getSZ(3);
  @$pb.TagNumber(4)
  set userRole($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserRole() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get preferenceCompleted => $_getBF(4);
  @$pb.TagNumber(5)
  set preferenceCompleted($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPreferenceCompleted() => $_has(4);
  @$pb.TagNumber(5)
  void clearPreferenceCompleted() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get createdAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set createdAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get photoURL => $_getSZ(6);
  @$pb.TagNumber(7)
  set photoURL($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPhotoURL() => $_has(6);
  @$pb.TagNumber(7)
  void clearPhotoURL() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get fcmToken => $_getSZ(7);
  @$pb.TagNumber(8)
  set fcmToken($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFcmToken() => $_has(7);
  @$pb.TagNumber(8)
  void clearFcmToken() => $_clearField(8);
}

/// UserPreferenceEntry represents a single preference selected by a user.
class UserPreferenceEntry extends $pb.GeneratedMessage {
  factory UserPreferenceEntry({
    $core.String? preferenceId,
    $core.String? selectedAt,
  }) {
    final result = create();
    if (preferenceId != null) result.preferenceId = preferenceId;
    if (selectedAt != null) result.selectedAt = selectedAt;
    return result;
  }

  UserPreferenceEntry._();

  factory UserPreferenceEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserPreferenceEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserPreferenceEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'preferenceId', protoName: 'preferenceId')
    ..aOS(2, _omitFieldNames ? '' : 'selectedAt', protoName: 'selectedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPreferenceEntry clone() => UserPreferenceEntry()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPreferenceEntry copyWith(void Function(UserPreferenceEntry) updates) =>
      super.copyWith((message) => updates(message as UserPreferenceEntry))
          as UserPreferenceEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserPreferenceEntry create() => UserPreferenceEntry._();
  @$core.override
  UserPreferenceEntry createEmptyInstance() => create();
  static $pb.PbList<UserPreferenceEntry> createRepeated() =>
      $pb.PbList<UserPreferenceEntry>();
  @$core.pragma('dart2js:noInline')
  static UserPreferenceEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserPreferenceEntry>(create);
  static UserPreferenceEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get preferenceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set preferenceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreferenceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreferenceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get selectedAt => $_getSZ(1);
  @$pb.TagNumber(2)
  set selectedAt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelectedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelectedAt() => $_clearField(2);
}

/// UserPreferenceModel represents a collection of user preferences.
class UserPreferenceModel extends $pb.GeneratedMessage {
  factory UserPreferenceModel({
    $core.String? userId,
    $core.Iterable<UserPreferenceEntry>? preferences,
    $core.String? updatedAt,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (preferences != null) result.preferences.addAll(preferences);
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  UserPreferenceModel._();

  factory UserPreferenceModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserPreferenceModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserPreferenceModel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'wellness'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..pc<UserPreferenceEntry>(
        2, _omitFieldNames ? '' : 'preferences', $pb.PbFieldType.PM,
        subBuilder: UserPreferenceEntry.create)
    ..aOS(3, _omitFieldNames ? '' : 'updatedAt', protoName: 'updatedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPreferenceModel clone() => UserPreferenceModel()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserPreferenceModel copyWith(void Function(UserPreferenceModel) updates) =>
      super.copyWith((message) => updates(message as UserPreferenceModel))
          as UserPreferenceModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserPreferenceModel create() => UserPreferenceModel._();
  @$core.override
  UserPreferenceModel createEmptyInstance() => create();
  static $pb.PbList<UserPreferenceModel> createRepeated() =>
      $pb.PbList<UserPreferenceModel>();
  @$core.pragma('dart2js:noInline')
  static UserPreferenceModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserPreferenceModel>(create);
  static UserPreferenceModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<UserPreferenceEntry> get preferences => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get updatedAt => $_getSZ(2);
  @$pb.TagNumber(3)
  set updatedAt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdatedAt() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
