package com.bookservice.application.service;

import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.port.in.GetAllBooksUseCase;
import com.bookservice.application.port.out.BookRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;
@Transactional(readOnly = true)
public class GetAllBooksService implements GetAllBooksUseCase {

    private final BookRepository repository;

    public GetAllBooksService(BookRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<BookSummaryView> find() {
        return repository.findAll()
                .stream()
                .map(BookSummaryView::fromBook)
                .collect(Collectors.toList());
    }
}