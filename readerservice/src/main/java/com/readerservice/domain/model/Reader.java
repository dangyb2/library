package com.readerservice.domain.model;

import java.time.LocalDate;

public class Reader {

    private String id;

    // Thông tin cơ bản của độc giả
    private String name;
    private Email email;
    private PhoneNumber phone;

    // Ngày hết hạn thẻ thành viên (luôn khác null)
    private LocalDate membershipExpireAt;

    // Trạng thái hiện tại của độc giả
    private Status status;

    // Lý do bị đình chỉ (chỉ có ý nghĩa khi status = SUSPENDED)
    private String suspendReason;

    public Reader(String id,
                  String name,
                  Email email,
                  PhoneNumber phone,
                  LocalDate membershipExpireAt) {

        if (id == null || id.isBlank()) {
            throw new IllegalArgumentException("Reader ID must not be null or blank");
        }
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Reader name must not be null or blank");
        }
        if (membershipExpireAt == null) {
            throw new IllegalArgumentException("Membership expiration date must not be null");
        }
        if (email == null) {
            throw new IllegalArgumentException("Email must not be null");
        }
        if (phone == null) {
            throw new IllegalArgumentException("Phone number must not be null");
        }

        this.id = id;
        this.name = name;
        this.email = email;
        this.phone = phone;
        this.membershipExpireAt = membershipExpireAt;
        this.status = Status.NORMAL;
    }

    // ===== Getter =====

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Email getEmail() {
        return email;
    }

    public PhoneNumber getPhone() {
        return phone;
    }

    public LocalDate getMembershipExpireAt() {
        return membershipExpireAt;
    }

    public Status getStatus() {
        return status;
    }

    public String getSuspendReason() {
        return suspendReason;
    }

    /**
     * Kiểm tra thẻ thành viên đã hết hạn hay chưa
     *
     * @return true nếu ngày hiện tại sau ngày hết hạn
     */
    public boolean isMembershipExpired() {
        return LocalDate.now().isAfter(membershipExpireAt);
    }


    public void extendMembership(LocalDate newExpireDate) {
        if (newExpireDate == null) {
            throw new IllegalArgumentException("New expiration date must not be null");
        }
        if (newExpireDate.isBefore(this.membershipExpireAt)
                || newExpireDate.isEqual(this.membershipExpireAt)) {
            throw new IllegalArgumentException(
                    "New expiration date must be later than current expiration date"
            );
        }
        this.membershipExpireAt = newExpireDate;
    }


    public void suspend(String reason) {
        if (this.status == Status.SUSPENDED) {
            throw new IllegalStateException("Reader is already suspended");
        }
        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException("Suspend reason must not be empty");
        }
        this.status = Status.SUSPENDED;
        this.suspendReason = reason;
    }

    public void unsuspend() {
        if (this.status != Status.SUSPENDED) {
            throw new IllegalStateException("Reader is not suspended");
        }
        this.status = Status.NORMAL;
        this.suspendReason = null;
    }
}