package com.readerservice.application.service;

import com.readerservice.application.port.in.ExtendMembershipUseCase;
import com.readerservice.application.port.out.ReaderRepository;

import java.time.LocalDate;

/**
 * Application Service triển khai use case "Gia hạn thẻ thành viên".
 *
 * Chịu trách nhiệm điều phối luồng xử lý giữa:
 * - Input Port (ExtendMembershipUseCase)
 * - Domain Model (Reader)
 * - Output Port (ReaderRepository)
 */
public class ExtendMembershipService implements ExtendMembershipUseCase {

    private final ReaderRepository readerRepository;

    public ExtendMembershipService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    public void extend(String id, LocalDate newDate) {
        // Tìm độc giả theo id
        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Reader not found"));

        // Áp dụng luật nghiệp vụ gia hạn thẻ trong Domain
        reader.extendMembership(newDate);

        // Lưu lại thay đổi
        readerRepository.save(reader);
    }
}
