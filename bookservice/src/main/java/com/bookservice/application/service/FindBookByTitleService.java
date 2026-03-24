package com.bookservice.application.service;

import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.port.in.FindBookByTitleUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.InvalidBookDataException;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Transactional(readOnly = true)
public class FindBookByTitleService implements FindBookByTitleUseCase {

    private final BookRepository repository;

    public FindBookByTitleService(BookRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<BookSummaryView> find(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            throw new InvalidBookDataException("Từ khóa tìm kiếm không được để trống");
        }

        return repository.findByTitleContainingIgnoreCase(keyword.trim())
                .stream()
                .map(BookSummaryView::fromBook)
                .toList();
    }
}