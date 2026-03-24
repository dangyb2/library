package com.readerservice.infrastructure.persistence;

import com.readerservice.domain.model.Status;
import jakarta.persistence.*;

import java.time.LocalDate;

/**
 * ReaderEntity là JPA Entity thuộc tầng Infrastructure.
 *
 * - Đại diện cho bảng "readers" trong database
 * - Chỉ phục vụ mục đích persistence (lưu / đọc dữ liệu)
 * - KHÔNG chứa logic nghiệp vụ
 *
 * Entity này được ánh xạ từ Domain model Reader,
 * nhưng không phải là Domain object.
 */
@Entity
@Table(name = "readers")
public class ReaderEntity {

    @Id
    private String id;

    @Column(nullable = false)
    private String name;

    @Column(unique = true)
    private String email;

    @Column(unique = true)
    private String phone;

    @Column(nullable = false)
    private LocalDate membershipExpireAt;

    @Enumerated(EnumType.STRING)
    private Status status;

    /**
     * Lý do bị đình chỉ
     * Chỉ có ý nghĩa khi status = SUSPENDED
     */
    private String suspendReason;

    /**
     * Constructor không tham số bắt buộc cho JPA.
     *
     * - JPA sử dụng constructor này khi load entity từ database
     * - Để protected nhằm:
     *   + Ngăn việc khởi tạo entity trực tiếp từ bên ngoài
     *   + Ép việc tạo object phải thông qua Mapper / Repository
     */
    protected ReaderEntity() {
    }

    // ===== Getter =====

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
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

    // ===== Setter =====
    // Setter chỉ dùng trong tầng Infrastructure (Mapper / JPA)

    public void setId(String id) {
        this.id = id;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public void setMembershipExpireAt(LocalDate membershipExpireAt) {
        this.membershipExpireAt = membershipExpireAt;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public void setSuspendReason(String suspendReason) {
        this.suspendReason = suspendReason;
    }
}
