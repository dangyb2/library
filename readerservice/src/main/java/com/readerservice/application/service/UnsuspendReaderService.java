package com.readerservice.application.service;

import com.readerservice.application.port.in.UnsuspendReaderUseCase;
import com.readerservice.application.port.out.ReaderRepository;

/**
 * Application Service triển khai use case "Gỡ đình chỉ độc giả".
 *
 * Lớp này không chứa logic nghiệp vụ chi tiết,
 * mà chỉ điều phối các thành phần trong hệ thống.
 */
public class UnsuspendReaderService implements UnsuspendReaderUseCase {

    private final ReaderRepository readerRepository;

    public UnsuspendReaderService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    public void unsuspend(String id) {
        // Tìm độc giả theo id
        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Reader not found"));

        // Gỡ bỏ trạng thái đình chỉ trong Domain
        reader.unsuspend();

        // Lưu lại trạng thái mới
        readerRepository.save(reader);
    }
}
