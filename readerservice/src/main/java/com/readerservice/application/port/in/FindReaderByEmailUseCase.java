package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;

/**
 * Input port for finding a reader by email.
 */
public interface FindReaderByEmailUseCase {
    ReaderView findByEmail(String email);
}
