package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderEligibilityView;

public interface CheckReaderEligibilityUseCase {
    ReaderEligibilityView check(String readerId);
}
