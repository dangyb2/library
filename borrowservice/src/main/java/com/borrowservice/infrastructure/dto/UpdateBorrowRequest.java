package com.borrowservice.infrastructure.dto;

import com.borrowservice.domain.model.BookCondition;
import java.time.LocalDate;

public record UpdateBorrowRequest(
        String readerId,
        String bookId,
        LocalDate borrowDate,
        LocalDate dueDate,
        BookCondition conditionBorrow
) {}