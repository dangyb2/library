package com.bookservice.application.service;

import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.port.in.FindLowStockBookUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.InvalidBookDataException;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Transactional(readOnly = true)
public class FindLowStockBookService implements FindLowStockBookUseCase {

    private final BookRepository repository;

    public FindLowStockBookService(BookRepository repository) {
        this.repository = repository;
    }
    @Override
    public List<BookSummaryView> findLowOnStock(long threshold) {

        if (threshold < 0) {
            throw new InvalidBookDataException("Threshold must not be negative");
        }
        return repository.findLowStock(threshold)
                .stream()
                .map(BookSummaryView::fromBook)
                .toList();
    }
}