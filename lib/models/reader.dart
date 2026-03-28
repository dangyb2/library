// ─────────────────────────────────────────────
//  ENUM
// ─────────────────────────────────────────────

enum ReaderStatus { NORMAL, SUSPENDED }

extension ReaderStatusX on ReaderStatus {
  String get value => name;

  static ReaderStatus fromString(String s) =>
      ReaderStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ReaderStatus.NORMAL,
      );

  String get label => switch (this) {
        ReaderStatus.NORMAL    => 'Hoạt động',
        ReaderStatus.SUSPENDED => 'Bị khoá',
      };
}

// ─────────────────────────────────────────────
//  REQUEST MODELS
// ─────────────────────────────────────────────

class CreateReaderRequest {
  final String   name;
  final String   email;
  final String   phone;
  final DateTime membershipExpireAt;

  const CreateReaderRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.membershipExpireAt,
  });

  Map<String, dynamic> toJson() => {
        'name':                name,
        'email':               email,
        'phone':               phone,
        'membershipExpireAt':  membershipExpireAt.toIso8601String().split('T').first,
      };
}

class UpdateReaderRequest {
  final String   name;
  final String   email;
  final String   phone;
  final DateTime membershipExpireAt;

  const UpdateReaderRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.membershipExpireAt,
  });

  Map<String, dynamic> toJson() => {
        'name':                name,
        'email':               email,
        'phone':               phone,
        'membershipExpireAt':  membershipExpireAt.toIso8601String().split('T').first,
      };
}

class SuspendRequest {
  final String reason;

  const SuspendRequest({required this.reason});

  Map<String, dynamic> toJson() => {'reason': reason};
}

class ExtendMemberShipRequest {
  final DateTime newExpireDate;

  const ExtendMemberShipRequest({required this.newExpireDate});

  Map<String, dynamic> toJson() => {
        'newExpireDate': newExpireDate.toIso8601String().split('T').first,
      };
}

// ─────────────────────────────────────────────
//  RESPONSE / VIEW MODELS
// ─────────────────────────────────────────────

class ReaderView {
  final String       id;
  final String       name;
  final String       email;
  final String       phone;
  final DateTime     membershipExpireAt;
  final ReaderStatus status;
  final String?      suspendReason;

  const ReaderView({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.membershipExpireAt,
    required this.status,
    this.suspendReason,
  });

  factory ReaderView.fromJson(Map<String, dynamic> json) => ReaderView(
        id:                 json['id']    as String,
        name:               json['name']  as String,
        email:              json['email'] as String,
        phone:              json['phone'] as String? ?? '',
        membershipExpireAt: DateTime.parse(json['membershipExpireAt'] as String),
        status:             ReaderStatusX.fromString(
                                json['status'] as String? ?? 'NORMAL'),
        suspendReason:      json['suspendReason'] as String?,
      );

  /// Tiện ích kiểm tra thẻ hết hạn
  bool get isMembershipExpired =>
      membershipExpireAt.isBefore(DateTime.now());
}

// ─────────────────────────────────────────────
//  ReaderEligibilityView
//  GET /readers/{readerId}/eligibility-details
// ─────────────────────────────────────────────

class ReaderEligibilityView {
  final bool      eligible;
  final DateTime? membershipExpireAt;

  const ReaderEligibilityView({
    required this.eligible,
    this.membershipExpireAt,
  });

  factory ReaderEligibilityView.fromJson(Map<String, dynamic> json) =>
      ReaderEligibilityView(
        eligible:           json['eligible'] as bool? ?? false,
        membershipExpireAt: json['membershipExpireAt'] != null
            ? DateTime.parse(json['membershipExpireAt'] as String)
            : null,
      );
}