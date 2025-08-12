// Category Model
import 'dart:convert';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String imageUrl;
  final List<String> preferenceIds;
  final String? categoryDescription;
  final DateTime createdAt;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    required this.preferenceIds,
    this.categoryDescription,
    required this.createdAt,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
      categoryId: id,
      categoryName: data['categoryName'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      preferenceIds: List<String>.from(data['preferenceIds'] ?? []),
      categoryDescription: data['categoryDescription'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      preferenceIds: List<String>.from(json['preferenceIds'] ?? []),
      categoryDescription: json['categoryDescription'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      preferenceIds: List<String>.from(jsonDecode(map['preferenceIds'] as String? ?? '[]')),
      categoryDescription: map['categoryDescription'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  List<int> toProto() {
    final proto = pb.CategoryModel()
      ..categoryId = categoryId
      ..categoryName = categoryName
      ..imageUrl = imageUrl
      ..preferenceIds.addAll(preferenceIds)
      ..categoryDescription = categoryDescription ?? ''
      ..createdAt = createdAt.toIso8601String();
    return proto.writeToBuffer();
  }

  factory CategoryModel.fromProto(List<int> bytes) {
    final proto = pb.CategoryModel.fromBuffer(bytes);
    return CategoryModel(
      categoryId: proto.categoryId,
      categoryName: proto.categoryName,
      imageUrl: proto.imageUrl,
      preferenceIds: proto.preferenceIds,
      categoryDescription: proto.hasCategoryDescription() ? proto.categoryDescription : null,
      createdAt: DateTime.parse(proto.createdAt),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'preferenceIds': preferenceIds,
      if (categoryDescription != null) 'categoryDescription': categoryDescription,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'preferenceIds': preferenceIds,
      'categoryDescription': categoryDescription,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'preferenceIds': jsonEncode(preferenceIds),
      'categoryDescription': categoryDescription,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}