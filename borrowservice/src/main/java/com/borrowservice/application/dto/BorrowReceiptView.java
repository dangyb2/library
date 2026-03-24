package com.borrowservice.application.dto;

import com.borrowservice.domain.model.BookCondition;

import java.math.BigDecimal;
import java.time.LocalDate;

public record BorrowReceiptView(
        String borrowId,
        String readerId,
        String bookId,
        LocalDate borrowDate,
        LocalDate dueDate,
        BookCondition conditionBorrow,
        BigDecimal price
){}
