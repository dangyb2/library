package com.bookservice.application.service;

import com.bookservice.application.dto.BookTitleProjection;
import com.bookservice.application.port.in.GetBookTitlesBatchUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.InvalidBookDataException;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Transactional(readOnly = true)
public class GetBookTitlesBatchService implements GetBookTitlesBatchUseCase {

    private final BookRepository bookRepository;

    public GetBookTitlesBatchService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    @Override
    public Map<String, String> getTitles(Set<String> bookIds) {
        if (bookIds == null || bookIds.isEmpty()) {
            throw new InvalidBookDataException("Danh sách mã sách không được để trống");
        }
        // Fetch projections and map them directly
        return bookRepository.findByIdIn(bookIds).stream()
                .collect(Collectors.toMap(
                        BookTitleProjection::id,
                        BookTitleProjection::title
                ));
    }
}