// User Preference Model
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'package:protobuf/protobuf.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class UserPreferenceEntry {
  final String preferenceId;
  final DateTime? selectedAt;
  final pb.PreferenceModel? preference;

  UserPreferenceEntry({required this.preferenceId, this.selectedAt, this.preference});

  factory UserPreferenceEntry.fromFirestore(Map<String, dynamic> data) {
    return UserPreferenceEntry(
      preferenceId: data['preferenceId'] as String? ?? '',
      selectedAt: (data['selectedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserPreferenceEntry.fromJson(Map<String, dynamic> json) {
    return UserPreferenceEntry(
      preferenceId: json['preferenceId'] as String? ?? '',
      selectedAt: _parseDate(json['selectedAt']),
    );
  }

  factory UserPreferenceEntry.fromMap(Map<String, dynamic> map) {
    return UserPreferenceEntry(
      preferenceId: map['preferenceId'] as String? ?? '',
      selectedAt: _parseDate(map['selectedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in UserPreferenceEntry: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.UserPreferenceEntry()
      ..preferenceId = preferenceId
      ..selectedAt = selectedAt?.toIso8601String() ?? '';
    return proto.writeToBuffer();
  }

  factory UserPreferenceEntry.fromProto(List<int> bytes) {
    final proto = pb.UserPreferenceEntry.fromBuffer(bytes);
    return UserPreferenceEntry(
      preferenceId: proto.preferenceId,
      selectedAt: proto.hasSelectedAt() ? DateTime.parse(proto.selectedAt) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'preferenceId': preferenceId,
      if (selectedAt != null) 'selectedAt': Timestamp.fromDate(selectedAt!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'preferenceId': preferenceId,
      'selectedAt': selectedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap({required String userId}) {
    return {
      'userId': userId,
      'preferenceId': preferenceId,
      'selectedAt': selectedAt?.toIso8601String(),
    };
  }
}

class UserPreferenceModel {
  final String userId;
  final List<UserPreferenceEntry> preferences;
  final DateTime? updatedAt;

  UserPreferenceModel({
    required this.userId,
    required this.preferences,
    this.updatedAt,
  });

  factory UserPreferenceModel.fromFirestore(Map<String, dynamic> data, String userId) {
    final preferencesData = data['preferences'] as List<dynamic>? ?? [];
    return UserPreferenceModel(
      userId: data['userId'] as String? ?? userId,
      preferences: preferencesData
          .map((item) => UserPreferenceEntry.fromFirestore(item as Map<String, dynamic>))
          .toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      userId: json['userId'] as String? ?? '',
      preferences: (json['preferences'] as List<dynamic>? ?? [])
          .map((item) => UserPreferenceEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  factory UserPreferenceModel.fromMap(Map<String, dynamic> map, List<UserPreferenceEntry> entries) {
    return UserPreferenceModel(
      userId: map['userId'] as String? ?? '',
      preferences: entries,
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in UserPreferenceModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.UserPreferenceModel()
      ..userId = userId
      ..preferences.addAll(preferences.map((entry) => pb.UserPreferenceEntry()
        ..preferenceId = entry.preferenceId
        ..selectedAt = entry.selectedAt?.toIso8601String() ?? ''))
      ..updatedAt = updatedAt?.toIso8601String() ?? '';
    return proto.writeToBuffer();
  }

  factory UserPreferenceModel.fromProto(List<int> bytes) {
    final proto = pb.UserPreferenceModel.fromBuffer(bytes);
    return UserPreferenceModel(
      userId: proto.userId,
      preferences: proto.preferences
          .map((entry) => UserPreferenceEntry(
        preferenceId: entry.preferenceId,
        selectedAt: entry.hasSelectedAt() ? DateTime.parse(entry.selectedAt) : null,
      ))
          .toList(),
      updatedAt: proto.hasUpdatedAt() ? DateTime.parse(proto.updatedAt) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'preferences': preferences.map((entry) => entry.toFirestore()).toList(),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'preferences': preferences.map((entry) => entry.toJson()).toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> toMapList() {
    return preferences.map((entry) => entry.toMap(userId: userId)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}