package com.readerservice.application.port.in;

/**
 * UnsuspendReaderUseCase là Input Port của tầng Application.
 *
 * Đại diện cho use case "Gỡ đình chỉ độc giả" trong hệ thống.
 *
 * - Các adapter bên ngoài (REST Controller, Messaging, ...)
 *   sẽ gọi vào interface này
 * - Interface này mô tả hành vi nghiệp vụ,
 *   không chứa chi tiết triển khai
 */
public interface UnsuspendReaderUseCase {

    /**
     * Gỡ bỏ trạng thái đình chỉ của độc giả theo id
     *
     * @param id định danh của độc giả
     */
    void unsuspend(String id);
}
