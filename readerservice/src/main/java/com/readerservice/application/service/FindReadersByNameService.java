package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.application.port.in.FindReadersByNameUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderValidationException;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public class FindReadersByNameService implements FindReadersByNameUseCase {
    private final ReaderRepository readerRepository;

    public FindReadersByNameService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReaderView> findByName(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            throw new ReaderValidationException("Từ khóa tên độc giả không được để trống");
        }

        return readerRepository.findByName(keyword.trim()).stream()
                .map(ReaderView::from)
                .toList();
    }
}
