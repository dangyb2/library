package com.readerservice.application.port.in;

import com.readerservice.application.dto.ReaderView;

import java.util.List;

/**
 * Input port for searching readers by name.
 */
public interface FindReadersByNameUseCase {

    /**
     * Search readers whose names contain the provided keyword.
     */
    List<ReaderView> findByName(String keyword);
}
