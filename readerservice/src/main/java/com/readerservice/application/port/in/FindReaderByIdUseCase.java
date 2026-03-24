package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;


/**
 * FindReaderByIdUseCase là Input Port của tầng Application.
 *
 * Đại diện cho use case "Tìm độc giả theo id".
 *
 * - Được gọi từ các adapter bên ngoài (REST Controller, ...)
 * - Chỉ mô tả hành vi nghiệp vụ, không chứa logic triển khai
 */
public interface FindReaderByIdUseCase {

    /**
     * Tìm độc giả theo id
     *
     * @param id định danh của độc giả
     * @return Optional chứa Reader nếu tồn tại, hoặc empty nếu không tìm thấy
     */
    ReaderView find(String id);
}
