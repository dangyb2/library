package com.bookservice.application.service;

import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.port.in.GetArchivedBooksUseCase;
import com.bookservice.application.port.out.BookRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Transactional(readOnly = true)
public class GetArchivedBooksService implements GetArchivedBooksUseCase {

    private final BookRepository bookRepository;

    public GetArchivedBooksService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    @Override
    public List<BookSummaryView> getArchived() {
        return bookRepository.findAllDeletedBooks().stream()
                .map(BookSummaryView::fromBook)
                .collect(Collectors.toList());
    }
}