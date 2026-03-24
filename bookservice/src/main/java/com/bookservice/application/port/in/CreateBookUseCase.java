package com.bookservice.application.port.in;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.command.CreateBookCommand;


public interface CreateBookUseCase {
    BookDetailView create(CreateBookCommand command);
}