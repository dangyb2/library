package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.domain.exception.ReaderNotFoundException;
import com.readerservice.application.port.in.FindReaderByPhoneUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.PhoneNumber;
import org.springframework.transaction.annotation.Transactional;

public class FindReaderByPhoneService implements FindReaderByPhoneUseCase {
    private final ReaderRepository readerRepository;

    public FindReaderByPhoneService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public ReaderView findByPhone(String phone) {
        return readerRepository.findByPhone(new PhoneNumber(phone))
                .map(ReaderView::from)
                .orElseThrow(() -> new ReaderNotFoundException("phone: " + phone));
    }
}
