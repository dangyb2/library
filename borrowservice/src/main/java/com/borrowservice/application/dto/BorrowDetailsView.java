package com.borrowservice.application.dto;

import com.borrowservice.domain.model.BookCondition;
import com.borrowservice.domain.model.PaymentStatus;
import com.borrowservice.domain.model.Status;
import java.math.BigDecimal;
import java.time.LocalDate;

public record BorrowDetailsView(
        String borrowId,
        String readerId,
        String readerName,  // Added
        String bookId,
        String bookTitle,   // Added
        LocalDate borrowDate,
        LocalDate dueDate,
        LocalDate returnDate,
        BookCondition conditionBorrow,
        BookCondition conditionReturn,
        Status status,
        BigDecimal price,
        BigDecimal fine,
        PaymentStatus paymentStatus
) {}