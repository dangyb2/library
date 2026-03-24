package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;

public interface AddBookStockUseCase {
    BookDetailView add(String id, long quantity);
    }
