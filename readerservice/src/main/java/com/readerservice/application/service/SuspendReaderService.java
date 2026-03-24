package com.readerservice.application.service;

import com.readerservice.application.port.in.SuspendReaderUseCase;
import com.readerservice.application.port.out.ReaderRepository;

/**
 * Application Service triển khai use case "Đình chỉ độc giả".
 *
 * Lớp này thuộc tầng Application, có nhiệm vụ:
 * - Điều phối luồng xử lý nghiệp vụ
 * - Gọi Domain Model để thực hiện hành vi
 * - Sử dụng Repository thông qua Output Port
 *
 * Không chứa logic truy xuất dữ liệu cụ thể hay code hạ tầng.
 */
public class SuspendReaderService implements SuspendReaderUseCase {

    private final ReaderRepository readerRepository;

    public SuspendReaderService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    public void suspend(String id, String reason) {
        // Lấy độc giả theo id, nếu không tồn tại thì báo lỗi
        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Reader not found"));

        // Thực hiện hành vi nghiệp vụ đình chỉ độc giả
        reader.suspend(reason);

        // Lưu lại trạng thái mới của Reader
        readerRepository.save(reader);
    }
}
