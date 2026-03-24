package com.borrowservice.application.port.in.command;

import com.borrowservice.domain.model.BookCondition;
import java.time.LocalDate;

public record BorrowBookCommand (
        String readerId,
        String bookId,
        LocalDate dueDate,
        BookCondition conditionBorrow
){}