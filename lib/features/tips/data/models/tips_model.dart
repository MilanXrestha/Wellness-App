// Tip Model
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class TipModel {
  final String tipsId;
  final String tipsTitle;
  final String tipsDescription;
  final String tipsType;
  final String tipsAuthor;
  final String? authorIcon;
  final List<String> preferenceIds;
  final String categoryId;
  final DateTime? createdAt;
  final bool isFeatured;
  final bool isPremium;
  final String? audioUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? mediaDuration;
  final String? imageUrl;

  TipModel({
    required this.tipsId,
    required this.tipsTitle,
    required this.tipsDescription,
    required this.tipsType,
    required this.tipsAuthor,
    this.authorIcon,
    required this.preferenceIds,
    required this.categoryId,
    this.createdAt,
    this.isFeatured = false,
    this.isPremium = false,
    this.audioUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.mediaDuration,
    this.imageUrl,
  });

  factory TipModel.fromFirestore(Map<String, dynamic> data, String tipsId) {
    try {
      return TipModel(
        tipsId: tipsId,
        tipsTitle: data['tipsTitle']?.toString() ?? '',
        tipsDescription: data['tipsDescription']?.toString() ?? '',
        tipsType: data['tipsType']?.toString() ?? 'tip',
        tipsAuthor: data['tipsAuthor']?.toString() ?? '',
        authorIcon: data['authorIcon']?.toString(),
        preferenceIds: List<String>.from(data['preferenceIds'] ?? []),
        categoryId: data['categoryId']?.toString() ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        isFeatured: data['isFeatured'] as bool? ?? false,
        isPremium: data['isPremium'] as bool? ?? false,
        audioUrl: data['audioUrl']?.toString(),
        videoUrl: data['videoUrl']?.toString(),
        thumbnailUrl: data['thumbnailUrl']?.toString(),
        mediaDuration: data['mediaDuration']?.toString(),
        imageUrl: data['imageUrl']?.toString(),
      );
    } catch (e, stackTrace) {
      print('Error parsing TipModel for tipsId $tipsId: $e');
      print(stackTrace);
      rethrow;
    }
  }

  factory TipModel.fromJson(Map<String, dynamic> json) {
    return TipModel(
      tipsId: json['tipsId'] as String? ?? '',
      tipsTitle: json['tipsTitle'] as String? ?? '',
      tipsDescription: json['tipsDescription'] as String? ?? '',
      tipsType: json['tipsType'] as String? ?? 'tip',
      tipsAuthor: json['tipsAuthor'] as String? ?? '',
      authorIcon: json['authorIcon'] as String?,
      preferenceIds: List<String>.from(json['preferenceIds'] ?? []),
      categoryId: json['categoryId'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      audioUrl: json['audioUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediaDuration: json['mediaDuration'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  factory TipModel.fromMap(Map<String, dynamic> map) {
    return TipModel(
      tipsId: map['tipsId'] as String? ?? '',
      tipsTitle: map['tipsTitle'] as String? ?? '',
      tipsDescription: map['tipsDescription'] as String? ?? '',
      tipsType: map['tipsType'] as String? ?? 'tip',
      tipsAuthor: map['tipsAuthor'] as String? ?? '',
      authorIcon: map['authorIcon'] as String?,
      preferenceIds: List<String>.from(jsonDecode(map['preferenceIds'] as String? ?? '[]')),
      categoryId: map['categoryId'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      isFeatured: (map['isFeatured'] as int? ?? 0) == 1,
      isPremium: (map['isPremium'] as int? ?? 0) == 1,
      audioUrl: map['audioUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      mediaDuration: map['mediaDuration'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in TipModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.TipModel()
      ..tipsId = tipsId
      ..tipsTitle = tipsTitle
      ..tipsDescription = tipsDescription
      ..tipsType = tipsType
      ..tipsAuthor = tipsAuthor
      ..authorIcon = authorIcon ?? ''
      ..preferenceIds.addAll(preferenceIds)
      ..categoryId = categoryId
      ..createdAt = createdAt?.toIso8601String() ?? ''
      ..isFeatured = isFeatured
      ..isPremium = isPremium
      ..audioUrl = audioUrl ?? ''
      ..videoUrl = videoUrl ?? ''
      ..thumbnailUrl = thumbnailUrl ?? ''
      ..mediaDuration = mediaDuration ?? ''
      ..imageUrl = imageUrl ?? '';
    return proto.writeToBuffer();
  }

  factory TipModel.fromProto(List<int> bytes) {
    final proto = pb.TipModel.fromBuffer(bytes);
    return TipModel(
      tipsId: proto.tipsId,
      tipsTitle: proto.tipsTitle,
      tipsDescription: proto.tipsDescription,
      tipsType: proto.tipsType,
      tipsAuthor: proto.tipsAuthor,
      authorIcon: proto.hasAuthorIcon() ? proto.authorIcon : null,
      preferenceIds: proto.preferenceIds,
      categoryId: proto.categoryId,
      createdAt: proto.hasCreatedAt() ? DateTime.parse(proto.createdAt) : null,
      isFeatured: proto.isFeatured,
      isPremium: proto.isPremium,
      audioUrl: proto.audioUrl.isNotEmpty ? proto.audioUrl : null,
      videoUrl: proto.videoUrl.isNotEmpty ? proto.videoUrl : null,
      thumbnailUrl: proto.thumbnailUrl.isNotEmpty ? proto.thumbnailUrl : null,
      mediaDuration: proto.mediaDuration.isNotEmpty ? proto.mediaDuration : null,
      imageUrl: proto.imageUrl.isNotEmpty ? proto.imageUrl : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipsTitle': tipsTitle,
      'tipsDescription': tipsDescription,
      'tipsType': tipsType,
      'tipsAuthor': tipsAuthor,
      if (authorIcon != null) 'authorIcon': authorIcon,
      'preferenceIds': preferenceIds,
      'categoryId': categoryId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'isFeatured': isFeatured,
      'isPremium': isPremium,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (mediaDuration != null) 'mediaDuration': mediaDuration,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'tipsId': tipsId,
      'tipsTitle': tipsTitle,
      'tipsDescription': tipsDescription,
      'tipsType': tipsType,
      'tipsAuthor': tipsAuthor,
      'authorIcon': authorIcon,
      'preferenceIds': preferenceIds,
      'categoryId': categoryId,
      'createdAt': createdAt?.toIso8601String(),
      'isFeatured': isFeatured,
      'isPremium': isPremium,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaDuration': mediaDuration,
      'imageUrl': imageUrl,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'tipsId': tipsId,
      'tipsTitle': tipsTitle,
      'tipsDescription': tipsDescription,
      'tipsType': tipsType,
      'tipsAuthor': tipsAuthor,
      'authorIcon': authorIcon,
      'preferenceIds': jsonEncode(preferenceIds),
      'categoryId': categoryId,
      'createdAt': createdAt?.toIso8601String(),
      'isFeatured': isFeatured ? 1 : 0,
      'isPremium': isPremium ? 1 : 0,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaDuration': mediaDuration,
      'imageUrl': imageUrl,
    };
  }
}