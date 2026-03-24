package com.readerservice.application.port.in;

import java.time.LocalDate;

/**
 * ExtendMembershipUseCase là Input Port của tầng Application.
 *
 * Đại diện cho use case "Gia hạn thẻ thành viên" cho độc giả.
 *
 * - Các adapter bên ngoài (REST Controller, Messaging, ...)
 *   sẽ gọi vào interface này
 * - Interface này mô tả hành vi nghiệp vụ,
 *   không chứa chi tiết triển khai
 */
public interface ExtendMembershipUseCase {

    /**
     * Gia hạn thẻ thành viên cho độc giả
     *
     * @param id             định danh của độc giả
     * @param newExpireDate  ngày hết hạn mới
     */
    void extend(String id, LocalDate newExpireDate);
}
