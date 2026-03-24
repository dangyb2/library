package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.application.port.in.FindReadersByNameUseCase;
import com.readerservice.application.port.out.ReaderRepository;

import java.util.List;

public class FindReadersByNameService implements FindReadersByNameUseCase {
    private final ReaderRepository readerRepository;

    public FindReadersByNameService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    public List<ReaderView> findByName(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            throw new IllegalArgumentException("Name keyword must not be blank");
        }

        return readerRepository.findByName(keyword.trim()).stream()
                .map(ReaderView::from)
                .toList();
    }
}
