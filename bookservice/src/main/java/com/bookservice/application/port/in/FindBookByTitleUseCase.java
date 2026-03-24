package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookSummaryView;

import java.util.List;

public interface FindBookByTitleUseCase {
    List<BookSummaryView> find(String keyword);
}