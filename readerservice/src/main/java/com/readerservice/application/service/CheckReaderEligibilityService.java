package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderEligibilityView;
import com.readerservice.application.port.in.CheckReaderEligibilityUseCase;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderNotFoundException;
import org.springframework.transaction.annotation.Transactional;

public class CheckReaderEligibilityService implements CheckReaderEligibilityUseCase {
    private final ReaderRepository readerRepository;

    public CheckReaderEligibilityService(ReaderRepository readerRepository) {
        this.readerRepository = readerRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public ReaderEligibilityView check(String readerId) {
        var reader = readerRepository.findById(readerId)
                .orElseThrow(() -> new ReaderNotFoundException("id: " + readerId));

        return new ReaderEligibilityView(
                reader.isEligibleToBorrow(),
                reader.getMembershipExpireAt()
        );
    }
}
