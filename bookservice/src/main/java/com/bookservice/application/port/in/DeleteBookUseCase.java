package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;

public interface DeleteBookUseCase {
    void deleteBook(String bookId);
}
