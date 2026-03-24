package com.borrowservice.application.port.in.command;

import com.borrowservice.domain.model.BookCondition;
import java.time.LocalDate;

public record UpdateBorrowCommand(
        String borrowId,
        String readerId,
        String bookId,
        LocalDate borrowDate,
        LocalDate dueDate,
        BookCondition conditionBorrow
) {}