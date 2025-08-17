// This is a generated file - do not edit.
//
// Generated from protos/wellness_data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use categoryModelDescriptor instead')
const CategoryModel$json = {
  '1': 'CategoryModel',
  '2': [
    {'1': 'categoryId', '3': 1, '4': 1, '5': 9, '10': 'categoryId'},
    {'1': 'categoryName', '3': 2, '4': 1, '5': 9, '10': 'categoryName'},
    {'1': 'imageUrl', '3': 3, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'preferenceIds', '3': 4, '4': 3, '5': 9, '10': 'preferenceIds'},
    {
      '1': 'categoryDescription',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'categoryDescription',
      '17': true
    },
    {'1': 'createdAt', '3': 6, '4': 1, '5': 9, '10': 'createdAt'},
  ],
  '8': [
    {'1': '_categoryDescription'},
  ],
};

/// Descriptor for `CategoryModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryModelDescriptor = $convert.base64Decode(
    'Cg1DYXRlZ29yeU1vZGVsEh4KCmNhdGVnb3J5SWQYASABKAlSCmNhdGVnb3J5SWQSIgoMY2F0ZW'
    'dvcnlOYW1lGAIgASgJUgxjYXRlZ29yeU5hbWUSGgoIaW1hZ2VVcmwYAyABKAlSCGltYWdlVXJs'
    'EiQKDXByZWZlcmVuY2VJZHMYBCADKAlSDXByZWZlcmVuY2VJZHMSNQoTY2F0ZWdvcnlEZXNjcm'
    'lwdGlvbhgFIAEoCUgAUhNjYXRlZ29yeURlc2NyaXB0aW9uiAEBEhwKCWNyZWF0ZWRBdBgGIAEo'
    'CVIJY3JlYXRlZEF0QhYKFF9jYXRlZ29yeURlc2NyaXB0aW9u');

@$core.Deprecated('Use favoriteModelDescriptor instead')
const FavoriteModel$json = {
  '1': 'FavoriteModel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'userId', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'tipId', '3': 3, '4': 1, '5': 9, '10': 'tipId'},
    {
      '1': 'createdAt',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'createdAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_createdAt'},
  ],
};

/// Descriptor for `FavoriteModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List favoriteModelDescriptor = $convert.base64Decode(
    'Cg1GYXZvcml0ZU1vZGVsEg4KAmlkGAEgASgJUgJpZBIWCgZ1c2VySWQYAiABKAlSBnVzZXJJZB'
    'IUCgV0aXBJZBgDIAEoCVIFdGlwSWQSIQoJY3JlYXRlZEF0GAQgASgJSABSCWNyZWF0ZWRBdIgB'
    'AUIMCgpfY3JlYXRlZEF0');

@$core.Deprecated('Use notificationModelDescriptor instead')
const NotificationModel$json = {
  '1': 'NotificationModel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'userId', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'body', '3': 4, '4': 1, '5': 9, '10': 'body'},
    {'1': 'type', '3': 5, '4': 1, '5': 9, '10': 'type'},
    {'1': 'isRead', '3': 6, '4': 1, '5': 8, '10': 'isRead'},
    {
      '1': 'payload',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.wellness.NotificationModel.PayloadEntry',
      '10': 'payload'
    },
    {
      '1': 'timestamp',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'timestamp',
      '17': true
    },
  ],
  '3': [NotificationModel_PayloadEntry$json],
  '8': [
    {'1': '_timestamp'},
  ],
};

@$core.Deprecated('Use notificationModelDescriptor instead')
const NotificationModel_PayloadEntry$json = {
  '1': 'PayloadEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `NotificationModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationModelDescriptor = $convert.base64Decode(
    'ChFOb3RpZmljYXRpb25Nb2RlbBIOCgJpZBgBIAEoCVICaWQSFgoGdXNlcklkGAIgASgJUgZ1c2'
    'VySWQSFAoFdGl0bGUYAyABKAlSBXRpdGxlEhIKBGJvZHkYBCABKAlSBGJvZHkSEgoEdHlwZRgF'
    'IAEoCVIEdHlwZRIWCgZpc1JlYWQYBiABKAhSBmlzUmVhZBJCCgdwYXlsb2FkGAcgAygLMigud2'
    'VsbG5lc3MuTm90aWZpY2F0aW9uTW9kZWwuUGF5bG9hZEVudHJ5UgdwYXlsb2FkEiEKCXRpbWVz'
    'dGFtcBgIIAEoCUgAUgl0aW1lc3RhbXCIAQEaOgoMUGF5bG9hZEVudHJ5EhAKA2tleRgBIAEoCV'
    'IDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCDAoKX3RpbWVzdGFtcA==');

@$core.Deprecated('Use preferenceModelDescriptor instead')
const PreferenceModel$json = {
  '1': 'PreferenceModel',
  '2': [
    {'1': 'preferenceId', '3': 1, '4': 1, '5': 9, '10': 'preferenceId'},
    {'1': 'preferenceName', '3': 2, '4': 1, '5': 9, '10': 'preferenceName'},
    {'1': 'preferenceIcon', '3': 3, '4': 1, '5': 9, '10': 'preferenceIcon'},
    {
      '1': 'preferenceDescription',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'preferenceDescription'
    },
    {'1': 'isSvg', '3': 5, '4': 1, '5': 8, '10': 'isSvg'},
  ],
};

/// Descriptor for `PreferenceModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preferenceModelDescriptor = $convert.base64Decode(
    'Cg9QcmVmZXJlbmNlTW9kZWwSIgoMcHJlZmVyZW5jZUlkGAEgASgJUgxwcmVmZXJlbmNlSWQSJg'
    'oOcHJlZmVyZW5jZU5hbWUYAiABKAlSDnByZWZlcmVuY2VOYW1lEiYKDnByZWZlcmVuY2VJY29u'
    'GAMgASgJUg5wcmVmZXJlbmNlSWNvbhI0ChVwcmVmZXJlbmNlRGVzY3JpcHRpb24YBCABKAlSFX'
    'ByZWZlcmVuY2VEZXNjcmlwdGlvbhIUCgVpc1N2ZxgFIAEoCFIFaXNTdmc=');

@$core.Deprecated('Use reminderModelDescriptor instead')
const ReminderModel$json = {
  '1': 'ReminderModel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'userId', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'categoryId', '3': 4, '4': 1, '5': 9, '10': 'categoryId'},
    {'1': 'frequency', '3': 5, '4': 1, '5': 9, '10': 'frequency'},
    {'1': 'time', '3': 6, '4': 1, '5': 9, '10': 'time'},
    {
      '1': 'dayOfWeek',
      '3': 7,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'dayOfWeek',
      '17': true
    },
    {
      '1': 'createdAt',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'createdAt',
      '17': true
    },
    {
      '1': 'notificationId',
      '3': 9,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'notificationId',
      '17': true
    },
  ],
  '8': [
    {'1': '_dayOfWeek'},
    {'1': '_createdAt'},
    {'1': '_notificationId'},
  ],
};

/// Descriptor for `ReminderModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reminderModelDescriptor = $convert.base64Decode(
    'Cg1SZW1pbmRlck1vZGVsEg4KAmlkGAEgASgJUgJpZBIWCgZ1c2VySWQYAiABKAlSBnVzZXJJZB'
    'ISCgR0eXBlGAMgASgJUgR0eXBlEh4KCmNhdGVnb3J5SWQYBCABKAlSCmNhdGVnb3J5SWQSHAoJ'
    'ZnJlcXVlbmN5GAUgASgJUglmcmVxdWVuY3kSEgoEdGltZRgGIAEoCVIEdGltZRIhCglkYXlPZl'
    'dlZWsYByABKAVIAFIJZGF5T2ZXZWVriAEBEiEKCWNyZWF0ZWRBdBgIIAEoCUgBUgljcmVhdGVk'
    'QXSIAQESKwoObm90aWZpY2F0aW9uSWQYCSABKAVIAlIObm90aWZpY2F0aW9uSWSIAQFCDAoKX2'
    'RheU9mV2Vla0IMCgpfY3JlYXRlZEF0QhEKD19ub3RpZmljYXRpb25JZA==');

@$core.Deprecated('Use subscriptionModelDescriptor instead')
const SubscriptionModel$json = {
  '1': 'SubscriptionModel',
  '2': [
    {'1': 'userId', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'planId', '3': 2, '4': 1, '5': 9, '10': 'planId'},
    {'1': 'status', '3': 3, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'startDate',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'startDate',
      '17': true
    },
    {
      '1': 'endDate',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'endDate',
      '17': true
    },
    {
      '1': 'createdAt',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'createdAt',
      '17': true
    },
    {
      '1': 'updatedAt',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'updatedAt',
      '17': true
    },
    {'1': 'paymentMethod', '3': 8, '4': 1, '5': 9, '10': 'paymentMethod'},
    {
      '1': 'lastTransactionId',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'lastTransactionId',
      '17': true
    },
    {'1': 'isAutoRenew', '3': 10, '4': 1, '5': 8, '10': 'isAutoRenew'},
  ],
  '8': [
    {'1': '_startDate'},
    {'1': '_endDate'},
    {'1': '_createdAt'},
    {'1': '_updatedAt'},
    {'1': '_lastTransactionId'},
  ],
};

/// Descriptor for `SubscriptionModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionModelDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpcHRpb25Nb2RlbBIWCgZ1c2VySWQYASABKAlSBnVzZXJJZBIWCgZwbGFuSWQYAi'
    'ABKAlSBnBsYW5JZBIWCgZzdGF0dXMYAyABKAlSBnN0YXR1cxIhCglzdGFydERhdGUYBCABKAlI'
    'AFIJc3RhcnREYXRliAEBEh0KB2VuZERhdGUYBSABKAlIAVIHZW5kRGF0ZYgBARIhCgljcmVhdG'
    'VkQXQYBiABKAlIAlIJY3JlYXRlZEF0iAEBEiEKCXVwZGF0ZWRBdBgHIAEoCUgDUgl1cGRhdGVk'
    'QXSIAQESJAoNcGF5bWVudE1ldGhvZBgIIAEoCVINcGF5bWVudE1ldGhvZBIxChFsYXN0VHJhbn'
    'NhY3Rpb25JZBgJIAEoCUgEUhFsYXN0VHJhbnNhY3Rpb25JZIgBARIgCgtpc0F1dG9SZW5ldxgK'
    'IAEoCFILaXNBdXRvUmVuZXdCDAoKX3N0YXJ0RGF0ZUIKCghfZW5kRGF0ZUIMCgpfY3JlYXRlZE'
    'F0QgwKCl91cGRhdGVkQXRCFAoSX2xhc3RUcmFuc2FjdGlvbklk');

@$core.Deprecated('Use transactionModelDescriptor instead')
const TransactionModel$json = {
  '1': 'TransactionModel',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'userId', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'subscriptionId', '3': 3, '4': 1, '5': 9, '10': 'subscriptionId'},
    {
      '1': 'paymentProviderTransactionId',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'paymentProviderTransactionId'
    },
    {'1': 'paymentProvider', '3': 5, '4': 1, '5': 9, '10': 'paymentProvider'},
    {'1': 'amount', '3': 6, '4': 1, '5': 1, '10': 'amount'},
    {'1': 'currency', '3': 7, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'status', '3': 8, '4': 1, '5': 9, '10': 'status'},
    {'1': 'planId', '3': 9, '4': 1, '5': 9, '10': 'planId'},
    {
      '1': 'createdAt',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'createdAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_createdAt'},
  ],
};

/// Descriptor for `TransactionModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionModelDescriptor = $convert.base64Decode(
    'ChBUcmFuc2FjdGlvbk1vZGVsEg4KAmlkGAEgASgJUgJpZBIWCgZ1c2VySWQYAiABKAlSBnVzZX'
    'JJZBImCg5zdWJzY3JpcHRpb25JZBgDIAEoCVIOc3Vic2NyaXB0aW9uSWQSQgoccGF5bWVudFBy'
    'b3ZpZGVyVHJhbnNhY3Rpb25JZBgEIAEoCVIccGF5bWVudFByb3ZpZGVyVHJhbnNhY3Rpb25JZB'
    'IoCg9wYXltZW50UHJvdmlkZXIYBSABKAlSD3BheW1lbnRQcm92aWRlchIWCgZhbW91bnQYBiAB'
    'KAFSBmFtb3VudBIaCghjdXJyZW5jeRgHIAEoCVIIY3VycmVuY3kSFgoGc3RhdHVzGAggASgJUg'
    'ZzdGF0dXMSFgoGcGxhbklkGAkgASgJUgZwbGFuSWQSIQoJY3JlYXRlZEF0GAogASgJSABSCWNy'
    'ZWF0ZWRBdIgBAUIMCgpfY3JlYXRlZEF0');

@$core.Deprecated('Use tipModelDescriptor instead')
const TipModel$json = {
  '1': 'TipModel',
  '2': [
    {'1': 'tipsId', '3': 1, '4': 1, '5': 9, '10': 'tipsId'},
    {'1': 'tipsTitle', '3': 2, '4': 1, '5': 9, '10': 'tipsTitle'},
    {'1': 'tipsDescription', '3': 3, '4': 1, '5': 9, '10': 'tipsDescription'},
    {'1': 'tipsType', '3': 4, '4': 1, '5': 9, '10': 'tipsType'},
    {'1': 'tipsAuthor', '3': 5, '4': 1, '5': 9, '10': 'tipsAuthor'},
    {
      '1': 'authorIcon',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'authorIcon',
      '17': true
    },
    {'1': 'preferenceIds', '3': 7, '4': 3, '5': 9, '10': 'preferenceIds'},
    {'1': 'categoryId', '3': 8, '4': 1, '5': 9, '10': 'categoryId'},
    {
      '1': 'createdAt',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'createdAt',
      '17': true
    },
    {'1': 'isFeatured', '3': 10, '4': 1, '5': 8, '10': 'isFeatured'},
    {'1': 'isPremium', '3': 11, '4': 1, '5': 8, '10': 'isPremium'},
    {
      '1': 'audioUrl',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'audioUrl',
      '17': true
    },
    {
      '1': 'videoUrl',
      '3': 13,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'videoUrl',
      '17': true
    },
    {
      '1': 'thumbnailUrl',
      '3': 14,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'thumbnailUrl',
      '17': true
    },
    {
      '1': 'mediaDuration',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'mediaDuration',
      '17': true
    },
    {
      '1': 'imageUrl',
      '3': 16,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'imageUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_authorIcon'},
    {'1': '_createdAt'},
    {'1': '_audioUrl'},
    {'1': '_videoUrl'},
    {'1': '_thumbnailUrl'},
    {'1': '_mediaDuration'},
    {'1': '_imageUrl'},
  ],
};

/// Descriptor for `TipModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tipModelDescriptor = $convert.base64Decode(
    'CghUaXBNb2RlbBIWCgZ0aXBzSWQYASABKAlSBnRpcHNJZBIcCgl0aXBzVGl0bGUYAiABKAlSCX'
    'RpcHNUaXRsZRIoCg90aXBzRGVzY3JpcHRpb24YAyABKAlSD3RpcHNEZXNjcmlwdGlvbhIaCgh0'
    'aXBzVHlwZRgEIAEoCVIIdGlwc1R5cGUSHgoKdGlwc0F1dGhvchgFIAEoCVIKdGlwc0F1dGhvch'
    'IjCgphdXRob3JJY29uGAYgASgJSABSCmF1dGhvckljb26IAQESJAoNcHJlZmVyZW5jZUlkcxgH'
    'IAMoCVINcHJlZmVyZW5jZUlkcxIeCgpjYXRlZ29yeUlkGAggASgJUgpjYXRlZ29yeUlkEiEKCW'
    'NyZWF0ZWRBdBgJIAEoCUgBUgljcmVhdGVkQXSIAQESHgoKaXNGZWF0dXJlZBgKIAEoCFIKaXNG'
    'ZWF0dXJlZBIcCglpc1ByZW1pdW0YCyABKAhSCWlzUHJlbWl1bRIfCghhdWRpb1VybBgMIAEoCU'
    'gCUghhdWRpb1VybIgBARIfCgh2aWRlb1VybBgNIAEoCUgDUgh2aWRlb1VybIgBARInCgx0aHVt'
    'Ym5haWxVcmwYDiABKAlIBFIMdGh1bWJuYWlsVXJsiAEBEikKDW1lZGlhRHVyYXRpb24YDyABKA'
    'lIBVINbWVkaWFEdXJhdGlvbogBARIfCghpbWFnZVVybBgQIAEoCUgGUghpbWFnZVVybIgBAUIN'
    'CgtfYXV0aG9ySWNvbkIMCgpfY3JlYXRlZEF0QgsKCV9hdWRpb1VybEILCglfdmlkZW9VcmxCDw'
    'oNX3RodW1ibmFpbFVybEIQCg5fbWVkaWFEdXJhdGlvbkILCglfaW1hZ2VVcmw=');

@$core.Deprecated('Use userModelDescriptor instead')
const UserModel$json = {
  '1': 'UserModel',
  '2': [
    {'1': 'userId', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'userEmail', '3': 2, '4': 1, '5': 9, '10': 'userEmail'},
    {'1': 'userName', '3': 3, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'userRole', '3': 4, '4': 1, '5': 9, '10': 'userRole'},
    {
      '1': 'preferenceCompleted',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'preferenceCompleted'
    },
    {'1': 'createdAt', '3': 6, '4': 1, '5': 9, '10': 'createdAt'},
    {
      '1': 'photoURL',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'photoURL',
      '17': true
    },
    {
      '1': 'fcmToken',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'fcmToken',
      '17': true
    },
  ],
  '8': [
    {'1': '_photoURL'},
    {'1': '_fcmToken'},
  ],
};

/// Descriptor for `UserModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userModelDescriptor = $convert.base64Decode(
    'CglVc2VyTW9kZWwSFgoGdXNlcklkGAEgASgJUgZ1c2VySWQSHAoJdXNlckVtYWlsGAIgASgJUg'
    'l1c2VyRW1haWwSGgoIdXNlck5hbWUYAyABKAlSCHVzZXJOYW1lEhoKCHVzZXJSb2xlGAQgASgJ'
    'Ugh1c2VyUm9sZRIwChNwcmVmZXJlbmNlQ29tcGxldGVkGAUgASgIUhNwcmVmZXJlbmNlQ29tcG'
    'xldGVkEhwKCWNyZWF0ZWRBdBgGIAEoCVIJY3JlYXRlZEF0Eh8KCHBob3RvVVJMGAcgASgJSABS'
    'CHBob3RvVVJMiAEBEh8KCGZjbVRva2VuGAggASgJSAFSCGZjbVRva2VuiAEBQgsKCV9waG90b1'
    'VSTEILCglfZmNtVG9rZW4=');

@$core.Deprecated('Use userPreferenceEntryDescriptor instead')
const UserPreferenceEntry$json = {
  '1': 'UserPreferenceEntry',
  '2': [
    {'1': 'preferenceId', '3': 1, '4': 1, '5': 9, '10': 'preferenceId'},
    {
      '1': 'selectedAt',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'selectedAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_selectedAt'},
  ],
};

/// Descriptor for `UserPreferenceEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPreferenceEntryDescriptor = $convert.base64Decode(
    'ChNVc2VyUHJlZmVyZW5jZUVudHJ5EiIKDHByZWZlcmVuY2VJZBgBIAEoCVIMcHJlZmVyZW5jZU'
    'lkEiMKCnNlbGVjdGVkQXQYAiABKAlIAFIKc2VsZWN0ZWRBdIgBAUINCgtfc2VsZWN0ZWRBdA==');

@$core.Deprecated('Use userPreferenceModelDescriptor instead')
const UserPreferenceModel$json = {
  '1': 'UserPreferenceModel',
  '2': [
    {'1': 'userId', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {
      '1': 'preferences',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.wellness.UserPreferenceEntry',
      '10': 'preferences'
    },
    {
      '1': 'updatedAt',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'updatedAt',
      '17': true
    },
  ],
  '8': [
    {'1': '_updatedAt'},
  ],
};

/// Descriptor for `UserPreferenceModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userPreferenceModelDescriptor = $convert.base64Decode(
    'ChNVc2VyUHJlZmVyZW5jZU1vZGVsEhYKBnVzZXJJZBgBIAEoCVIGdXNlcklkEj8KC3ByZWZlcm'
    'VuY2VzGAIgAygLMh0ud2VsbG5lc3MuVXNlclByZWZlcmVuY2VFbnRyeVILcHJlZmVyZW5jZXMS'
    'IQoJdXBkYXRlZEF0GAMgASgJSABSCXVwZGF0ZWRBdIgBAUIMCgpfdXBkYXRlZEF0');
