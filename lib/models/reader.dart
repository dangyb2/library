import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  ENUM
// ─────────────────────────────────────────────

enum ReaderStatus {
  active,
  suspended,
  expired;

  String get label => switch (this) {
        ReaderStatus.active    => 'Đang hoạt động',
        ReaderStatus.suspended => 'Đình chỉ',
        ReaderStatus.expired   => 'Hết hạn',
      };

  Color get color => switch (this) {
        ReaderStatus.active    => const Color(0xFF16A34A),
        ReaderStatus.suspended => const Color(0xFFDC2626),
        ReaderStatus.expired   => const Color(0xFFD97706),
      };

  Color get backgroundColor => switch (this) {
        ReaderStatus.active    => const Color(0xFFDCFCE7),
        ReaderStatus.suspended => const Color(0xFFFEE2E2),
        ReaderStatus.expired   => const Color(0xFFFEF3C7),
      };

  bool get isActive    => this == ReaderStatus.active;
  bool get isSuspended => this == ReaderStatus.suspended;
  bool get isExpired   => this == ReaderStatus.expired;
}

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────

class Reader {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime membershipExpireAt;
  final ReaderStatus status;
  final String? suspendReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Reader({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.membershipExpireAt,
    required this.status,
    this.suspendReason,
    this.createdAt,
    this.updatedAt,
  });

  // ── COMPUTED ──────────────────────────────────────────────────

  bool get isMembershipExpired =>
      membershipExpireAt.isBefore(DateTime.now());

  int get daysUntilExpiry =>
      membershipExpireAt.difference(DateTime.now()).inDays.clamp(0, 99999);

  bool isExpiringSoon({int withinDays = 7}) =>
      daysUntilExpiry <= withinDays;

  // ── SERIALIZATION ─────────────────────────────────────────────

  factory Reader.fromJson(Map<String, dynamic> json) {
    return Reader(
      id:                  json['id'] as String,
      name:                json['name'] as String,
      email:               json['email'] as String,
      phone:               json['phone'] as String,
      membershipExpireAt:  DateTime.parse(json['membershipExpireAt'] as String),
      status:              ReaderStatus.values.firstWhere(
                             (e) => e.name == json['status'],
                             orElse: () => ReaderStatus.expired,
                           ),
      suspendReason:       json['suspendReason'] as String?,
      createdAt:           json['createdAt'] != null
                             ? DateTime.parse(json['createdAt'] as String)
                             : null,
      updatedAt:           json['updatedAt'] != null
                             ? DateTime.parse(json['updatedAt'] as String)
                             : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                 id,
        'name':               name,
        'email':              email,
        'phone':              phone,
        'membershipExpireAt': membershipExpireAt.toIso8601String(),
        'status':             status.name,
        'suspendReason':      suspendReason,
        'createdAt':          createdAt?.toIso8601String(),
        'updatedAt':          updatedAt?.toIso8601String(),
      };

  // ── COPY WITH ─────────────────────────────────────────────────

  Reader copyWith({
    String?       id,
    String?       name,
    String?       email,
    String?       phone,
    DateTime?     membershipExpireAt,
    ReaderStatus? status,
    String?       suspendReason,
    DateTime?     createdAt,
    DateTime?     updatedAt,
  }) {
    return Reader(
      id:                  id                 ?? this.id,
      name:                name               ?? this.name,
      email:               email              ?? this.email,
      phone:               phone              ?? this.phone,
      membershipExpireAt:  membershipExpireAt ?? this.membershipExpireAt,
      status:              status             ?? this.status,
      suspendReason:       suspendReason      ?? this.suspendReason,
      createdAt:           createdAt          ?? this.createdAt,
      updatedAt:           updatedAt          ?? this.updatedAt,
    );
  }

  // ── EQUALITY ──────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      other is Reader && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reader(id: $id, name: $name, status: ${status.name})';
}