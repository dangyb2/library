package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.FindBookByIsbnUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.InvalidBookDataException;

import java.util.Optional;

public class FindBookByIsbnService implements FindBookByIsbnUseCase {

    private final BookRepository repository;

    public FindBookByIsbnService(BookRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<BookDetailView> find(String isbn) {

        if (isbn == null || isbn.isBlank()) {
            throw new InvalidBookDataException("Mã ISBN không được để trống");
        }

        return repository.findByIsbn(isbn.trim())
                .map(BookDetailView::fromBook);
    }
}