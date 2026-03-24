package com.borrowservice.application.dto;

import com.borrowservice.domain.model.PaymentStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

public record OverdueBorrowView(
        String borrowId,
        String readerId,
        String bookId,
        LocalDate dueDate,
        long daysOverdue,
        BigDecimal currentFine,
        PaymentStatus paymentStatus
) {}