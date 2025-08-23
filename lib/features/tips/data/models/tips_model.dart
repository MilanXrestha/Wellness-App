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

  // New fields for video statistics and classification
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int durationInSeconds;
  final bool isShort;

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
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.durationInSeconds = 0,
    this.isShort = false,
  });

  factory TipModel.fromFirestore(Map<String, dynamic> data, String tipsId) {
    try {
      // Parse mediaDuration to calculate durationInSeconds if not already provided
      int durationInSeconds = 0;
      if (data['durationInSeconds'] != null) {
        durationInSeconds = (data['durationInSeconds'] is int)
            ? data['durationInSeconds']
            : (data['durationInSeconds'] as num).toInt();
      }

      if (durationInSeconds == 0 && data['mediaDuration'] != null) {
        String duration = data['mediaDuration'].toString();
        // Parse durations like "1:30" or "01:30"
        List<String> parts = duration.split(':');
        if (parts.length == 2) {
          int minutes = int.tryParse(parts[0].trim()) ?? 0;
          int seconds = int.tryParse(parts[1].trim()) ?? 0;
          durationInSeconds = (minutes * 60) + seconds;
        } else if (parts.length == 3) {
          // Handle HH:MM:SS format
          int hours = int.tryParse(parts[0].trim()) ?? 0;
          int minutes = int.tryParse(parts[1].trim()) ?? 0;
          int seconds = int.tryParse(parts[2].trim()) ?? 0;
          durationInSeconds = (hours * 3600) + (minutes * 60) + seconds;
        }
      }

      // Determine if video is a short based on duration
      bool isShort =
          data['isShort'] as bool? ??
              (durationInSeconds > 0 && durationInSeconds < 60);

      // Safe conversions for numeric fields
      int viewCount = 0;
      if (data['viewCount'] != null) {
        viewCount = (data['viewCount'] is int)
            ? data['viewCount']
            : (data['viewCount'] as num).toInt();
      }

      int likeCount = 0;
      if (data['likeCount'] != null) {
        likeCount = (data['likeCount'] is int)
            ? data['likeCount']
            : (data['likeCount'] as num).toInt();
      }

      int commentCount = 0;
      if (data['commentCount'] != null) {
        commentCount = (data['commentCount'] is int)
            ? data['commentCount']
            : (data['commentCount'] as num).toInt();
      }

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
        // Safe numeric fields
        viewCount: viewCount,
        likeCount: likeCount,
        commentCount: commentCount,
        durationInSeconds: durationInSeconds,
        isShort: isShort,
      );
    } catch (e, stackTrace) {
      print('Error parsing TipModel for tipsId $tipsId: $e');
      print(stackTrace);
      rethrow;
    }
  }

  factory TipModel.fromJson(Map<String, dynamic> json) {
    // Parse duration for the JSON case
    int durationInSeconds = 0;
    if (json['durationInSeconds'] != null) {
      durationInSeconds = (json['durationInSeconds'] is int)
          ? json['durationInSeconds']
          : (json['durationInSeconds'] as num).toInt();
    }

    if (durationInSeconds == 0 && json['mediaDuration'] != null) {
      String duration = json['mediaDuration'].toString();
      List<String> parts = duration.split(':');
      if (parts.length == 2) {
        int minutes = int.tryParse(parts[0].trim()) ?? 0;
        int seconds = int.tryParse(parts[1].trim()) ?? 0;
        durationInSeconds = (minutes * 60) + seconds;
      } else if (parts.length == 3) {
        int hours = int.tryParse(parts[0].trim()) ?? 0;
        int minutes = int.tryParse(parts[1].trim()) ?? 0;
        int seconds = int.tryParse(parts[2].trim()) ?? 0;
        durationInSeconds = (hours * 3600) + (minutes * 60) + seconds;
      }
    }

    bool isShort =
        json['isShort'] as bool? ??
            (durationInSeconds > 0 && durationInSeconds < 60);

    // Safe conversions for numeric fields
    int viewCount = 0;
    if (json['viewCount'] != null) {
      viewCount = (json['viewCount'] is int)
          ? json['viewCount']
          : (json['viewCount'] as num).toInt();
    }

    int likeCount = 0;
    if (json['likeCount'] != null) {
      likeCount = (json['likeCount'] is int)
          ? json['likeCount']
          : (json['likeCount'] as num).toInt();
    }

    int commentCount = 0;
    if (json['commentCount'] != null) {
      commentCount = (json['commentCount'] is int)
          ? json['commentCount']
          : (json['commentCount'] as num).toInt();
    }

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
      // Safe numeric fields
      viewCount: viewCount,
      likeCount: likeCount,
      commentCount: commentCount,
      durationInSeconds: durationInSeconds,
      isShort: isShort,
    );
  }

  factory TipModel.fromMap(Map<String, dynamic> map) {
    // Parse duration for the Map case
    int durationInSeconds = 0;
    if (map['durationInSeconds'] != null) {
      durationInSeconds = (map['durationInSeconds'] is int)
          ? map['durationInSeconds']
          : (map['durationInSeconds'] as num).toInt();
    }

    if (durationInSeconds == 0 && map['mediaDuration'] != null) {
      String duration = map['mediaDuration'].toString();
      List<String> parts = duration.split(':');
      if (parts.length == 2) {
        int minutes = int.tryParse(parts[0].trim()) ?? 0;
        int seconds = int.tryParse(parts[1].trim()) ?? 0;
        durationInSeconds = (minutes * 60) + seconds;
      } else if (parts.length == 3) {
        int hours = int.tryParse(parts[0].trim()) ?? 0;
        int minutes = int.tryParse(parts[1].trim()) ?? 0;
        int seconds = int.tryParse(parts[2].trim()) ?? 0;
        durationInSeconds = (hours * 3600) + (minutes * 60) + seconds;
      }
    }

    // Safe conversion for isShort
    bool isShort = false;
    if (map['isShort'] != null) {
      isShort = map['isShort'] is bool
          ? map['isShort']
          : (map['isShort'] is int ? map['isShort'] == 1 : false);
    }
    isShort = isShort || (durationInSeconds > 0 && durationInSeconds < 60);

    // Safe conversions for numeric fields
    int viewCount = 0;
    if (map['viewCount'] != null) {
      viewCount = (map['viewCount'] is int)
          ? map['viewCount']
          : (map['viewCount'] as num).toInt();
    }

    int likeCount = 0;
    if (map['likeCount'] != null) {
      likeCount = (map['likeCount'] is int)
          ? map['likeCount']
          : (map['likeCount'] as num).toInt();
    }

    int commentCount = 0;
    if (map['commentCount'] != null) {
      commentCount = (map['commentCount'] is int)
          ? map['commentCount']
          : (map['commentCount'] as num).toInt();
    }

    return TipModel(
      tipsId: map['tipsId'] as String? ?? '',
      tipsTitle: map['tipsTitle'] as String? ?? '',
      tipsDescription: map['tipsDescription'] as String? ?? '',
      tipsType: map['tipsType'] as String? ?? 'tip',
      tipsAuthor: map['tipsAuthor'] as String? ?? '',
      authorIcon: map['authorIcon'] as String?,
      preferenceIds: List<String>.from(
        jsonDecode(map['preferenceIds'] as String? ?? '[]'),
      ),
      categoryId: map['categoryId'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      isFeatured: (map['isFeatured'] as int? ?? 0) == 1,
      isPremium: (map['isPremium'] as int? ?? 0) == 1,
      audioUrl: map['audioUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      mediaDuration: map['mediaDuration'] as String?,
      imageUrl: map['imageUrl'] as String?,
      // Safe numeric fields
      viewCount: viewCount,
      likeCount: likeCount,
      commentCount: commentCount,
      durationInSeconds: durationInSeconds,
      isShort: isShort,
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
      ..imageUrl = imageUrl ?? ''
    // New fields
      ..viewCount = viewCount
      ..likeCount = likeCount
      ..commentCount = commentCount
      ..durationInSeconds = durationInSeconds
      ..isShort = isShort;

    return proto.writeToBuffer();
  }

  factory TipModel.fromProto(List<int> bytes) {
    final proto = pb.TipModel.fromBuffer(bytes);

    // Calculate duration and isShort
    int durationInSeconds = proto.durationInSeconds;

    if (durationInSeconds == 0 && proto.mediaDuration.isNotEmpty) {
      List<String> parts = proto.mediaDuration.split(':');
      if (parts.length == 2) {
        int minutes = int.tryParse(parts[0].trim()) ?? 0;
        int seconds = int.tryParse(parts[1].trim()) ?? 0;
        durationInSeconds = (minutes * 60) + seconds;
      } else if (parts.length == 3) {
        int hours = int.tryParse(parts[0].trim()) ?? 0;
        int minutes = int.tryParse(parts[1].trim()) ?? 0;
        int seconds = int.tryParse(parts[2].trim()) ?? 0;
        durationInSeconds = (hours * 3600) + (minutes * 60) + seconds;
      }
    }

    bool isShort =
        proto.isShort || (durationInSeconds > 0 && durationInSeconds < 60);

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
      mediaDuration: proto.mediaDuration.isNotEmpty
          ? proto.mediaDuration
          : null,
      imageUrl: proto.imageUrl.isNotEmpty ? proto.imageUrl : null,
      // New fields
      viewCount: proto.viewCount,
      likeCount: proto.likeCount,
      commentCount: proto.commentCount,
      durationInSeconds: durationInSeconds,
      isShort: isShort,
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
      // New fields
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'durationInSeconds': durationInSeconds,
      'isShort': isShort,
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
      // New fields
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'durationInSeconds': durationInSeconds,
      'isShort': isShort,
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
      // New fields
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'durationInSeconds': durationInSeconds,
      'isShort': isShort ? 1 : 0,
    };
  }

  // Helper method to get formatted duration
  String getFormattedDuration() {
    if (mediaDuration != null && mediaDuration!.isNotEmpty) {
      return mediaDuration!;
    }

    if (durationInSeconds <= 0) {
      return "0:00";
    }

    int hours = durationInSeconds ~/ 3600;
    int minutes = (durationInSeconds % 3600) ~/ 60;
    int seconds = durationInSeconds % 60;

    if (hours > 0) {
      return "${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes}:${seconds.toString().padLeft(2, '0')}";
    }
  }

  // Helper to format view count with K, M, etc.
  String getFormattedViewCount() {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K views';
    } else {
      return '$viewCount views';
    }
  }

  // Helper to format the date in a readable way
  String getFormattedDate() {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Helper to check if this video is a short
  bool get isVideoShort => isShort || durationInSeconds < 60;

  // Helper to check if this is a video
  bool get isVideo =>
      tipsType == 'video' && videoUrl != null && videoUrl!.isNotEmpty;

  // Helper to get a copy of this model with updated fields
  TipModel copyWith({
    String? tipsId,
    String? tipsTitle,
    String? tipsDescription,
    String? tipsType,
    String? tipsAuthor,
    String? authorIcon,
    List<String>? preferenceIds,
    String? categoryId,
    DateTime? createdAt,
    bool? isFeatured,
    bool? isPremium,
    String? audioUrl,
    String? videoUrl,
    String? thumbnailUrl,
    String? mediaDuration,
    String? imageUrl,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? durationInSeconds,
    bool? isShort,
  }) {
    return TipModel(
      tipsId: tipsId ?? this.tipsId,
      tipsTitle: tipsTitle ?? this.tipsTitle,
      tipsDescription: tipsDescription ?? this.tipsDescription,
      tipsType: tipsType ?? this.tipsType,
      tipsAuthor: tipsAuthor ?? this.tipsAuthor,
      authorIcon: authorIcon ?? this.authorIcon,
      preferenceIds: preferenceIds ?? this.preferenceIds,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isPremium: isPremium ?? this.isPremium,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      imageUrl: imageUrl ?? this.imageUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      isShort: isShort ?? this.isShort,
    );
  }
}