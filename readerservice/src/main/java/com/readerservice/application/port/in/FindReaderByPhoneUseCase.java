package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;

/**
 * Input port for finding a reader by phone number.
 */
public interface FindReaderByPhoneUseCase {
    ReaderView findByPhone(String phone);
}
