package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.domain.exception.ReaderNotFoundException;
import com.readerservice.application.port.in.FindReaderByIdUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Reader;
import org.springframework.transaction.annotation.Transactional;

public class    FindReaderByIdService implements FindReaderByIdUseCase {

    private final ReaderRepository readerRepository;

    public FindReaderByIdService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public ReaderView find(String id) {
        Reader reader = readerRepository.findById(id)
                .orElseThrow(()->new ReaderNotFoundException(id));
        return ReaderView.from(reader);
    }

}
