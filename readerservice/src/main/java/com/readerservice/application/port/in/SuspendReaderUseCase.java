package com.readerservice.application.port.in;

/**
 * SuspendReaderUseCase là Input Port của tầng Application.
 *
 * Đại diện cho use case "Đình chỉ độc giả" trong hệ thống.
 *
 * - Các adapter bên ngoài (REST Controller, Messaging, ...)
 *   sẽ gọi vào interface này
 * - Interface này mô tả hành vi nghiệp vụ,
 *   không chứa chi tiết triển khai
 */
public interface SuspendReaderUseCase {

    /**
     * Đình chỉ một độc giả theo id với lý do cụ thể
     *
     * @param id     định danh của độc giả
     * @param reason lý do đình chỉ
     */
    void suspend(String id, String reason);
}
