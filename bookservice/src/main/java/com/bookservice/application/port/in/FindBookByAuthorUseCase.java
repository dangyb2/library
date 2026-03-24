package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookSummaryView;

import java.util.List;

public interface FindBookByAuthorUseCase {
    List<BookSummaryView> findIgnoreCase(String author);
}
