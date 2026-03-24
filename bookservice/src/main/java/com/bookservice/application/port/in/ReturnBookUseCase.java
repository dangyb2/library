package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;

public interface ReturnBookUseCase {
    BookDetailView returnBook(String id);

}
