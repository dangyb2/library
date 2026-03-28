package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;
public interface UpdateReaderUseCase {
    ReaderView update(String id, String name, String email, String phone);
}