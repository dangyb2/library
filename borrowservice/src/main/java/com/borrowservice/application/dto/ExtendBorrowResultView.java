package com.borrowservice.application.dto;

import java.time.LocalDate;

public record ExtendBorrowResultView(
        String borrowId,
        LocalDate newDueDate
) {}