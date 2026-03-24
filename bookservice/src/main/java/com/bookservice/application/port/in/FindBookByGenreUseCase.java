package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookSummaryView;

import java.util.List;

public interface FindBookByGenreUseCase {
    List<BookSummaryView> findIgnoreCase(String genre);

}
