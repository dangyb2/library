package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;

import java.util.Optional;

public interface FindBookByIsbnUseCase {
    Optional<BookDetailView> find(String isbn);
}
