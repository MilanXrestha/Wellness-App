// Preference Model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:protobuf/protobuf.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class PreferenceModel {
  final String preferenceId;
  final String preferenceName;
  final String preferenceIcon;
  final String preferenceDescription;
  final bool isSvg;

  PreferenceModel({
    required this.preferenceId,
    required this.preferenceName,
    required this.preferenceIcon,
    required this.preferenceDescription,
    this.isSvg = false,
  });

  bool get isNetworkIcon => preferenceIcon.startsWith('http');

  factory PreferenceModel.fromFirestore(Map<String, dynamic> data, String preferenceId) {
    return PreferenceModel(
      preferenceId: preferenceId,
      preferenceName: data['preferenceName'] as String? ?? '',
      preferenceIcon: data['preferenceIcon'] as String? ?? '',
      preferenceDescription: data['preferenceDescription'] as String? ?? '',
      isSvg: data['isSvg'] as bool? ?? false,
    );
  }

  factory PreferenceModel.fromJson(Map<String, dynamic> json) {
    return PreferenceModel(
      preferenceId: json['preferenceId'] as String? ?? '',
      preferenceName: json['preferenceName'] as String? ?? '',
      preferenceIcon: json['preferenceIcon'] as String? ?? '',
      preferenceDescription: json['preferenceDescription'] as String? ?? '',
      isSvg: json['isSvg'] as bool? ?? false,
    );
  }

  factory PreferenceModel.fromMap(Map<String, dynamic> map) {
    return PreferenceModel(
      preferenceId: map['preferenceId'] as String? ?? '',
      preferenceName: map['preferenceName'] as String? ?? '',
      preferenceIcon: map['preferenceIcon'] as String? ?? '',
      preferenceDescription: map['preferenceDescription'] as String? ?? '',
      isSvg: (map['isSvg'] as int? ?? 0) == 1,
    );
  }

  List<int> toProto() {
    final proto = pb.PreferenceModel()
      ..preferenceId = preferenceId
      ..preferenceName = preferenceName
      ..preferenceIcon = preferenceIcon
      ..preferenceDescription = preferenceDescription
      ..isSvg = isSvg;
    return proto.writeToBuffer();
  }

  factory PreferenceModel.fromProto(List<int> bytes) {
    final proto = pb.PreferenceModel.fromBuffer(bytes);
    return PreferenceModel(
      preferenceId: proto.preferenceId,
      preferenceName: proto.preferenceName,
      preferenceIcon: proto.preferenceIcon,
      preferenceDescription: proto.preferenceDescription,
      isSvg: proto.isSvg,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'preferenceName': preferenceName,
      'preferenceIcon': preferenceIcon,
      'preferenceDescription': preferenceDescription,
      'isSvg': isSvg,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'preferenceId': preferenceId,
      'preferenceName': preferenceName,
      'preferenceIcon': preferenceIcon,
      'preferenceDescription': preferenceDescription,
      'isSvg': isSvg,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'preferenceId': preferenceId,
      'preferenceName': preferenceName,
      'preferenceIcon': preferenceIcon,
      'preferenceDescription': preferenceDescription,
      'isSvg': isSvg ? 1 : 0,
    };
  }
}