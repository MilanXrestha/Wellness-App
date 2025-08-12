// Subscription Model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:protobuf/protobuf.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class SubscriptionModel {
  final String userId;
  final String planId;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String paymentMethod;
  final String? lastTransactionId;
  final bool isAutoRenew;

  SubscriptionModel({
    required this.userId,
    required this.planId,
    required this.status,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    required this.paymentMethod,
    this.lastTransactionId,
    required this.isAutoRenew,
  });

  factory SubscriptionModel.fromFirestore(Map<String, dynamic> data, String userId) {
    return SubscriptionModel(
      userId: userId,
      planId: data['planId'] as String? ?? '',
      status: data['status'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'] as String? ?? '',
      lastTransactionId: data['transactionId'] as String?,
      isAutoRenew: data['isAutoRenew'] as bool? ?? false,
    );
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      userId: json['userId'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      lastTransactionId: json['lastTransactionId'] as String?,
      isAutoRenew: json['isAutoRenew'] as bool? ?? false,
    );
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      userId: map['userId'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      status: map['status'] as String? ?? '',
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      paymentMethod: map['paymentMethod'] as String? ?? '',
      lastTransactionId: map['lastTransactionId'] as String?,
      isAutoRenew: (map['isAutoRenew'] as int? ?? 0) == 1,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in SubscriptionModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.SubscriptionModel()
      ..userId = userId
      ..planId = planId
      ..status = status
      ..startDate = startDate?.toIso8601String() ?? ''
      ..endDate = endDate?.toIso8601String() ?? ''
      ..createdAt = createdAt?.toIso8601String() ?? ''
      ..updatedAt = updatedAt?.toIso8601String() ?? ''
      ..paymentMethod = paymentMethod
      ..lastTransactionId = lastTransactionId ?? ''
      ..isAutoRenew = isAutoRenew;
    return proto.writeToBuffer();
  }

  factory SubscriptionModel.fromProto(List<int> bytes) {
    final proto = pb.SubscriptionModel.fromBuffer(bytes);
    return SubscriptionModel(
      userId: proto.userId,
      planId: proto.planId,
      status: proto.status,
      startDate: proto.hasStartDate() ? DateTime.parse(proto.startDate) : null,
      endDate: proto.hasEndDate() ? DateTime.parse(proto.endDate) : null,
      createdAt: proto.hasCreatedAt() ? DateTime.parse(proto.createdAt) : null,
      updatedAt: proto.hasUpdatedAt() ? DateTime.parse(proto.updatedAt) : null,
      paymentMethod: proto.paymentMethod,
      lastTransactionId: proto.hasLastTransactionId() ? proto.lastTransactionId : null,
      isAutoRenew: proto.isAutoRenew,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'planId': planId,
      'status': status,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'paymentMethod': paymentMethod,
      if (lastTransactionId != null) 'transactionId': lastTransactionId,
      'isAutoRenew': isAutoRenew,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'lastTransactionId': lastTransactionId,
      'isAutoRenew': isAutoRenew,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'lastTransactionId': lastTransactionId,
      'isAutoRenew': isAutoRenew ? 1 : 0,
    };
  }
}