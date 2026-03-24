package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.FindBookByIdUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.exception.InvalidBookDataException;
import org.springframework.transaction.annotation.Transactional;

@Transactional(readOnly = true)
public class FindBookByIdService implements FindBookByIdUseCase {

    private final BookRepository repository;

    public FindBookByIdService(BookRepository repository) {
        this.repository = repository;
    }

    @Override
    public BookDetailView find(String id) {

        if (id == null || id.isBlank()) {
            throw new InvalidBookDataException("Mã sách không được để trống");
        }

        return repository.findById(id)
                .map(BookDetailView::fromBook)
                .orElseThrow(() -> BookNotFoundException.byId(id));
    }
}