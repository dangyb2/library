package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.application.port.in.FindAllReadersUseCase;
import com.readerservice.application.port.out.ReaderRepository;

import java.util.List;

public class FindAllReadersService implements FindAllReadersUseCase {
    private final ReaderRepository readerRepository;

    public FindAllReadersService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    public List<ReaderView> findAll() {
        return readerRepository.findAll().stream()
                .map(ReaderView::from)
                .toList();
    }
}
