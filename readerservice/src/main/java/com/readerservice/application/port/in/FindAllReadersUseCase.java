package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;

import java.util.List;

/**
 * Input port for finding all readers.
 */
public interface FindAllReadersUseCase {
    List<ReaderView> findAll();
}
