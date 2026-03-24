package com.bookservice.application.port.in;

import com.bookservice.application.port.in.command.UpdateBookCommand;
import com.bookservice.application.dto.BookDetailView;

public interface UpdateBookUseCase {
    BookDetailView update(String id, UpdateBookCommand command);
}