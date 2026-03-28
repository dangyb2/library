package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.application.port.in.FindReadersByStatusUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Status;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public class FindReadersByStatusService implements FindReadersByStatusUseCase {
    private final ReaderRepository readerRepository;

    public FindReadersByStatusService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReaderView> findByStatus(Status status) {
        return readerRepository.findByStatus(status)
                .stream()
                .map(ReaderView::from)
                .toList();
    }


}
