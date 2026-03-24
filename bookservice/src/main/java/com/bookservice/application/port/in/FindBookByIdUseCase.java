package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;

public interface FindBookByIdUseCase {
    BookDetailView find(String id);
}