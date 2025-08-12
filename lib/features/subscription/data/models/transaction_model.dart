// Transaction Model
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../generated/protos/wellness_data.pb.dart' as pb;

class TransactionModel {
  final String id;
  final String userId;
  final String subscriptionId;
  final String paymentProviderTransactionId;
  final String paymentProvider;
  final double amount;
  final String currency;
  final String status;
  final String planId;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.paymentProviderTransactionId,
    required this.paymentProvider,
    required this.amount,
    required this.currency,
    required this.status,
    required this.planId,
    this.createdAt,
  });

  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TransactionModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      subscriptionId: data['subscriptionId'] as String? ?? '',
      paymentProviderTransactionId: data['paymentProviderTransactionId'] as String? ?? '',
      paymentProvider: data['paymentProvider'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? '',
      status: data['status'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      subscriptionId: json['subscriptionId'] as String? ?? '',
      paymentProviderTransactionId: json['paymentProviderTransactionId'] as String? ?? '',
      paymentProvider: json['paymentProvider'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '',
      status: json['status'] as String? ?? '',
      planId: json['planId'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      subscriptionId: map['subscriptionId'] as String? ?? '',
      paymentProviderTransactionId: map['paymentProviderTransactionId'] as String? ?? '',
      paymentProvider: map['paymentProvider'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? '',
      status: map['status'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in TransactionModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.TransactionModel()
      ..id = id
      ..userId = userId
      ..subscriptionId = subscriptionId
      ..paymentProviderTransactionId = paymentProviderTransactionId
      ..paymentProvider = paymentProvider
      ..amount = amount
      ..currency = currency
      ..status = status
      ..planId = planId
      ..createdAt = createdAt?.toIso8601String() ?? '';
    return proto.writeToBuffer();
  }

  factory TransactionModel.fromProto(List<int> bytes) {
    final proto = pb.TransactionModel.fromBuffer(bytes);
    return TransactionModel(
      id: proto.id,
      userId: proto.userId,
      subscriptionId: proto.subscriptionId,
      paymentProviderTransactionId: proto.paymentProviderTransactionId,
      paymentProvider: proto.paymentProvider,
      amount: proto.amount,
      currency: proto.currency,
      status: proto.status,
      planId: proto.planId,
      createdAt: proto.hasCreatedAt() ? DateTime.parse(proto.createdAt) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subscriptionId': subscriptionId,
      'paymentProviderTransactionId': paymentProviderTransactionId,
      'paymentProvider': paymentProvider,
      'amount': amount,
      'currency': currency,
      'status': status,
      'planId': planId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'paymentProviderTransactionId': paymentProviderTransactionId,
      'paymentProvider': paymentProvider,
      'amount': amount,
      'currency': currency,
      'status': status,
      'planId': planId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'paymentProviderTransactionId': paymentProviderTransactionId,
      'paymentProvider': paymentProvider,
      'amount': amount,
      'currency': currency,
      'status': status,
      'planId': planId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
