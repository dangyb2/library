package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.domain.model.Status;

import java.util.List;

public interface FindReadersByStatusUseCase {
    List<ReaderView> findByStatus(Status status);
}
