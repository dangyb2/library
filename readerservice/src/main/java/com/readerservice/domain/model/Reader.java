package com.readerservice.domain.model;

import com.readerservice.domain.exception.ReaderStateException;
import com.readerservice.domain.exception.ReaderValidationException;

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
            throw new ReaderValidationException("Mã độc giả không được để trống");
        }
        if (membershipExpireAt == null) {
            throw new ReaderValidationException("Ngày hết hạn thẻ thành viên không được để trống");
        }
        if (email == null) {
            throw new ReaderValidationException("Email không được để trống");
        }
        if (phone == null) {
            throw new ReaderValidationException("Số điện thoại không được để trống");
        }

        this.id = id;
        this.name = normalizeName(name);
        this.email = email;
        this.phone = phone;
        this.membershipExpireAt = membershipExpireAt;
        this.status = Status.NORMAL;
    }
    public Reader(String id, String name, Email email,
                  PhoneNumber phone, LocalDate membershipExpireAt,
                  Status status, String suspendReason) {
        this(id, name, email, phone, membershipExpireAt); // reuse guards
        this.status = status != null ? status : Status.NORMAL;
        this.suspendReason = suspendReason;
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

    public boolean isMembershipExpired() {
        return LocalDate.now().isAfter(membershipExpireAt);
    }

    public boolean isEligibleToBorrow() {
        return this.status == Status.NORMAL && !isMembershipExpired();
    }

    public void updateProfile(String newName, Email newEmail, PhoneNumber newPhone) {
        if (newEmail == null)
            throw new ReaderValidationException("Email không được để trống");
        if (newPhone == null)
            throw new ReaderValidationException("Số điện thoại không được để trống");
        // normalizeName also validates, so assign last
        this.name = normalizeName(newName);
        this.email = newEmail;
        this.phone = newPhone;
    }
    public void extendMembership(LocalDate newExpireDate) {
        if (newExpireDate == null) {
            throw new ReaderValidationException("Ngày gia hạn không được để trống");
        }
        if (newExpireDate.isBefore(this.membershipExpireAt)
                || newExpireDate.isEqual(this.membershipExpireAt)) {
            throw new ReaderValidationException("Ngày gia hạn phải lớn hơn ngày hết hạn hiện tại");
        }
        this.membershipExpireAt = newExpireDate;
    }


    public void suspend(String reason) {
        if (this.status == Status.SUSPENDED) {
            throw new ReaderStateException("Độc giả đã bị đình chỉ trước đó");
        }
        if (reason == null || reason.isBlank()) {
            throw new ReaderValidationException("Lý do đình chỉ không được để trống");
        }
        this.status = Status.SUSPENDED;
        this.suspendReason = reason.trim();
    }

    public void unsuspend() {
        if (this.status != Status.SUSPENDED) {
            throw new ReaderStateException("Độc giả hiện không ở trạng thái đình chỉ");
        }
        this.status = Status.NORMAL;
        this.suspendReason = null;
    }

    private String normalizeName(String rawName) {
        if (rawName == null || rawName.isBlank()) {
            throw new ReaderValidationException("Tên độc giả không được để trống");
        }
        return rawName.trim();
    }
}
