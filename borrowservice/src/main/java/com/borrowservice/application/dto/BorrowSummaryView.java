package com.borrowservice.application.dto;

import com.borrowservice.domain.model.Status;
import java.time.LocalDate;

public record BorrowSummaryView(
        String borrowId,
        String bookId,
        String bookTitle,
        String readerId,
        String readerName,
        LocalDate borrowDate,
        LocalDate dueDate,
        LocalDate returnDate,
        Status status
) {}