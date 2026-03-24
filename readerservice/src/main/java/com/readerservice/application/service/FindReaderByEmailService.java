package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.domain.exception.ReaderNotFoundException;
import com.readerservice.application.port.in.FindReaderByEmailUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Email;

public class FindReaderByEmailService implements FindReaderByEmailUseCase {
    private final ReaderRepository readerRepository;

    public FindReaderByEmailService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    public ReaderView findByEmail(String email) {
        return readerRepository.findByEmail(new Email(email))
                .map(ReaderView::from)
                .orElseThrow(() -> new ReaderNotFoundException("email: " + email));
    }
}
